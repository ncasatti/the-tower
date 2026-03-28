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

# Random Rainbow Border
# hyprctl keyword general:col.active_border $(random_hex)  $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex)  270deg
# hyprctl keyword general:col.inactive_border $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex)  270deg

# Wallpaper Colors Border
# hyprctl keyword general:col.active_border $C0 $C1 $C2 $C3 $C4 $C5 $C6 $C7 $C8 $C9 $C10 $C11 $C12 0deg
# hyprctl keyword general:col.active_border $C1 $C2 $C3 $C4 $C9 $C10 $C12 $C0 $C13 $C7 90deg
hyprctl keyword general:col.active_border $C14 $C5 $C13 $C11 $C10 $C7 90deg
# hyprctl keyword general:col.inactive_border $C0 $C1 $C2 $C3 $C4 $C5 0deg
