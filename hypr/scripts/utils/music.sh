#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For Rofi Beats to play online Music or Locally save media files

# Directory local music folder
mDIR="$HOME/Music/"

# Directory for icons
iDIR="$HOME/.config/swaync/icons"

# Online Stations. Edit as required
declare -A online_music=(
  ["Radio 📻 | Easy Rock 96.3"]="https://radio-stations-philippines.com/easy-rock"
  ["Radio 📻 | Shopping Classics 96.1"]="https://stream4.suenas.net/shoppingclassics"
  ["Radio 📻 | Aspen 93.7"]="https://sslstream.online:7001/stream"
  ["Radio 📻 | Rock And Pop 95.9"]="https://playerservices.streamtheworld.com/api/livestream-redirect/ROCKANDPOPAAC_SC"
  ["Youtube Playlist 🎶 | RetroWave"]="https://youtube.com/playlist?list=PLL3BWakT7rqX86diD3PgBkY1cBncKFfnT&si=scxgSiiUk-DJsvRa"
  ["Youtube Playlist 🎶 | Remixes Playlist"]="https://youtube.com/playlist?list=PLeqTkIUlrZXlSNn3tcXAa-zbo95j0iN-0"
  ["Youtube Playlist 🎶 | Lo-Fi Rock"]="https://youtube.com/playlist?list=PLL3BWakT7rqX3at7Sot-9ZynNqK9LBThu&si=hRm9XKdjl3BwsjuY"
  ["Youtube Playlist 🎶 | StarWars Epic Music"]="https://youtube.com/playlist?list=PL9PLUrw0CbcTK97xwPGVLs8EcZUIap54v&si=X87C_h0dCubTYLeG"
  ["Youtube Playlist 🎶 | Gaming Music"]="https://youtube.com/playlist?list=PLL3BWakT7rqXF3T_LYfLBn0tyQcpeARzb&si=f_I7QftTzS8EL7KG"
  ["Youtube Playlist 🎶 | Back To The 80s - Thanatos Mixes"]="https://youtube.com/playlist?list=PL_MHjKxnHz1vGIan1NvtfR1NLMk3qkG8j&si=_Pif0WAu6oGP3Tn-"
  ["Youtube Playlist 🎶 | Symphonic Metal"]="https://youtube.com/playlist?list=PLL3BWakT7rqVs8s3ojHtxSzV_ZNFnBgIA&si=hy-4w4yk2S9-ZaO_"
  ["Youtube Radio 🎧 | RetroWave Radio - ThePrimeThanatos"]="https://youtu.be/h-aqn3Lpur8"
  ["Youtube Radio 🎧 | Synthwave and Chillwave Radio"]="https://youtu.be/W-1azuktk9U"
  ["Youtube Radio 🎧 | Synthwave Radio - Lofi Girl"]="https://youtu.be/4xDzrJKXOOY"
  ["Youtube Radio 🎧 | RetroTape - RetroRoom"]="https://youtu.be/C6cIkhd3IuE"
)

# Populate local_music array with files from music directory and subdirectories
populate_local_music() {
  local_music=()
  filenames=()
  while IFS= read -r file; do
    local_music+=("$file")
    filenames+=("$(basename "$file")")
  done < <(find "$mDIR" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.mp4" \))
}

# Function for displaying notifications
notification() {
  notify-send -u normal -i "$iDIR/music.png" "Playing: $@"
}

# Main function for playing local music
play_local_music() {
  populate_local_music

  # Prompt the user to select a song
  choice=$(printf "%s\n" "${filenames[@]}" | sort | rofi -i -dmenu -config ~/.config/rofi/config-rofi-Beats.rasi -p "Local Music")

  if [ -z "$choice" ]; then
    exit 1
  fi

  # Find the corresponding file path based on user's choice and set that to play the song then continue on the list
  for ((i = 0; i < "${#filenames[@]}"; ++i)); do
    if [ "${filenames[$i]}" = "$choice" ]; then

      notification "$choice"

      # Play the selected local music file using mpv
      mpv --playlist-start="$i" --loop-playlist --vid=no "${local_music[@]}"

      break
    fi
  done
}

# Main function for shuffling local music
shuffle_local_music() {
  notification "Shuffle local music"

  # Play music in $mDIR on shuffle
  mpv --shuffle --loop-playlist --vid=no "$mDIR"
}

# Main function for playing online music
play_online_music() {
  choice=$(printf "%s\n" "${!online_music[@]}" | sort | rofi -i -dmenu -config ~/.config/rofi/config-rofi-Beats.rasi -p "Online Music")

  if [ -z "$choice" ]; then
    exit 1
  fi

  link="${online_music[$choice]}"

  notification "$choice"

  # Play the selected online music using mpv with audio-only format
  mpv --shuffle --vid=no --ytdl-format="bestaudio/best" --script-opts=ytdl_hook-ytdl_path=yt-dlp "$link"
}

# Check if an online music process is running and send a notification, otherwise run the main function
pkill mpv && notify-send -u low -i "$iDIR/music.png" "Music stopped" || {

  # Prompt the user to choose between local and online music
  user_choice=$(printf "Play from Online Stations\nPlay from Music Folder\nShuffle Play from Music Folder" | rofi -dmenu -config ~/.config/rofi/config-rofi-Beats-menu.rasi -p "Select music source")

  case "$user_choice" in
  "Play from Music Folder")
    play_local_music
    ;;
  "Play from Online Stations")
    play_online_music
    ;;
  "Shuffle Play from Music Folder")
    shuffle_local_music
    ;;
  *)
    echo "Invalid choice"
    ;;
  esac
}
