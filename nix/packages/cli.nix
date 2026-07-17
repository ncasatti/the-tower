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
    posting
    translate-shell
    btop
    ncdu
    pdf2md
    herdr   # tmux-like, agent-aware terminal workspace manager (builds from source)

    # bionic-kindle pipeline (books/clingy — see docs/feats/bionic-kindle)
    python3Packages.lxml      # EPUB DOM transforms (bold injection)
    python3Packages.ebooklib  # EPUB metadata extraction (Dublin Core in OPF)
    python3Packages.mobi      # MOBI metadata extraction (EXTH header)
    python3Packages.pytest    # test runner for books/tests/
    calibre                   # ebook-convert CLI for EPUB -> AZW3
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
