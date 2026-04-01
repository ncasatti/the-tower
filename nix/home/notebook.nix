# nix/home/notebook.nix
# Home Manager configuration for NixOS notebook user: flyn
# Injected via home-manager.users.flyn in nix/hosts/notebook/default.nix

{ pkgs, ... }:

{
  imports = [ ./shared.nix ];

  home.username      = "flyn";
  home.homeDirectory = "/home/flyn";
  home.stateVersion  = "23.11";

  programs.home-manager.enable = true;

  # Extra packages specific to the notebook (GUI apps)
  home.packages = with pkgs; [
    cool-retro-term
    kitty
    brave
    obsidian

    # Screenshot & Multimedia dependencies
    grim
    slurp
    wl-clipboard
    jq
    libnotify
    swappy
    xdg-user-dirs
    sound-theme-freedesktop
  ];
}
