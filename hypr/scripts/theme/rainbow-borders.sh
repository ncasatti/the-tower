#!/usr/bin/env bash
#!/bin/bash
source "$HOME/.cache/hypr/wallust/colors-bash.sh"

function random_hex() {
    random_hex=("0xff$(openssl rand -hex 3)")
    echo $random_hex
}

function hex_to_0x() {
    # Remueve el # si existe y agrega 0xff al principio
    echo "0xff${1#\#}"
}

C0=$(hex_to_0x $COLOR0)
C1=$(hex_to_0x $COLOR1)
C2=$(hex_to_0x $COLOR2)
C3=$(hex_to_0x $COLOR3)
C4=$(hex_to_0x $COLOR4)
C5=$(hex_to_0x $COLOR5)
C6=$(hex_to_0x $COLOR6)
C7=$(hex_to_0x $COLOR7)
C8=$(hex_to_0x $COLOR8)
C9=$(hex_to_0x $COLOR9)
C10=$(hex_to_0x $COLOR10)
C11=$(hex_to_0x $COLOR11)
C12=$(hex_to_0x $COLOR12)
C13=$(hex_to_0x $COLOR13)
C14=$(hex_to_0x $COLOR14)
C15=$(hex_to_0x $COLOR15)

# DEPRECATED: per-color angles don't work via `hyprctl keyword` IPC — the parser only takes the
# first color+angle pair and silently drops the rest. So this script can NOT set per-side gradients.
#
# Rainbow border is now configured directly in:
#   hypr/configs/settings.conf  (general { col.active_border = ... per-color angles })
# Animation: animation = borderangle, 1, 60, linear, loop  (in the animations block)
#
# This script is kept as a no-op stub for backwards compat (refresh.sh may call it).
echo "[rainbow-borders] deprecated; rainbow border is configured in settings.conf" >&2
