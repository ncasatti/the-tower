#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for changing blurs on the fly

notif="$HOME/.config/swaync/images/bell.png"
scripts="$HOME/.config/hypr/new-scripts"

STATE=$(hyprctl -j getoption decoration:blur:size | jq ".int")

if [ "${STATE}" == "0" ]; then
	hyprctl keyword decoration:blur:size 2
	hyprctl keyword decoration:blur:passes 1
  notify-send -e -u low -i "$notif" "Blur: 1"
elif [ "${STATE}" == "2" ]; then
	hyprctl keyword decoration:blur:size 4
	hyprctl keyword decoration:blur:passes 2
  notify-send -e -u low -i "$notif" "Blur: 2"
elif [ "${STATE}" == "4" ]; then
	hyprctl keyword decoration:blur:size 6
	hyprctl keyword decoration:blur:passes 2
	notify-send -e -u low -i "$notif" "Blur: 3"
elif [ "${STATE}" == "6" ]; then
	hyprctl keyword decoration:blur:size 8
	hyprctl keyword decoration:blur:passes 2
	notify-send -e -u low -i "$notif" "Blur: 4"
elif [ "${STATE}" == "8" ]; then
	hyprctl keyword decoration:blur:size 10
	hyprctl keyword decoration:blur:passes 2
	notify-send -e -u low -i "$notif" "Blur: 5"
elif [ "${STATE}" == "10" ]; then
	hyprctl keyword decoration:blur:size 0
	hyprctl keyword decoration:blur:passes 2
	notify-send -e -u low -i "$notif" "Blur: 0"
fi
