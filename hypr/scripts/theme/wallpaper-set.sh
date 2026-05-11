#!/usr/bin/env bash
# Primitive: set wallpaper, write state, update symlink for hyprlock

CACHE_DIR="$HOME/.cache/hypr"
focused_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')

FPS=144
TYPE="any"
DURATION=0.8
AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION"

wallpaper_path="$1"

if [[ -z "$wallpaper_path" ]] || [[ ! -f "$wallpaper_path" ]]; then
    echo "Usage: wallpaper-set.sh <path>" >&2
    exit 1
fi

mkdir -p "$CACHE_DIR"

if pidof swaybg >/dev/null; then
    pkill swaybg
fi

awww query || awww-daemon --format xrgb

awww img -o "$focused_monitor" "$wallpaper_path" $AWWW_PARAMS

echo "$wallpaper_path" > "$CACHE_DIR/wallpaper-path"
ln -sf "$wallpaper_path" "$CACHE_DIR/current-wallpaper"
