{ config, pkgs, ... }:

{
  home.username = "ncasatti";
  home.homeDirectory = "/home/ncasatti";
  home.stateVersion = "23.11"; 

  # 1. THE SOFTWARE: Assignment of new computing cycles
  home.packages = with pkgs; [
    # --- CLI & Core ---
    neovim tmux yazi starship ripgrep fd git fzf gcc unzip glow

    # --- Wayland UI ---
    hyprpaper hyprlock hypridle pyprland waybar rofi wl-clipboard

    # --- RECENTLY ASSIMILATED MODULES ---
    swaynotificationcenter
    wallust
    rclone
    lazygit
    kitty
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
    ".tmux.conf" = { source = ./tmux/tmux.conf; };
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
    ".config/Kvantum" = { source = ./hypr/.configs/Kvantum; recursive = true; };
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
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-cursor-theme-name = "default";
      gtk-cursor-theme-size = 24;
    };
  };

  # 3. WRITABLE CONFIGS: Copied (not symlinked) for apps that need write access
  home.activation.copyRcloneConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/rclone"
    # Read from a secure location outside the git repo
    if [ -f "$HOME/.the-grid/.private/rclone/rclone.conf" ]; then
      cp -f "$HOME/.the-grid/.private/rclone/rclone.conf" "$HOME/.config/rclone/rclone.conf"
      chmod 600 "$HOME/.config/rclone/rclone.conf"
    else
      echo "Warning: rclone.conf not found in ~/.the-grid/.private/rclone/"
    fi
  '';


  home.activation.refreshSystem = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD $HOME/.config/hypr/scripts/system/refresh.sh
  '';

  programs.home-manager.enable = true;
}
