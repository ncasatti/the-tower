#!/usr/bin/env bash
# Randomly cycle wallpapers from a directory at a fixed interval

scripts_dir="$HOME/.config/hypr/scripts"
focused_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')

if [[ $# -lt 1 ]] || [[ ! -d $1 ]]; then
    echo "Usage: $0 <dir containing images>"
    exit 1
fi

INTERVAL=1800

while true; do
    find "$1" \
        | while read -r img; do
            echo "$((RANDOM % 1000)):$img"
        done \
        | sort -n | cut -d':' -f2- \
        | while read -r img; do
            "${scripts_dir}/theme/wallpaper-set.sh" "$img"
            "${scripts_dir}/theme/wallpaper-colors.sh"
            "${scripts_dir}/system/refresh.sh"
            sleep $INTERVAL
        done
done
