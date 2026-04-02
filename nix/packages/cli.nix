# nix/packages/cli.nix
# CLI tools and core utilities

{ pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
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
    tldr
    lazygit
    fish
    rclone
    inputs.opencode-nix.packages.${pkgs.system}.default
    inputs.clingy.packages.${pkgs.system}.default
  ];
}
