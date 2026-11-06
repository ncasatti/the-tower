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
    gh
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
    lazydocker
    fish
    rclone
    # Official Ookla client. Replaces the Python speedtest-cli, whose server
    # list had no Argentine servers (it picked Brazil, ~2265 km) and which
    # under-reports on fast links. Unfree (allowUnfree is global).
    ookla-speedtest
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
