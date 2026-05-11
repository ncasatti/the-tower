#!/usr/bin/env bash
# Generate color scheme from current wallpaper via wallust

CACHE_DIR="$HOME/.cache/hypr"
wallpaper_path=$(cat "$CACHE_DIR/wallpaper-path" 2>/dev/null)

if [[ -z "$wallpaper_path" ]] || [[ ! -f "$wallpaper_path" ]]; then
    echo "wallpaper-colors: no valid path in $CACHE_DIR/wallpaper-path" >&2
    exit 1
fi

wallust run "$wallpaper_path" -s
