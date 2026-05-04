# nix/packages/cli.nix
# CLI tools and core utilities
{ pkgs, ... }:

{
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
    translate-shell
    btop
    ncdu
    # (pkgs.callPackage ./gentle-ai.nix {})
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
