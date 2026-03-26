#Variables
HYPR_CONFIGS="$HOME/.config/hypr/.configs"
CURRENT_DATE=$(date +%Y-%m-%d_%H-%M-%S)

#gtk-2
GTK2_CONFIGS="$HOME/.config/gtk-2.0"
GTK2_CONFIGS_LOCAL="$HYPR_CONFIGS/gtk-2.0"

#gtk-3
GTK3_CONFIGS="$HOME/.config/gtk-3.0"
GTK3_CONFIGS_LOCAL="$HYPR_CONFIGS/gtk-3.0"

#gtk-4
GTK4_CONFIGS="$HOME/.config/gtk-4.0"
GTK4_CONFIGS_LOCAL="$HYPR_CONFIGS/gtk-4.0"

#kitty
create_kitty_link() {

  local KITTY_CONFIG="$HOME/.config/kitty"

  if ! mv "$KITTY_CONFIG" "$KITTY_CONFIG-$CURRENT_DATE"; then
    echo "Error: Could not move $KITTY_CONFIG" >&2
    exit 1
  fi

  if ! ln -s "$HYPR_CONFIGS/kitty" "$KITTY_CONFIG"; then
    echo "Error: Could not create symlink for $KITTY_CONFIG" >&2
    exit 1
  fi

  echo "Kitty symlinks created successfully"

}

#kvantum
KVANTUM_CONFIGS="$HOME/.config/Kvantum"
KVANTUM_CONFIGS_LOCAL="$HYPR_CONFIGS/Kvantum"

#rofi
create_rofi_link() {

  local ROFI_CONFIGS="$HOME/.config/rofi"

  if ! mv "$ROFI_CONFIGS" "$ROFI_CONFIGS-$CURRENT_DATE"; then
    echo "Error: Could not move $ROFI_CONFIGS" >&2
    exit 1
  fi

  if ! ln -s "$HYPR_CONFIGS/rofi" "$ROFI_CONFIGS"; then
    echo "Error: Could not create symlink for $ROFI_CONFIGS" >&2
    exit 1
  fi

  echo "Rofi symlinks created successfully"

}

#wallust
create_wallust_link() {

  local WALLUST_CONFIGS="$HOME/.config/wallust"

  mv "$WALLUST_CONFIGS" "$WALLUST_CONFIGS-$CURRENT_DATE"
  ln -s "$HYPR_CONFIGS/wallust" "$WALLUST_CONFIGS"

}

#waybar
create_waybar_link() {

  local WAYBAR_CONFIGS="$HOME/.config/waybar"

  if ! mv "$WAYBAR_CONFIGS" "$WAYBAR_CONFIGS-$CURRENT_DATE"; then
    echo "Error: Could not move $WAYBAR_CONFIGS" >&2
    exit 1
  fi

  if ! ln -s "$HYPR_CONFIGS/waybar" "$WAYBAR_CONFIGS"; then
    echo "Error: Could not create symlink for $WAYBAR_CONFIGS" >&2
    exit 1
  fi

  echo "Waybar symlinks created successfully"

}

#zsh
create_zsh_link() {

  local ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
  local ZSH_CONFIG="$HOME/.zshrc"

  if ! mv "$ZSH_CUSTOM" "$ZSH_CUSTOM-$CURRENT_DATE"; then
    echo "Error: Could not move $ZSH_CUSTOM" >&2
    exit 1
  fi

  if ! mv "$ZSH_CONFIG" "$ZSH_CONFIG-$CURRENT_DATE"; then
    echo "Error: Could not move $ZSH_CONFIG" >&2
    exit 1
  fi

  if ! ln -s "$HYPR_CONFIGS/zsh/custom" "$ZSH_CUSTOM"; then
    echo "Error: Could not create symlink for $ZSH_CUSTOM" >&2
    exit 1
  fi

  if ! ln -s "$HYPR_CONFIGS/zsh/.zshrc" "$ZSH_CONFIG"; then
    echo "Error: Could not create symlink for $ZSH_CONFIG" >&2
    exit 1
  fi

  echo "ZSH symlinks created successfully"

}

#keyd
create_keyd_link() {

  local KEYD_CONFIGS="/etc/keyd"
  local KEYD_CONFIGS_LOCAL="$HYPR_CONFIGS/keyd"

  if ! sudo mv "$KEYD_CONFIGS" "$KEYD_CONFIGS-$CURRENT_DATE"; then
    echo "Error: Could not move $KEYD_CONFIGS" >&2
    exit 1
  fi

  if ! sudo ln -s "$KEYD_CONFIGS_LOCAL" "$KEYD_CONFIGS"; then
    echo "Error: Could not create symlink for $KEYD_CONFIGS" >&2
    exit 1
  fi

  echo "Keyd symlinks created successfully"
}

#hyprshade
create_hyprshade_link() {

  local HYPRSHADE_CONFIGS="/usr/share/hyprshade"
  local HYPRSHADE_CONFIGS_LOCAL="$HYPR_CONFIGS/hyprshade"

  if ! sudo mv "$HYPRSHADE_CONFIGS" "$HYPRSHADE_CONFIGS-$CURRENT_DATE"; then
    echo "Error: Could not move $HYPRSHADE_CONFIGS" >&2
    exit 1
  fi

  if ! sudo ln -s "$HYPRSHADE_CONFIGS_LOCAL" "$HYPRSHADE_CONFIGS"; then
    echo "Error: Could not create symlink for $HYPRSHADE_CONFIGS" >&2
    exit 1
  fi

  echo "Hyprshade symlinks created successfully"
}

# TODO: Sincronizar carpetas sensibles y encriptarlas para que no sean accesibles en el repositorio.

main() {

  # TODO

  # ? Done Main
  # create_keyd_link

  # ? Done Notebook
  # create_hyprshade_link

  # * Done
  # create_zsh_link
  # create_kitty_link
  # create_wallust_link
  # create_rofi_link
  # create_waybar_link


}

main