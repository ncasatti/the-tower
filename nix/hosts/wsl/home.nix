# nix/hosts/wsl/home.nix
# Home Manager for the NixOS-WSL host, user: flyn.
# Slim subset of the desktop home: the Neovim/CLI/dev stack minus every
# Wayland/GTK/audio module.
#
# activation.nix is intentionally NOT imported — it declares the Hyprland hy3
# plugin (a dead GUI dependency here). dotfiles.nix IS imported whole: its
# Wayland symlinks (hypr/waybar/rofi/…) are inert on WSL, but it delivers the
# nvim/fish/yazi/starship configs.

{ pkgs, ... }:

{
  imports = [
    # --- Home modules ---
    ../../home/dotfiles.nix
    ../../home/git.nix
    ../../home/tmux.nix

    # --- Package sets ---
    ../../packages/cli.nix
    ../../packages/dev.nix
    ../../packages/ai.nix
    ../../packages/nvim.nix
    ../../packages/languages.nix
  ];

  home.username      = "flyn";
  home.homeDirectory = "/home/flyn";
  home.stateVersion  = "23.11";

  home.packages = with pkgs; [
    # Obsidian GUI — renders through WSLg. The zettelkasten vault syncs into
    # ~/.the-grid/zettelkasten on native ext4 (see nix/modules/syncthing.nix).
    obsidian
  ];
}
