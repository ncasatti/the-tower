# nix/packages/cli.nix
# CLI tools and core utilities
{
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
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
    bind
    tcpdump
    posting
    claude-code
    inputs.opencode-nix.packages.${system}.default
    inputs.clingy.packages.${system}.default
    gemini-cli
  ];
}
