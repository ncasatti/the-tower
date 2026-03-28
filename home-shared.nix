{ config, pkgs, inputs, ... }:
{
  # Allow unfree packages (Obsidian, etc.)
  nixpkgs.config.allowUnfree = true;

  # 1. THE SOFTWARE: Assignment of new computing cycles
  home.packages = with pkgs; [
    # --- CLI & Core ---
    neovim yazi starship ripgrep fd git fzf gcc unzip glow
    nettools zoxide brightnessctl tree-sitter

    # --- Language Toolchains (for Neovim LSPs via Mason) ---
    nodejs_22 python3 go lua-language-server luarocks lua5_1
    jq bat

    # --- Wayland UI ---
    hyprpaper hyprlock hypridle pyprland waybar rofi wl-clipboard hyprshade swww
    inputs.zen-browser.packages.x86_64-linux.default  # Zen Browser (community flake)

    # --- RECENTLY ASSIMILATED MODULES ---
    obsidian
    swaynotificationcenter
    wallust
    rclone
    lazygit
    fish

    # --- Fonts ---
    nerd-fonts.jetbrains-mono
    nerd-fonts._3270
    roboto
    inter

    # --- Themes ---
    sweet
    qogir-icon-theme
  ];

  # 2. THE STRUCTURE: Immutable links to ~/.config
  home.file = {
    # --- Core & UI ---
    ".config/nvim" = { source = ./nvim; recursive = true; };
    ".config/yazi" = { source = ./yazi; recursive = true; };
    ".config/starship.toml" = { source = ./starship/starship.toml; };
    ".config/hypr" = { source = ./hypr; recursive = true; };
    ".config/waybar" = { source = ./waybar; recursive = true; };
    ".config/rofi" = { source = ./rofi; recursive = true; };

    # --- NEW LINKS ---
    ".config/swaync" = { source = ./swaync; recursive = true; };
    ".config/wallust" = { source = ./wallust; recursive = true; };
    ".config/kitty" = { source = ./kitty; recursive = true; };
    ".config/fish" = { source = ./fish; recursive = true; };
    ".config/lazygit" = { source = ./lazygit; recursive = true; };

    # --- System Reference (keyd needs /etc/keyd on NixOS) ---
    ".config/keyd" = { source = ./keyd; recursive = true; };

    ".config/hyprshade" = { source = ./hyprshade; recursive = true; };
  };

  # 2.5. GTK THEMING: Declarative GTK configuration
  gtk = {
    enable = true;
    theme = {
      name = "Sweet-Ambar-Blue-Dark-v40";
      package = pkgs.sweet;
    };
    iconTheme = {
      name = "Qogir-dark";
      package = pkgs.qogir-icon-theme;
    };
    font = {
      name = "Roboto Light";
      size = 10;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-cursor-theme-name = "default";
      gtk-cursor-theme-size = 24;
      gtk-decoration-layout = "icon:minimize,maximize,close";
      gtk-enable-animations = true;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
    };
    gtk4.theme = config.gtk.theme;
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-cursor-theme-name = "default";
      gtk-cursor-theme-size = 24;
    };
  };

  # 2.7. GIT: Declarative git configuration
  programs.git = {
    enable = true;
    settings = {
      user.name = "Nicolas Casatti";
      user.email = "ncasatti@gmail.com";
      core.editor = "nvim";
      credential.helper = "store";
    };
    signing.format = null;
  };

  # 3. CACHE & SYMLINKS: Runtime mutable state
  home.activation.createCacheAndSymlinks = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.cache/hypr/wallust"
    ln -sfn "$HOME/.cache/hypr/wallust" "$HOME/.config/waybar/wallust"
    ln -sfn "$HOME/.cache/hypr/wallust" "$HOME/.config/rofi/wallust"
    ln -sfn "$HOME/.cache/hypr/current-wallpaper" "$HOME/.config/rofi/.current_wallpaper"
  '';

  # 4. POST-ACTIVATION: Refresh Hyprland after linking
  home.activation.refreshSystem = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD $HOME/.config/hypr/scripts/system/refresh.sh
  '';

  # --- HYPRLAND PLUGINS (Declarativo) ---
  home.file.".config/hypr-nix-plugins.conf".text = ''
    plugin = ${pkgs.hyprlandPlugins.hy3}/lib/libhy3.so
  '';

  programs.home-manager.enable = true;
}
