{ config, pkgs, inputs, ... }:

{
  imports = [
    ./tmux/tmux.nix
  ];

  home.username = "flyn";
  home.homeDirectory ="/home/flyn";
  home.stateVersion = "23.11"; 

  # 1. THE SOFTWARE: Assignment of new computing cycles
  home.packages = with pkgs; [
    # --- CLI & Core ---
    neovim yazi starship ripgrep fd git fzf gcc unzip glow
    nettools zoxide

    # --- Wayland UI ---
    hyprpaper hyprlock hypridle pyprland waybar rofi wl-clipboard hyprshade swww
    cool-retro-term
    inputs.zen-browser.packages.x86_64-linux.default  # Zen Browser (community flake)

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
  };

  # 3. WRITABLE CONFIGS
  # NOTE: Secrets (SSH keys, AWS credentials, rclone) are managed by agenix
  # in configuration.nix. They are decrypted at activation to /run/agenix/
  # and symlinked to their expected paths.


  home.activation.refreshSystem = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD $HOME/.config/hypr/scripts/system/refresh.sh
  '';

  programs.home-manager.enable = true;
}
