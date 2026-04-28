# nix/packages/dev.nix
# Development tools and utilities
{ pkgs, ... }:

let
  gemini-cli = pkgs.callPackage ./custom/gemini-cli.nix { };
  # antigravity = pkgs.callPackage ./custom/antigravity.nix { };
in

{
  home.packages = with pkgs; [
    claude-code
    opencode
    clingy
    gemini-cli
    postman
    postgresql
    dbeaver-bin
    antigravity-nix
  ];
}
