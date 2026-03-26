#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for Random Wallpaper ( CTRL ALT W)

echo Select random wallpaper script

wallpaper_dir="$HOME/Pictures/wallpapers"
scripts_dir="$HOME/.config/hypr/scripts"
focused_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')

echo $focused_monitor

PICS=($(find ${wallpaper_dir} -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \)))
RANDOMPIC=${PICS[ $RANDOM % ${#PICS[@]} ]}

echo $RANDOMPIC

# Transition config
FPS=144
TYPE="random"
DURATION=0.8
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

swww img -o $focused_monitor $RANDOMPIC $SWWW_PARAMS

# swww query || swww-daemon --format xrgb && swww img -o $focused_monitor ${RANDOMPIC} $SWWW_PARAMS

wallust run $RANDOMPIC -s &

${scripts_dir}/theme/wallpaper-colors.sh
${scripts_dir}/settings/refresh-no-waybar.sh

