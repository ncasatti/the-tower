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
    zip
    unzip
    glow
    nettools
    zoxide
    brightnessctl
    cliphist
    playerctl
    bat
    jq
    tldr
    lazygit
    fish
    rclone
    speedtest-cli
    bind
    tcpdump
    translate-shell
    btop
    ncdu
    pdf2md
    herdr   # tmux-like, agent-aware terminal workspace manager (builds from source)
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
