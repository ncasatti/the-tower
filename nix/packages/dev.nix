# nix/packages/dev.nix
# Development tools and utilities
{
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  gemini-cli = pkgs.callPackage ./custom/gemini-cli.nix {};
in {
  home.packages = with pkgs; [
    claude-code
    inputs.opencode-nix.packages.${system}.default
    inputs.clingy.packages.${system}.default
    gemini-cli
    postman
  ];
}
