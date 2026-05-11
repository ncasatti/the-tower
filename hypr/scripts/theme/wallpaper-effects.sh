#!/usr/bin/env bash
# Wallpaper Effects using ImageMagick

CACHE_DIR="$HOME/.cache/hypr"
current_wallpaper=$(cat "$CACHE_DIR/wallpaper-path" 2>/dev/null)
wallpaper_output="$CACHE_DIR/modified-wallpaper"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
focused_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')

iDIR="$HOME/.config/swaync/images"

FPS=60
TYPE="wipe"
DURATION=2
AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION"

if [[ -z "$current_wallpaper" ]] || [[ ! -f "$current_wallpaper" ]]; then
    notify-send -u critical "wallpaper-effects" "No wallpaper set. Run wallpaper-select first."
    exit 1
fi

declare -A effects=(
    ["No Effects"]="no-effects"
    ["Black & White"]="magick $current_wallpaper -colorspace gray -sigmoidal-contrast 10,40% $wallpaper_output"
    ["Blurred"]="magick $current_wallpaper -blur 0x10 $wallpaper_output"
    ["Charcoal"]="magick $current_wallpaper -charcoal 0x5 $wallpaper_output"
    ["Edge Detect"]="magick $current_wallpaper -edge 1 $wallpaper_output"
    ["Emboss"]="magick $current_wallpaper -emboss 0x5 $wallpaper_output"
    ["Negate"]="magick $current_wallpaper -negate $wallpaper_output"
    ["Oil Paint"]="magick $current_wallpaper -paint 4 $wallpaper_output"
    ["Posterize"]="magick $current_wallpaper -posterize 4 $wallpaper_output"
    ["Polaroid"]="magick $current_wallpaper -polaroid 0 $wallpaper_output"
    ["Sepia Tone"]="magick $current_wallpaper -sepia-tone 65% $wallpaper_output"
    ["Solarize"]="magick $current_wallpaper -solarize 80% $wallpaper_output"
    ["Sharpen"]="magick $current_wallpaper -sharpen 0x5 $wallpaper_output"
    ["Vignette"]="magick $current_wallpaper -vignette 0x5 $wallpaper_output"
    ["Zoomed"]="magick $current_wallpaper -gravity Center -extent 1:1 $wallpaper_output"
)

no-effects() {
    awww query || awww-daemon --format xrgb
    awww img -o "$focused_monitor" "$current_wallpaper" $AWWW_PARAMS &
    wait $!
    wallust run "$current_wallpaper" -s &
    wait $!
    ln -sf "$current_wallpaper" "$CACHE_DIR/current-wallpaper"
    "${SCRIPTSDIR}/system/refresh.sh"
    notify-send -u low -i "$iDIR/bell.png" "No wallpaper effects"
}

main() {
    options=("No Effects")
    for effect in "${!effects[@]}"; do
        [[ "$effect" != "No Effects" ]] && options+=("$effect")
    done

    choice=$(printf "%s\n" "${options[@]}" | LC_COLLATE=C sort | rofi -dmenu -p "Choose effect" -i -config ~/.config/rofi/config-wallpaper-effect.rasi)

    if [[ -n "$choice" ]]; then
        if [[ "$choice" == "No Effects" ]]; then
            no-effects
        elif [[ "${effects[$choice]+exists}" ]]; then
            notify-send -u normal -i "$iDIR/bell.png" "Applying $choice effects"
            eval "${effects[$choice]}"
            sleep 1
            awww query || awww-daemon --format xrgb
            awww img -o "$focused_monitor" "$wallpaper_output" $AWWW_PARAMS &
            wait $!
            wallust run "$wallpaper_output" -s &
            wait $!
            ln -sf "$wallpaper_output" "$CACHE_DIR/current-wallpaper"
            "${SCRIPTSDIR}/system/refresh.sh"
            notify-send -u low -i "$iDIR/bell.png" "$choice effects applied"
        else
            echo "Effect '$choice' not recognized."
        fi
    fi
}

if pidof rofi >/dev/null; then
    pkill rofi
    exit 0
fi

main
