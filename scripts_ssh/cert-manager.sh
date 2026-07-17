#!/usr/bin/env bash
#
# cert-manager.sh — Let's Encrypt / lego certificate manager for a Bitnami + Apache stack.
#
# Bitnami issues certs with `lego` into  /opt/bitnami/letsencrypt/certificates/
# but Apache reads them from           /opt/bitnami/apache/conf/<domain>.{crt,key}
# (REAL copies, root-owned — NOT symlinks). So a full renewal is:
#   stop apache -> lego renew (HTTP-01 on :80) -> copy+chmod into apache/conf -> start apache -> verify.
#
# DEPLOY (from your workstation):
#   scp cert-manager.sh bitnami@<host>:/opt/bitnami/letsencrypt/scripts/cert-manager.sh
#   ssh bitnami@<host> 'chmod +x /opt/bitnami/letsencrypt/scripts/cert-manager.sh'
#
# USE (on the server):
#   ./cert-manager.sh            # interactive menu (shows status first)
#   ./cert-manager.sh status     # show certificate status (no sudo needed)
#   sudo ./cert-manager.sh renew # renew + install + restart apache + verify
#   ./cert-manager.sh cron       # show current auto-renew schedule (config coming soon)
#   ./cert-manager.sh help
#
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Configuration (override with flags or env vars)
# ─────────────────────────────────────────────────────────────────────────────
DOMAIN="${CERT_DOMAIN:-xls.xionico.com}"
EMAIL="${CERT_EMAIL:-david.gonzalez@xionico.com}"
BITNAMI="${BITNAMI_ROOT:-/opt/bitnami}"
RENEW_DAYS="${CERT_RENEW_DAYS:-90}"      # renew if fewer than N days remain (expired => always)

LEGO_PATH="$BITNAMI/letsencrypt"
LEGO_BIN="$LEGO_PATH/lego"
APACHE_CONF="$BITNAMI/apache/conf"
CTL="$BITNAMI/ctlscript.sh"

LOG_FILE="${CERT_MANAGER_LOG:-$LEGO_PATH/scripts/cert-manager.log}"
SCRIPT_NAME="$(basename "$0")"
CMD=""

# Derived paths — recomputed after flag parsing (domain/path may change).
set_paths() {
    LEGO_CRT="$LEGO_PATH/certificates/$DOMAIN.crt"
    LEGO_KEY="$LEGO_PATH/certificates/$DOMAIN.key"
    APACHE_CRT="$APACHE_CONF/$DOMAIN.crt"
    APACHE_KEY="$APACHE_CONF/$DOMAIN.key"
}

# ─────────────────────────────────────────────────────────────────────────────
# Logging — single sink: colored console + plain-text log file (best effort).
# Everything the script does flows through here, so the log is the audit trail.
# ─────────────────────────────────────────────────────────────────────────────
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_RESET=$'\e[0m'; C_DIM=$'\e[2m'; C_STEP=$'\e[1;35m'
    C_INFO=$'\e[36m'; C_OK=$'\e[32m'; C_WARN=$'\e[33m'; C_ERR=$'\e[31m'
else
    C_RESET=""; C_DIM=""; C_STEP=""; C_INFO=""; C_OK=""; C_WARN=""; C_ERR=""
fi

init_log() {
    local dir; dir="$(dirname "$LOG_FILE")"
    if mkdir -p "$dir" 2>/dev/null && : >>"$LOG_FILE" 2>/dev/null; then
        return 0
    fi
    LOG_FILE=""   # not writable (e.g. `status` run as non-root) -> console only
}

_log() {
    local level="$1" color="$2"; shift 2
    local msg="$*"
    local ts; ts="$(date '+%Y-%m-%d %H:%M:%S')"
    printf '%s%s%s %s[%s]%s %s\n' "$C_DIM" "$ts" "$C_RESET" "$color" "$level" "$C_RESET" "$msg"
    [ -n "$LOG_FILE" ] && printf '[%s] [%s] %s\n' "$ts" "$level" "$msg" >>"$LOG_FILE" 2>/dev/null || true
}

log_step() { _log "STEP " "$C_STEP" "$*"; }
log_info() { _log "INFO " "$C_INFO" "$*"; }
log_ok()   { _log "OK   " "$C_OK"   "$*"; }
log_warn() { _log "WARN " "$C_WARN" "$*"; }
log_error(){ _log "ERROR" "$C_ERR" "$*"; }

# ─────────────────────────────────────────────────────────────────────────────
# Certificate helpers (read-only, work on any PEM file)
# ─────────────────────────────────────────────────────────────────────────────
cert_fingerprint() { openssl x509 -in "$1" -noout -fingerprint -sha256 2>/dev/null | cut -d= -f2; }

cert_days_left() {
    local crt="$1" end now
    end="$(openssl x509 -in "$crt" -noout -enddate 2>/dev/null | cut -d= -f2)" || return 1
    end="$(date -d "$end" +%s 2>/dev/null)" || return 1
    now="$(date +%s)"
    echo $(( (end - now) / 86400 ))
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "Action '${1:-this}' needs root: it binds port 80 and writes root-owned files in $APACHE_CONF."
        log_info  "Re-run as: sudo $0 ${1:-renew}"
        exit 1
    fi
}

# Safety net: if a renewal aborts after Apache was stopped, bring it back up.
_ensure_apache_up() {
    log_warn "Cleanup hook: making sure Apache is running again..."
    if "$CTL" start apache >/dev/null 2>&1; then
        log_ok "Apache is back up."
    else
        log_error "Could not start Apache. MANUAL ACTION NEEDED: $CTL start apache"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Command: status (default)
# ─────────────────────────────────────────────────────────────────────────────
cmd_status() {
    set_paths
    log_step "Certificate status — $DOMAIN"

    if [ ! -f "$APACHE_CRT" ]; then
        log_error "Apache certificate not found at $APACHE_CRT"
        return 0
    fi

    local subject issuer startd endd days
    subject="$(openssl x509 -in "$APACHE_CRT" -noout -subject 2>/dev/null | sed 's/^subject= *//')"
    issuer="$(openssl x509 -in "$APACHE_CRT" -noout -issuer  2>/dev/null | sed 's/^issuer= *//')"
    startd="$(openssl x509 -in "$APACHE_CRT" -noout -startdate 2>/dev/null | cut -d= -f2)"
    endd="$(openssl x509 -in "$APACHE_CRT" -noout -enddate   2>/dev/null | cut -d= -f2)"
    days="$(cert_days_left "$APACHE_CRT" 2>/dev/null || echo '')"

    log_info "Active cert (Apache) : $APACHE_CRT"
    log_info "  Subject : $subject"
    log_info "  Issuer  : $issuer"
    log_info "  Valid   : $startd  ->  $endd"

    if [ -z "$days" ]; then
        log_warn "  Expiry  : could not compute days remaining"
    elif [ "$days" -lt 0 ]; then
        log_error "  Expiry  : EXPIRED ${days#-} day(s) ago"
    elif [ "$days" -lt 14 ]; then
        log_warn "  Expiry  : EXPIRING SOON — $days day(s) left"
    else
        log_ok "  Expiry  : OK — $days day(s) left"
    fi

    # Does Apache's copy match lego's latest output?
    if [ -f "$LEGO_CRT" ]; then
        if [ "$(cert_fingerprint "$APACHE_CRT")" = "$(cert_fingerprint "$LEGO_CRT")" ]; then
            log_ok "  Sync    : Apache cert == lego's latest"
        else
            log_warn "  Sync    : MISMATCH — lego holds a different cert than Apache"
            log_warn "            (lego may have renewed without copying into apache/conf)."
            log_info "            lego copy expires in: $(cert_days_left "$LEGO_CRT" 2>/dev/null || echo '?') day(s)"
        fi
    else
        log_warn "  Sync    : no lego copy at $LEGO_CRT"
    fi

    # Apache process state ('not running' also contains 'running', so test it first).
    local st; st="$("$CTL" status apache 2>/dev/null || true)"
    if printf '%s' "$st" | grep -qiE 'not running|stopped'; then
        log_warn "  Apache  : NOT running"
    elif printf '%s' "$st" | grep -qi 'running'; then
        log_ok "  Apache  : running"
    else
        log_info "  Apache  : ${st:-status unknown}"
    fi

    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Command: renew
# ─────────────────────────────────────────────────────────────────────────────
cmd_renew() {
    set_paths
    require_root renew
    log_step "=== Renewal cycle for $DOMAIN (account: $EMAIL) ==="

    # Pre-flight
    [ -x "$LEGO_BIN" ] || { log_error "lego binary missing/not executable: $LEGO_BIN"; exit 1; }
    [ -x "$CTL" ]      || { log_error "Bitnami control script missing: $CTL"; exit 1; }

    log_step "[1/7] Status before renewal"
    cmd_status || true

    # [2/7] Backup whatever Apache is serving today.
    local ts bkdir
    ts="$(date '+%Y%m%d%H%M%S')"
    bkdir="$APACHE_CONF/cert-backups"
    mkdir -p "$bkdir"
    log_step "[2/7] Backing up current Apache cert/key -> $bkdir"
    [ -f "$APACHE_CRT" ] && cp -a "$APACHE_CRT" "$bkdir/$DOMAIN.crt.$ts" && log_ok  "Backed up crt ($DOMAIN.crt.$ts)"
    [ -f "$APACHE_KEY" ] && cp -a "$APACHE_KEY" "$bkdir/$DOMAIN.key.$ts" && log_ok  "Backed up key ($DOMAIN.key.$ts)"

    # [3/7] Free port 80 for the HTTP-01 challenge. Arm the safety net first.
    log_step "[3/7] Stopping Apache to free port 80"
    trap '_ensure_apache_up' EXIT INT TERM
    if "$CTL" stop apache; then log_ok "Apache stopped"; else log_error "Failed to stop Apache"; exit 1; fi

    # [4/7] Renew. lego runs its own webserver on :80 for the challenge.
    log_step "[4/7] Running lego renew (HTTP-01)"
    if "$LEGO_BIN" \
            --accept-tos \
            --email="$EMAIL" \
            --domains="$DOMAIN" \
            --path="$LEGO_PATH" \
            --http \
            renew --days "$RENEW_DAYS" --no-random-sleep; then
        log_ok "lego renew completed"
    else
        rc=$?
        log_error "lego renew FAILED (exit $rc). Apache will be restarted with the existing cert."
        exit 1   # EXIT trap restarts Apache
    fi

    [ -f "$LEGO_CRT" ] && [ -f "$LEGO_KEY" ] || { log_error "Renewed files not found in $LEGO_PATH/certificates"; exit 1; }

    # [5/7] Install into apache/conf with correct ownership + perms.
    log_step "[5/7] Installing renewed cert/key into $APACHE_CONF"
    install -o root -g root -m 644 "$LEGO_CRT" "$APACHE_CRT" && log_ok "Installed crt (644 root:root)"
    install -o root -g root -m 600 "$LEGO_KEY" "$APACHE_KEY" && log_ok "Installed key (600 root:root)"

    # [6/7] Bring Apache back. Disarm the safety net so we can report start failures.
    log_step "[6/7] Starting Apache"
    trap - EXIT INT TERM
    if "$CTL" start apache; then
        log_ok "Apache started"
    else
        log_error "Apache FAILED to start. Check config: $CTL status apache  /  apachectl -t"
        exit 1
    fi

    # [7/7] Verify the new state.
    log_step "[7/7] Verification"
    cmd_status
    local days; days="$(cert_days_left "$APACHE_CRT" 2>/dev/null || echo '?')"
    if [ "$days" != "?" ] && [ "$days" -gt 0 ]; then
        log_ok "=== Renewal SUCCESSFUL — certificate valid for $days more day(s). ==="
    else
        log_warn "=== Renewal ran but expiry check is inconclusive. Verify manually. ==="
    fi
    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Command: cron (view-only for now; configuration will land in a later iteration)
# ─────────────────────────────────────────────────────────────────────────────
cmd_cron() {
    log_step "Auto-renew schedule (VIEW ONLY — configuration coming soon)"
    local found=0

    log_info "User crontab ($(whoami)):"
    if crontab -l 2>/dev/null | grep -iE 'lego|cert-manager|renew'; then found=1; fi

    if [ "$(id -u)" -eq 0 ]; then
        log_info "System cron (/etc/cron.d, /etc/crontab):"
        if grep -rIsE 'lego|cert-manager' /etc/cron.d /etc/crontab 2>/dev/null; then found=1; fi
    else
        log_info "(run with sudo to also inspect root/system cron)"
    fi

    log_info "systemd timers:"
    if systemctl list-timers --all 2>/dev/null | grep -iE 'cert|lego'; then found=1; fi

    if [ "$found" -eq 0 ]; then
        log_warn "No automatic renewal schedule found — the cert will NOT renew on its own."
        log_warn "This is the likely reason it expired. Scheduling will be added in a later iteration."
    fi
    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Command: help
# ─────────────────────────────────────────────────────────────────────────────
cmd_help() {
    cat <<EOF
${C_STEP}cert-manager${C_RESET} — Let's Encrypt / lego certificate manager (Bitnami + Apache)

${C_INFO}USAGE${C_RESET}
  $SCRIPT_NAME [command] [options]

${C_INFO}COMMANDS${C_RESET}
  status        Show certificate status (no sudo needed). DEFAULT in the menu.
  renew         Renew (needs sudo): backup -> stop apache -> lego HTTP-01
                -> install cert -> start apache -> verify.
  cron          Show the current auto-renew schedule (configuration coming soon).
  help          Show this help.

${C_INFO}OPTIONS${C_RESET}
  -d, --domain <fqdn>   Domain                       (default: $DOMAIN)
  -e, --email  <email>  ACME account email           (default: $EMAIL)
      --days   <n>      Renew if < n days remain      (default: $RENEW_DAYS)
  -h, --help            Show this help.

With NO command, an interactive menu is shown (current status first).

${C_DIM}Log file: ${LOG_FILE:-<disabled: not writable>}${C_RESET}
EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# Interactive menu (default action: show status, then offer choices)
# ─────────────────────────────────────────────────────────────────────────────
menu() {
    log_step "cert-manager — interactive mode"
    cmd_status
    echo
    local PS3=$'\nSelect an option (number): '
    local opt
    select opt in "Show status" "Renew certificate now" "Cron (view)" "Help" "Quit"; do
        case "${REPLY:-}" in
            1) echo; cmd_status ;;
            2) echo; cmd_renew  ;;
            3) echo; cmd_cron   ;;
            4) echo; cmd_help   ;;
            5) log_info "Bye."; break ;;
            *) log_warn "Invalid option: ${REPLY:-<empty>}" ;;
        esac
        echo
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# Argument parsing + dispatch
# ─────────────────────────────────────────────────────────────────────────────
main() {
    local positional=()
    while [ $# -gt 0 ]; do
        case "$1" in
            -d|--domain) DOMAIN="$2"; shift 2 ;;
            --domain=*)  DOMAIN="${1#*=}"; shift ;;
            -e|--email)  EMAIL="$2"; shift 2 ;;
            --email=*)   EMAIL="${1#*=}"; shift ;;
            --days)      RENEW_DAYS="$2"; shift 2 ;;
            --days=*)    RENEW_DAYS="${1#*=}"; shift ;;
            -h|--help)   CMD="help"; shift ;;
            --)          shift; while [ $# -gt 0 ]; do positional+=("$1"); shift; done ;;
            -*)          log_error "Unknown option: $1"; exit 1 ;;
            *)           positional+=("$1"); shift ;;
        esac
    done

    CMD="${CMD:-${positional[0]:-menu}}"
    set_paths
    init_log

    case "$CMD" in
        status) cmd_status ;;
        renew)  cmd_renew  ;;
        cron)   cmd_cron   ;;
        menu)   menu       ;;
        help)   cmd_help   ;;
        *)      log_error "Unknown command: $CMD"; echo; cmd_help; exit 1 ;;
    esac
}

main "$@"
