#!/usr/bin/env bash
# htpc-toggle.sh — Visual toggle indicator for Moonlight keyboard capture.
# Bound to $super + SHIFT + R in configs/keybinds.conf.
#
# IMPORTANT: this script does NOT control Moonlight itself. Moonlight always
# eats Super as a host shortcut, so this bind never reaches the server. The
# real capture is the "Capture keyboard" toggle in Moonlight's tray menu —
# flip that manually before using alt+n/alt+space on the remote side.
#
# What this DOES: maintain a local flag in ~/.cache/hypr/htpc-grab.flag and
# raise a Hyprland OSD via `hyprctl notify` so you can see which way the
# input is going. hyprctl notify draws on the overlay layer, so the OSD is
# visible above any fullscreen window (including Moonlight), unlike
# notify-send which is rendered under fullscreen exclusive surfaces.

set -euo pipefail

FLAG="${XDG_CACHE_HOME:-$HOME/.cache}/hypr/htpc-grab.flag"
ID=1001                                 # fixed → repeated calls REPLACE
COLOR_CAPTURED="rgb(50c878)"            # emerald — driving the server
COLOR_RELEASED="rgb(808080)"            # grey   — input back on client

# Accept optional "on"/"off" for scripting/debugging; default = toggle.
case "${1:-toggle}" in
  on)      STATE=on ;;
  off)     STATE=off ;;
  toggle)  if [[ -e "$FLAG" ]]; then STATE=off; else STATE=on; fi ;;
  *)
    printf 'usage: %s [on|off|toggle]\n' "$0" >&2
    exit 2
    ;;
esac

case "$STATE" in
  on)
    mkdir -p "$(dirname "$FLAG")"
    : > "$FLAG"
    MSG="⌨  Keyboard captured → remote
Moonlight is driving the server."
    COLOR="$COLOR_CAPTURED"
    ;;
  off)
    rm -f "$FLAG"
    MSG="🖥  Keyboard released → local
Moonlight hands input back to this desktop."
    COLOR="$COLOR_RELEASED"
    ;;
esac

hyprctl notify "$ID" 4000 "$COLOR" "$MSG"
