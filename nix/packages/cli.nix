# nix/packages/cli.nix
# CLI tools and core utilities
{
  pkgs,
  inputs,
  ...
}: let
  gemini-cli = pkgs.callPackage ./custom/gemini-cli.nix {};
in {
  home.packages = with pkgs; [
    yazi
    starship
    qimgv
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
    speedtest-cli
    posting
    inputs.opencode-nix.packages.${pkgs.system}.default
    inputs.clingy.packages.${pkgs.system}.default
    gemini-cli
  ];
}
