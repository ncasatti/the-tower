# nix/packages/languages.nix
# Language toolchains for Neovim LSPs via Mason and general development

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nodejs_22
    (python3.withPackages (ps: with ps; [ pip mdformat mdformat-front-matters mdformat-wikilink ]))
    go
    cargo
    rustc
    lua-language-server
    luarocks
    lua5_1
    mermaid-cli
    icu
    marksman
  ];
}
