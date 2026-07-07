#!/usr/bin/env bash
# htpc-remote.sh — Stream and control the HTPC server (Sunshine) via Moonlight.
# Bound to $super + R in configs/keybinds.conf. See docs/server-htpc-migration.md.
#
# One-time pairing (over Tailscale):
#   moonlight pair the-grid-server
#   → enter the PIN it prints at https://the-grid-server:47990 (Sunshine web UI)
#
# Audio: pick per-connection in Moonlight settings — "Play audio on host PC"
# keeps sound on the server's stereo (HTPC mode) instead of streaming it here.
#
# Overridable via env: HTPC_HOST, HTPC_APP.

set -euo pipefail

HOST="${HTPC_HOST:-the-grid-server}"   # Tailscale MagicDNS name
APP="${HTPC_APP:-Desktop}"

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send "HTPC · Moonlight" "$1"
  printf '%s\n' "$1" >&2
}

if ! command -v moonlight >/dev/null 2>&1; then
  notify "moonlight not found — rebuild main (moonlight-qt in home.nix)."
  exit 1
fi

if ! moonlight stream "$HOST" "$APP"; then
  notify "Stream failed — server down, unpaired, or Tailscale off?"
  exit 1
fi
