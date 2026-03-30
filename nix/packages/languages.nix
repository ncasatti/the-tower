# nix/packages/languages.nix
# Language toolchains for Neovim LSPs via Mason and general development

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nodejs_22
    python3
    go
    lua-language-server
    luarocks
    lua5_1
  ];
}
