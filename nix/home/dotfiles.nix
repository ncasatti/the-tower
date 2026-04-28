# nix/home/dotfiles.nix
# Immutable symlinks from ~/.config to dotfile directories at repo root

{ ... }:

{
  home.file = {
    # --- Core & UI ---
    ".config/nvim"                = { source = ../../nvim;              recursive = true; };
    ".config/yazi"                = { source = ../../yazi;             recursive = true; };
    ".config/starship.toml"       = { source = ../../starship/starship.toml; };
    ".config/hypr"                = { source = ../../hypr;             recursive = true; };
    ".config/waybar"              = { source = ../../waybar;           recursive = true; };
    ".config/rofi"                = { source = ../../rofi;             recursive = true; };

    # --- Notification & Wallpaper ---
    ".config/swaync"              = { source = ../../swaync;           recursive = true; };
    ".config/wallust"             = { source = ../../wallust;          recursive = true; };

    # --- Terminal & Shell ---
    ".config/kitty"               = { source = ../../kitty;            recursive = true; };
    ".config/wezterm"             = { source = ../../wezterm;          recursive = true; };
    ".config/fish"                = { source = ../../fish;             recursive = true; };
    ".config/lazygit"             = { source = ../../lazygit;          recursive = true; };
    ".config/posting"             = { source = ../../posting;          recursive = true; };
    ".local/share/posting/themes" = { source = ../../posting/themes;   recursive = true; };


    # --- System Reference (keyd config for reference) ---
    ".config/keyd"                = { source = ../../keyd;             recursive = true; };

    # --- Package Managers ---
    ".bunfig.toml".text = ''
      [install]
      ignoreScripts = true
    '';
    ".npmrc".text = ''
      ignore-scripts=true
    '';

    # --- Misc ---
    ".config/hyprshade"           = { source = ../../hyprshade;        recursive = true; };
    ".local/share/fonts"          = { source = ../../fonts;            recursive = true; };
  };
}
