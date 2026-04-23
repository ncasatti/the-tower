# nix/hosts/notebook/home.nix
# Home Manager configuration for NixOS notebook host, user: flyn
# Injected via home-manager.users.flyn in the flake.

{ pkgs, ... }:

{
  imports = [
    # --- Home modules ---
    ../../home/dotfiles.nix
    ../../home/git.nix
    ../../home/gtk.nix
    ../../home/tmux.nix
    ../../home/activation.nix
    ../../home/xdg.nix
    ../../home/sioyek.nix
    # ../../home/secrets.nix  # agenix — disabled for now

    # --- Package sets ---
    ../../packages/cli.nix
    ../../packages/dev.nix
    ../../packages/nvim.nix
    ../../packages/languages.nix
    ../../packages/wayland.nix
    ../../packages/appearance.nix
    ../../packages/utilities.nix
    ../../packages/audio.nix
  ];

  home.username      = "flyn";
  home.homeDirectory = "/home/flyn";
  home.stateVersion  = "23.11";

  # Extra packages specific to the notebook
  home.packages = with pkgs; [
    cool-retro-term
    kitty
    obsidian

    # Screenshot & Multimedia dependencies
    grim
    slurp
    libnotify
    swappy
    xdg-user-dirs
    sound-theme-freedesktop
  ];
}
