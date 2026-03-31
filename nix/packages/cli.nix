# nix/packages/cli.nix
# CLI tools and core utilities

{ pkgs, inputs, ... }:

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
    gnumake
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
    inputs.opencode-nix.packages.${pkgs.system}.default
  ];
}
