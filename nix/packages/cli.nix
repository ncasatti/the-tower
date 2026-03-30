# nix/packages/cli.nix
# CLI tools and core utilities

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim
    yazi
    starship
    ripgrep
    fd
    git
    fzf
    gcc
    unzip
    glow
    nettools
    zoxide
    brightnessctl
    bat
    jq
    lazygit
    fish
    rclone
    tree-sitter
  ];
}
