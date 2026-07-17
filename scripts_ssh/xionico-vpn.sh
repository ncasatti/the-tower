#!/usr/bin/env bash
#
# xionico-vpn.sh — Unified OpenVPN client manager for the Xionico server.
#
# Single source of truth: easy-rsa PKI index (pki/index.txt).
# One profile only (the two-VPN split — "soporte" vs "VMs" — was consolidated
# into a single tunnel on UDP 1195; the server pushes redirect-gateway + routes,
# so the client profile stays minimal).
#
# Replaces the legacy manage-clients.sh and manage-clients-new.sh.

set -euo pipefail

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------
VPN_SERVER="44.235.240.158"
VPN_PORT="1195"                 # the ONLY port actually listening (443 was dead)
VPN_PROTO="udp"
SERVER_CN="server_1efElTMbv7JnUJ0F"

EASYRSA_DIR="/etc/openvpn/easy-rsa"
PKI_DIR="${EASYRSA_DIR}/pki"
INDEX="${PKI_DIR}/index.txt"
KEY_DIR="${PKI_DIR}/private"
CERT_DIR="${PKI_DIR}/issued"
CA_CRT="${PKI_DIR}/ca.crt"
TLS_CRYPT="/etc/openvpn/tls-crypt.key"

OUTPUT_DIR="/etc/openvpn/client-configs"   # canonical, single output location
CCD_DIR="/etc/openvpn/ccd"                 # per-client static IPs

SHOW_REVOKED=0                             # hide revoked clients by default

# ----------------------------------------------------------------------------
# UI helpers
# ----------------------------------------------------------------------------
RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'; BOLD=$'\033[1m'; NC=$'\033[0m'

die()  { echo "${RED}Error: $1${NC}" >&2; exit 1; }
info() { echo "${YELLOW}$1${NC}"; }
ok()   { echo "${GREEN}$1${NC}"; }

require_root() {
  [ "${EUID:-$(id -u)}" -eq 0 ] || die "Este script debe ejecutarse como root (sudo)."
}

pause() { read -rp "Presione ENTER para continuar..."; }

validate_name() {
  [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]] || die "Nombre inválido: solo letras, números, '-' y '_'."
}

# YYMMDDHHMMSSZ -> YYYY-MM-DD (all current certs are 20xx)
fmt_date() {
  local r="$1"
  printf '20%s-%s-%s' "${r:0:2}" "${r:2:2}" "${r:4:2}"
}

# ----------------------------------------------------------------------------
# PKI reading (index.txt is the truth)
# ----------------------------------------------------------------------------
# Emits one row per CN as: STATUS|EXPIRY|CN
#   STATUS = V (has a valid cert) or R (only revoked entries)
# Skips the server certificate.
pki_rows() {
  awk -F'\t' '
    {
      cn = $NF; sub(/.*\/CN=/, "", cn);
      if (cn ~ /^server_/) next;
      if ($1 == "V") { valid[cn] = $2 }
      else           { if (!(cn in revoked)) revoked[cn] = $2 }
      all[cn] = 1;
    }
    END {
      for (cn in all) {
        if (cn in valid) print "V|" valid[cn] "|" cn;
        else             print "R|" revoked[cn] "|" cn;
      }
    }' "$INDEX" | sort -t'|' -k3,3
}

# Populated by load_list(): parallel arrays indexed 1..N (aligned with the table)
declare -a L_NAME L_STATUS L_EXPIRY
REVOKED_HIDDEN=0
load_list() {
  L_NAME=(""); L_STATUS=(""); L_EXPIRY=("")   # index 0 unused
  REVOKED_HIDDEN=0
  local st ex cn
  while IFS='|' read -r st ex cn; do
    [ -n "$cn" ] || continue
    if [ "$st" = "R" ] && [ "$SHOW_REVOKED" -eq 0 ]; then
      REVOKED_HIDDEN=$((REVOKED_HIDDEN + 1)); continue
    fi
    L_NAME+=("$cn"); L_STATUS+=("$st"); L_EXPIRY+=("$ex")
  done < <(pki_rows)
}

static_ip() {
  local f="${CCD_DIR}/$1"
  [ -f "$f" ] && grep -oE '10\.8\.0\.[0-9]+' "$f" 2>/dev/null | head -1 || true
}

has_ovpn() { [ -f "${OUTPUT_DIR}/$1.ovpn" ]; }

# ----------------------------------------------------------------------------
# Listing
# ----------------------------------------------------------------------------
print_table() {
  load_list
  local n=$(( ${#L_NAME[@]} - 1 ))
  echo "${BLUE}${BOLD}  #   CLIENTE                    ESTADO     EXPIRA       IP FIJA      OVPN${NC}"
  echo "${BLUE}  ------------------------------------------------------------------------${NC}"
  local i
  for (( i=1; i<=n; i++ )); do
    local st="${L_STATUS[$i]}" color="$GREEN" label="VÁLIDO"
    if [ "$st" = "R" ]; then color="$RED"; label="REVOCADO"; fi
    local ip; ip="$(static_ip "${L_NAME[$i]}")"; [ -n "$ip" ] || ip="dinámica"
    local ov="no"; has_ovpn "${L_NAME[$i]}" && ov="sí"
    printf "${color}  %-3s %-26s %-10s %-12s %-12s %-4s${NC}\n" \
      "$i" "${L_NAME[$i]}" "$label" "$(fmt_date "${L_EXPIRY[$i]}")" "$ip" "$ov"
  done
  echo "${BLUE}  ------------------------------------------------------------------------${NC}"
  if [ "$SHOW_REVOKED" -eq 1 ]; then
    echo "${GREEN}  Total: $n cliente(s) ${YELLOW}(revocados incluidos)${NC}"
  else
    echo "${GREEN}  Total: $n activo(s)${NC}${YELLOW}   ${REVOKED_HIDDEN} revocado(s) oculto(s)${NC}"
  fi
}

# ----------------------------------------------------------------------------
# Profile generation (single template, cloned from a known-working client)
# ----------------------------------------------------------------------------
write_ovpn() {
  local name="$1" out="$2"
  [ -f "${CERT_DIR}/${name}.crt" ] || die "Falta el certificado de ${name}."
  [ -f "${KEY_DIR}/${name}.key" ]  || die "Falta la clave de ${name}."
  cat > "$out" <<EOF
client
proto ${VPN_PROTO}
explicit-exit-notify
remote ${VPN_SERVER} ${VPN_PORT}
dev tun
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verify-x509-name ${SERVER_CN} name
auth SHA256
auth-nocache
cipher AES-128-GCM
tls-client
tls-version-min 1.2
tls-cipher TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256
ignore-unknown-option block-outside-dns
setenv opt block-outside-dns
verb 3
<ca>
$(cat "$CA_CRT")
</ca>
<cert>
$(awk '/BEGIN/,/END/' "${CERT_DIR}/${name}.crt")
</cert>
<key>
$(cat "${KEY_DIR}/${name}.key")
</key>
<tls-crypt>
$(cat "$TLS_CRYPT")
</tls-crypt>
EOF
  chmod 600 "$out"
}

export_separate() {
  local name="$1" dir="${OUTPUT_DIR}"
  [ -f "${CERT_DIR}/${name}.crt" ] || die "Falta el certificado de ${name}."
  cp "$CA_CRT"                    "${dir}/${name}-ca.pem"
  awk '/BEGIN/,/END/' "${CERT_DIR}/${name}.crt" > "${dir}/${name}-cert.pem"
  cp "${KEY_DIR}/${name}.key"     "${dir}/${name}-key.pem"
  cp "$TLS_CRYPT"                 "${dir}/${name}-tls-crypt.pem"
  chmod 600 "${dir}/${name}"-*.pem
  ok "Certificados sueltos generados en ${dir}/:"
  echo "  ${name}-ca.pem  ${name}-cert.pem  ${name}-key.pem  ${name}-tls-crypt.pem"
  info "Formato para dispositivos que no aceptan .ovpn inline (MikroTik/RouterOS, pfSense)."
}

# ----------------------------------------------------------------------------
# Actions
# ----------------------------------------------------------------------------
create_client() {
  local name ip
  read -rp "Nombre del nuevo cliente: " name
  validate_name "$name"
  if [ -f "${KEY_DIR}/${name}.key" ]; then
    read -rp "Ya existe '${name}'. ¿Sobrescribir? (yes/no): " a
    [ "$a" = "yes" ] || { info "Cancelado."; return; }
  fi
  mkdir -p "$OUTPUT_DIR" "$CCD_DIR"
  info "Generando certificados para ${name}..."
  ( cd "$EASYRSA_DIR"
    ./easyrsa --batch gen-req "$name" nopass
    ./easyrsa --batch sign-req client "$name" ) || die "Falló la emisión del certificado."

  read -rp "¿Asignar IP fija? (10.8.0.x / vacío = dinámica): " ip
  if [ -n "$ip" ]; then
    [[ "$ip" =~ ^10\.8\.0\.([0-9]{1,3})$ ]] || die "IP inválida (formato 10.8.0.x)."
    [ "${BASH_REMATCH[1]}" -ge 1 ] && [ "${BASH_REMATCH[1]}" -le 254 ] || die "Octeto 1-254."
    echo "ifconfig-push ${ip} 255.255.255.0" > "${CCD_DIR}/${name}"
    chmod 644 "${CCD_DIR}/${name}"
    ok "IP fija ${ip} asignada."
  fi

  write_ovpn "$name" "${OUTPUT_DIR}/${name}.ovpn"
  ok "Cliente ${name} creado: ${OUTPUT_DIR}/${name}.ovpn"
}

revoke_client() {
  local name="$1"
  read -rp "¿Revocar '${name}'? Esto lo desconecta. (yes/no): " a
  [ "$a" = "yes" ] || { info "Cancelado."; return; }
  ( cd "$EASYRSA_DIR"
    ./easyrsa --batch revoke "$name"
    ./easyrsa gen-crl ) || die "Falló la revocación."
  cp "${PKI_DIR}/crl.pem" /etc/openvpn/
  chmod 644 /etc/openvpn/crl.pem
  rm -f "${OUTPUT_DIR}/${name}.ovpn" "${OUTPUT_DIR}/${name}"-*.pem
  ok "Cliente ${name} revocado. La CRL se aplicará en el próximo ciclo del server."
}

# Full delete: revoke (if still valid) THEN purge all client material.
# The revoked entry stays in index.txt on purpose — it feeds the CRL.
purge_client() {
  local name="$1"
  echo
  echo "${RED}${BOLD}⚠ BORRADO COMPLETO de '${name}'${NC}"
  echo "  Revoca el certificado Y elimina cert, clave, request, .ovpn, .pem e IP fija."
  echo "  La entrada queda como REVOCADA en el registro PKI (necesario para la CRL)."
  read -rp "Escriba el nombre exacto del cliente para confirmar: " confirm
  [ "$confirm" = "$name" ] || { info "Cancelado (el nombre no coincide)."; return; }

  # Never orphan a valid cert: revoke it first.
  if grep -q "^V.*/CN=${name}\$" "$INDEX"; then
    info "Revocando antes de purgar..."
    ( cd "$EASYRSA_DIR"
      ./easyrsa --batch revoke "$name"
      ./easyrsa gen-crl ) || die "Falló la revocación."
    cp "${PKI_DIR}/crl.pem" /etc/openvpn/
    chmod 644 /etc/openvpn/crl.pem
  fi

  rm -fv "${CERT_DIR}/${name}.crt" \
         "${KEY_DIR}/${name}.key" \
         "${PKI_DIR}/reqs/${name}.req" \
         "${OUTPUT_DIR}/${name}.ovpn" \
         "${CCD_DIR}/${name}" 2>/dev/null || true
  rm -fv "${OUTPUT_DIR}/${name}"-*.pem 2>/dev/null || true
  ok "Cliente ${name} borrado por completo."
}

# Consolidation: regenerate .ovpn (canonical location) for every VALID cert
# that still has key+cert on disk. Never copies old files (some point to 443).
regen_all() {
  load_list
  local i n regen=0 skip=0
  mkdir -p "$OUTPUT_DIR"
  for (( i=1; i<${#L_NAME[@]}; i++ )); do
    n="${L_NAME[$i]}"
    [ "${L_STATUS[$i]}" = "V" ] || continue
    if [ -f "${CERT_DIR}/${n}.crt" ] && [ -f "${KEY_DIR}/${n}.key" ]; then
      write_ovpn "$n" "${OUTPUT_DIR}/${n}.ovpn"
      echo "  ${GREEN}regenerado${NC}: ${n}.ovpn"
      regen=$((regen+1))
    else
      echo "  ${YELLOW}omitido (falta key/crt)${NC}: ${n}"
      skip=$((skip+1))
    fi
  done
  ok "Consolidación: ${regen} regenerados, ${skip} omitidos."
}

# Machine-readable list of downloadable clients (one name per line).
# Consumed by --local; keep it plain (no colors, no headers).
list_names() {
  ls -1 "$OUTPUT_DIR"/*.ovpn 2>/dev/null | while read -r f; do
    basename "$f" .ovpn
  done | sort
}

# ----------------------------------------------------------------------------
# Local mode (runs on the operator's PC, NOT on the server)
# Thin client: asks the server's script for the list, then downloads the
# selected profile via `ssh sudo cat`. Reimplements no PKI logic.
# ----------------------------------------------------------------------------
local_download() {
  local host="${XIONICO_VPN_HOST:-vpn-xionico}"
  local remote_dir="/etc/openvpn/client-configs"

  info "Obteniendo lista de clientes desde ${host}..."
  local names
  names="$(ssh "$host" 'sudo xionico-vpn names' 2>/dev/null)" \
    || die "No se pudo conectar a ${host} o el script remoto no respondió."
  [ -n "$names" ] || die "No hay perfiles descargables en el servidor."

  local sel
  if command -v fzf >/dev/null 2>&1; then
    sel="$(printf '%s\n' "$names" | fzf --prompt='Cliente a descargar> ' --height=40% --reverse)"
  else
    local -a arr; mapfile -t arr <<<"$names"
    local i
    for i in "${!arr[@]}"; do printf "  %3d  %s\n" "$((i + 1))" "${arr[$i]}"; done
    local n; read -rp "Número: " n
    [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "${#arr[@]}" ] \
      || die "Selección inválida."
    sel="${arr[$((n - 1))]}"
  fi
  [ -n "$sel" ] || { info "Cancelado."; exit 0; }

  local out="./${sel}.ovpn"
  info "Descargando ${sel}.ovpn ..."
  if ssh "$host" "sudo cat ${remote_dir}/${sel}.ovpn" > "$out" && [ -s "$out" ]; then
    chmod 600 "$out"
    ok "Guardado: ${out}  (chmod 600 — contiene la clave privada)"
  else
    rm -f "$out"   # never leave an empty/half file on failure
    die "No se pudo descargar ${sel}.ovpn"
  fi
}

set_static_ip() {
  local name="$1" ip
  read -rp "Nueva IP fija (10.8.0.x / vacío = quitar): " ip
  if [ -z "$ip" ]; then
    rm -f "${CCD_DIR}/${name}"; ok "IP fija removida (vuelve a dinámica)."; return
  fi
  [[ "$ip" =~ ^10\.8\.0\.([0-9]{1,3})$ ]] || die "IP inválida."
  echo "ifconfig-push ${ip} 255.255.255.0" > "${CCD_DIR}/${name}"
  chmod 644 "${CCD_DIR}/${name}"
  ok "IP fija ${ip} asignada a ${name}."
}

show_client() {
  local name="$1"
  echo
  echo "${BOLD}Cliente: ${name}${NC}"
  grep "/CN=${name}\$" "$INDEX" | while IFS=$'\t' read -r st ex rest; do
    local lbl="VÁLIDO"; [ "$st" = "R" ] && lbl="REVOCADO"
    echo "  entrada PKI: ${lbl}  (expira $(fmt_date "$ex"))"
  done
  local ip; ip="$(static_ip "$name")"
  echo "  IP fija    : ${ip:-dinámica}"
  echo "  .ovpn      : $(has_ovpn "$name" && echo "${OUTPUT_DIR}/${name}.ovpn" || echo "no generado")"
  echo "  clave/cert : $( [ -f "${KEY_DIR}/${name}.key" ] && echo presente || echo AUSENTE )"
}

manage_client() {
  local name="$1"
  while true; do
    show_client "$name"
    echo
    echo "  1  Regenerar .ovpn (inline)"
    echo "  2  Exportar certificados sueltos (.pem para router/MikroTik)"
    echo "  3  Asignar/cambiar IP fija"
    echo "  4  ${YELLOW}Revocar cliente${NC} (invalida, conserva material)"
    echo "  5  ${RED}Borrar por completo${NC} (revoca + elimina todo)"
    echo "  b  Volver"
    read -rp "Opción: " op
    case "$op" in
      1) write_ovpn "$name" "${OUTPUT_DIR}/${name}.ovpn"; ok "Regenerado."; pause ;;
      2) export_separate "$name"; pause ;;
      3) set_static_ip "$name"; pause ;;
      4) revoke_client "$name"; pause; return ;;
      5) purge_client "$name"; pause; return ;;
      b|B) return ;;
      *) info "Opción inválida." ;;
    esac
  done
}

# ----------------------------------------------------------------------------
# Audit — report the inherited mess (read-only)
# ----------------------------------------------------------------------------
audit() {
  echo
  echo "${BOLD}===== AUDITORÍA =====${NC}"

  echo "${BOLD}[1] .ovpn regados en múltiples ubicaciones${NC}"
  local a b
  a=$(ls -1 /home/ubuntu/*.ovpn 2>/dev/null | wc -l)
  b=$(ls -1 "${OUTPUT_DIR}"/*.ovpn 2>/dev/null | wc -l)
  echo "    /home/ubuntu/        : ${a} archivos"
  echo "    ${OUTPUT_DIR}/ : ${b} archivos  (ubicación canónica)"

  echo "${BOLD}[2] .ovpn apuntando al puerto muerto 443${NC}"
  local broken
  broken=$(grep -rl "remote ${VPN_SERVER} 443" /home/ubuntu/*.ovpn "${OUTPUT_DIR}"/*.ovpn 2>/dev/null | wc -l)
  echo "    ${broken} perfil(es) rotos (deberían ser ${VPN_PORT})"

  echo "${BOLD}[3] Nombres con convención inconsistente${NC}"
  pki_rows | cut -d'|' -f3 | grep -iE 'mov(il|ile)$|_' | sed 's/^/    /' || true
  echo "    (revisar guion vs guion_bajo y movil/movile/mobile)"

  echo "${BOLD}[4] Certificados VÁLIDOS sin .ovpn generado${NC}"
  load_list
  local i cnt=0
  for (( i=1; i<${#L_NAME[@]}; i++ )); do
    if [ "${L_STATUS[$i]}" = "V" ] && ! has_ovpn "${L_NAME[$i]}"; then
      echo "    ${L_NAME[$i]}"; cnt=$((cnt+1))
    fi
  done
  [ "$cnt" -eq 0 ] && echo "    (ninguno)"

  echo "${BOLD}[5] Servicios OpenVPN fantasma${NC}"
  echo "    openvpn-server@server  -> crash-loop (config inexistente)"
  echo "    openvpn@server-vms     -> muerto (server-vms.conf inexistente)"
  echo "    Único vivo: openvpn@server (UDP ${VPN_PORT})"
  echo "${BOLD}=====================${NC}"
}

# ----------------------------------------------------------------------------
# Main menu
# ----------------------------------------------------------------------------
main_menu() {
  while true; do
    clear
    echo "${BOLD}${BLUE}=== VPN Xionico — Gestión de clientes ===${NC}"
    print_table
    echo
    local rev_lbl="mostrar revocados"; [ "$SHOW_REVOKED" -eq 1 ] && rev_lbl="ocultar revocados"
    echo "  ${BOLD}[número]${NC} gestionar   ${BOLD}n${NC} nuevo   ${BOLD}a${NC} auditoría   ${BOLD}x${NC} ${rev_lbl}   ${BOLD}r${NC} refrescar   ${BOLD}q${NC} salir"
    read -rp "Opción: " sel
    case "$sel" in
      ''|q|Q) exit 0 ;;
      n|N) create_client; pause ;;
      a|A) audit; pause ;;
      x|X) SHOW_REVOKED=$((1 - SHOW_REVOKED)) ;;
      r|R) : ;;
      *[!0-9]*) info "Opción inválida."; sleep 1 ;;
      *)
        load_list
        if [ "$sel" -ge 1 ] && [ "$sel" -lt "${#L_NAME[@]}" ]; then
          manage_client "${L_NAME[$sel]}"
        else
          info "Número fuera de rango."; sleep 1
        fi
        ;;
    esac
  done
}

# Local mode short-circuits BEFORE require_root / any server-side assumption.
if [ "${1:-}" = "--local" ]; then
  local_download
  exit 0
fi

require_root
case "${1:-}" in
  audit)     audit ;;
  list)      [ "${2:-}" = "all" ] && SHOW_REVOKED=1; print_table ;;
  names)     list_names ;;
  regen-all) regen_all ;;
  "")        main_menu ;;
  *)         echo "Uso:"; \
             echo "  xionico-vpn                 menú interactivo (en el server)"; \
             echo "  xionico-vpn audit|list|list all|regen-all|names"; \
             echo "  xionico-vpn --local         descargar un .ovpn a tu PC"; \
             exit 1 ;;
esac
