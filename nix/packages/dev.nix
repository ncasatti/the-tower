# nix/packages/dev.nix
# Development tools and utilities
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    claude-code
    opencode
    clingy
    engram
    gemini-cli
    postman
    postgresql
    dbeaver-bin
    antigravity-nix
  ];
}
