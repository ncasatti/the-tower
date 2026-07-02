#!/usr/bin/env bash
# rdp-htpc.sh — Connect to the HTPC server (hypr-rdp) over Tailscale.
# Bound to $super + R in configs/keybinds.conf. See docs/server-htpc-migration.md.
#
# The RDP password is NEVER stored in the repo / Nix store (world-readable).
# Create it out-of-band, chmod 600:
#   mkdir -p ~/.config/hypr-rdp-client
#   printf '%s' 'your-password' > ~/.config/hypr-rdp-client/pass
#   chmod 600 ~/.config/hypr-rdp-client/pass
#
# Overridable via env: RDP_HOST, RDP_PORT, RDP_USER, RDP_PASS_FILE.

set -euo pipefail

HOST="${RDP_HOST:-the-grid-server}"        # Tailscale MagicDNS name
PORT="${RDP_PORT:-7777}"
RUSER="${RDP_USER:-flyn}"
PASS_FILE="${RDP_PASS_FILE:-$HOME/.config/hypr-rdp-client/pass}"

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send "RDP · HTPC" "$1"
  printf '%s\n' "$1" >&2
}

if [[ ! -r "$PASS_FILE" ]]; then
  notify "No password file at $PASS_FILE (create it, chmod 600). Aborting."
  exit 1
fi

# /gfx:AVC420 matches the server's egfx_codec; audio stays local (server
# audio_mode=off) so no /sound; /cert:ignore accepts hypr-rdp's self-signed cert.
# NO /dynamic-resolution: hypr-rdp mirrors the physical eDP-1 output, and dynamic
# resize against a physical output triggers an endless presentation-resize loop
# (blank screen at fullscreen). Re-add it ONLY if config.toml switches to a
# managed headless output (drop the `output` line there).
if ! xfreerdp \
  /v:"$HOST:$PORT" \
  /u:"$RUSER" \
  /p:"$(< "$PASS_FILE")" \
  /gfx:AVC420 \
  +clipboard \
  /cert:ignore \
  /log-level:WARN \
  /t:"HTPC — The Grid"; then
  notify "Connection failed — server down, or Tailscale off?"
  exit 1
fi
