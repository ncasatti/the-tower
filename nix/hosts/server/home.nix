# Home Manager configuration for NixOS notebook host, user: flyn
# Injected via home-manager.users.flyn in the flake.

{ pkgs, ... }:

{
  imports = [
    # --- Home modules ---
    ../../home/dotfiles.nix
    ../../home/git.nix
    ../../home/tmux.nix

    # --- Package sets ---
    ../../packages/nvim.nix
  ];

  home.username      = "flyn";
  home.homeDirectory = "/home/flyn";
  home.stateVersion  = "23.11";

  # Extra packages specific to the notebook
  home.packages = with pkgs; [
    xdg-user-dirs
    fzf
    yazi
    starship
    zoxide
    bat
    lazygit
    fish
    rclone
    clingy
  ];
}
