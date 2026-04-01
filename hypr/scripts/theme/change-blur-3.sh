#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for changing blurs on the fly

notif="$HOME/.config/swaync/images/bell.png"
scripts="$HOME/.config/hypr/new-scripts"

STATE=$(hyprctl -j getoption decoration:blur:passes | jq ".int")

if [ "${STATE}" == "0" ]; then
	hyprctl keyword decoration:blur:size 2
	hyprctl keyword decoration:blur:passes 1
  notify-send -e -u low -i "$notif" "Blur: 1"
elif [ "${STATE}" == "1" ]; then
	hyprctl keyword decoration:blur:size 2
	hyprctl keyword decoration:blur:passes 2
  notify-send -e -u low -i "$notif" "Blur: 2"
elif [ "${STATE}" == "2" ]; then
	hyprctl keyword decoration:blur:size 2
	hyprctl keyword decoration:blur:passes 3
	notify-send -e -u low -i "$notif" "Blur: 3"
elif [ "${STATE}" == "3" ]; then
	hyprctl keyword decoration:blur:size 2
	hyprctl keyword decoration:blur:passes 4
	notify-send -e -u low -i "$notif" "Blur: 4"
elif [ "${STATE}" == "4" ]; then
	hyprctl keyword decoration:blur:size 2
	hyprctl keyword decoration:blur:passes 5
	notify-send -e -u low -i "$notif" "Blur: 5"
elif [ "${STATE}" == "5" ]; then
	hyprctl keyword decoration:blur:size 2
	hyprctl keyword decoration:blur:passes 6
	notify-send -e -u low -i "$notif" "Blur: 6"
elif [ "${STATE}" == "6" ]; then
	hyprctl keyword decoration:blur:size 2
	hyprctl keyword decoration:blur:passes 0
	notify-send -e -u low -i "$notif" "Blur: 0"
fi
