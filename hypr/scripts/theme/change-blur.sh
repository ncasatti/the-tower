#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for changing blurs on the fly

notif="$HOME/.config/swaync/images/bell.png"
scripts="$HOME/.config/hypr/new-scripts"

PASSES=$(hyprctl -j getoption decoration:blur:passes | jq ".int")

if [ "${PASSES}" == "0" ]; then
	hyprctl keyword decoration:blur:size 1
	hyprctl keyword decoration:blur:passes 2
  notify-send -e -u low -i "$notif" "Passes: 2"
elif [ "${PASSES}" == "2" ]; then
	hyprctl keyword decoration:blur:size 1
	hyprctl keyword decoration:blur:passes 3
	notify-send -e -u low -i "$notif" "Passes: 3"
elif [ "${PASSES}" == "3" ]; then
	hyprctl keyword decoration:blur:size 1
	hyprctl keyword decoration:blur:passes 4
	notify-send -e -u low -i "$notif" "Passes: 4"
elif [ "${PASSES}" == "4" ]; then
	hyprctl keyword decoration:blur:size 1
	hyprctl keyword decoration:blur:passes 5
	notify-send -e -u low -i "$notif" "Passes: 5"
elif [ "${PASSES}" == "5" ]; then
	hyprctl keyword decoration:blur:size 1
	hyprctl keyword decoration:blur:passes 6
	notify-send -e -u low -i "$notif" "Passes: 6"
elif [ "${PASSES}" == "6" ]; then
	hyprctl keyword decoration:blur:size 1
	hyprctl keyword decoration:blur:passes 0
	notify-send -e -u low -i "$notif" "Passes: 0"
fi
