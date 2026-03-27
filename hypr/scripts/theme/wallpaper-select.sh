#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# This script for selecting wallpapers (SUPER W) with folder navigation support

# WALLPAPERS PATH
wallDIR="$HOME/Pictures/wallpapers"
# wallDIR="$HOME/.config/konfig/themes/wallpapers"
# wallDIR="$HOME/Pictures/X"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

# Current directory for navigation
current_dir="$wallDIR"

# variables
focused_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')
# swww transition config
FPS=144
TYPE="any"
DURATION=0.8
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION"

# Check if swaybg is running
if pidof swaybg >/dev/null; then
  pkill swaybg
fi


# Rofi command
rofi_command="rofi -i -show -dmenu -config ~/.config/rofi/config-wallpaper.rasi"

# Function to get random image from folder
get_random_image_from_folder() {
  local folder="$1"
  local images=()
  
  # Get all images in the folder (including subdirectories)
  while IFS= read -r -d '' img; do
    images+=("$img")
  done < <(find "$folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -print0)
  
  # Return random image if any found
  if [[ ${#images[@]} -gt 0 ]]; then
    echo "${images[$((RANDOM % ${#images[@]}))]}"
  fi
}

# Function to show folder contents
show_folder_contents() {
  local dir="$1"
  local relative_path=""
  
  # Show relative path if not in root wallpaper directory
  if [[ "$dir" != "$wallDIR" ]]; then
    relative_path="📁 $(basename "$dir")"
    printf "%s\n" "🔙 .. (back)"
  fi
  
  # Show subdirectories with random image icons
  while IFS= read -r -d '' folder; do
    folder_name=$(basename "$folder")
    random_img=$(get_random_image_from_folder "$folder")
    
    if [[ -n "$random_img" ]]; then
      printf "%s\x00icon\x1f%s\n" "📁 $folder_name" "$random_img"
    else
      printf "%s\n" "📁 $folder_name"
    fi
  done < <(find "$dir" -maxdepth 1 -type d ! -path "$dir" -print0 | sort -z)
  
  # Show image files in current directory
  while IFS= read -r -d '' pic_path; do
    pic_name=$(basename "$pic_path")
    
    # Displaying .gif to indicate animated images
    if [[ ! "$pic_name" =~ \.gif$ ]]; then
      printf "%s\x00icon\x1f%s\n" "🖼️ $(echo "$pic_name" | cut -d. -f1)" "$pic_path"
    else
      printf "%s\n" "🎬 $pic_name"
    fi
  done < <(find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -print0 | sort -z)
}

# Main menu function
menu() {
  # Show current folder contents
  show_folder_contents "$current_dir"
}

# initiate swww if not running
swww query || swww-daemon --format xrgb

# Function to handle wallpaper selection
set_wallpaper() {
  local wallpaper_path="$1"
  swww img -o "$focused_monitor" "$wallpaper_path" $SWWW_PARAMS
  notify-send "Wallpaper changed"
  notify-send "Getting wallpaper colors"
  "$SCRIPTSDIR/theme/wallpaper-colors.sh"
  "$SCRIPTSDIR/system/refresh.sh"
  notify-send "Done..."
}

# Main navigation function
navigate() {
  while true; do
    choice=$(menu | $rofi_command)
    
    # Trim any potential whitespace or hidden characters
    choice=$(echo "$choice" | xargs)
    
    # No choice case
    if [[ -z "$choice" ]]; then
      exit 0
    fi
    
    # Back navigation
    if [[ "$choice" == "🔙 .. (back)" ]]; then
      current_dir=$(dirname "$current_dir")
      # Don't go above wallpaper directory
      if [[ "$current_dir" < "$wallDIR" ]]; then
        current_dir="$wallDIR"
      fi
      continue
    fi
    
    # Remove emoji prefixes for processing
    clean_choice="$choice"
    if [[ "$choice" == 📁* ]]; then
      clean_choice="${choice#📁 }"
    elif [[ "$choice" == 🖼️* ]]; then
      clean_choice="${choice#🖼️ }"
    elif [[ "$choice" == 🎬* ]]; then
      clean_choice="${choice#🎬 }"
    fi
    
    # Check if it's a folder
    if [[ "$choice" == 📁* ]]; then
      potential_dir="$current_dir/$clean_choice"
      if [[ -d "$potential_dir" ]]; then
        current_dir="$potential_dir"
        continue
      fi
    fi
    
    # Check if it's an image file
    if [[ "$choice" == 🖼️* ]] || [[ "$choice" == 🎬* ]]; then
      # Find the full path of the selected image
      mapfile -d '' current_pics < <(find "$current_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -print0)
      
      for pic_path in "${current_pics[@]}"; do
        pic_name=$(basename "$pic_path")
        pic_name_no_ext=$(echo "$pic_name" | cut -d. -f1)
        # Debug output
        echo "DEBUG: clean_choice='$clean_choice'" >&2
        echo "DEBUG: pic_name='$pic_name'" >&2
        echo "DEBUG: pic_name_no_ext='$pic_name_no_ext'" >&2
        
        if [[ "$clean_choice" == "$pic_name_no_ext" ]] || [[ "$clean_choice" == "$pic_name" ]]; then
          echo "DEBUG: Match found! Setting wallpaper: $pic_path" >&2
          set_wallpaper "$pic_path"
          exit 0
        fi
      done
      echo "DEBUG: No match found for '$clean_choice'" >&2
    fi
  done
}

# Main function
main() {
  navigate
}

# Check if rofi is already running
if pidof rofi >/dev/null; then
  pkill rofi
  sleep 1 # Allow some time for rofi to close
fi

main

