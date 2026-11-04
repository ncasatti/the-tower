# nix/home/dotfiles.nix
# Immutable symlinks from ~/.config to dotfile directories at repo root

{ config, ... }:

{
  # nvim's vim.loader bytecode cache (~/.cache/nvim/luac) validates entries by
  # size + mtime. Store files all have mtime 1, so an edit that keeps a file's
  # byte size (e.g. swapping equal-length color strings) kept running the stale
  # bytecode. Drop the cache whenever the config generation is relinked.
  home.activation.clearNvimLuaCache = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD rm -rf "$HOME/.cache/nvim/luac"
  '';

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
    ".config/herdr"               = { source = ../../herdr;            recursive = true; };
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

    # Per-host Hyprland override include (sourced last by hypr/hyprland.conf).
    # Empty default; hosts override with lib.mkForce (see hosts/server/home.nix).
    ".config/hypr-host.conf".text = "# host-specific Hyprland overrides (none)\n";

    # --- Vesktop custom CSS (Brutalist Command theme) ---
    ".config/vesktop/custom.css" = { source = ../../vesktop/custom.css; };
  };
}
