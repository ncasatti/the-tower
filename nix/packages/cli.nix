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
    freerdp     # FreeRDP3 (xfreerdp) — RDP client for the HTPC (see rdp-htpc.sh)
    posting
    translate-shell
    btop
    ncdu
    pdf2md
    # (pkgs.callPackage ./gentle-ai.nix {})
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
