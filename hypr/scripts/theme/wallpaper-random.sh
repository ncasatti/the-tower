#!/usr/bin/env bash
# Random wallpaper from wallpaper directory

wallpaper_dir="$HOME/Pictures/wallpapers"
scripts_dir="$HOME/.config/hypr/scripts"

PICS=($(find "${wallpaper_dir}" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \)))
RANDOMPIC="${PICS[$RANDOM % ${#PICS[@]}]}"

"${scripts_dir}/theme/wallpaper-set.sh" "$RANDOMPIC"
"${scripts_dir}/theme/wallpaper-colors.sh"
"${scripts_dir}/system/refresh.sh"
