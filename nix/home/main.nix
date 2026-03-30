# nix/home/main.nix
# Home Manager configuration for Arch Linux user: ncasatti
# Deployment: nix run home-manager/master -- switch --flake .#main

{ ... }:

{
  imports = [ ./shared.nix ];

  home.username      = "ncasatti";
  home.homeDirectory = "/home/ncasatti";
  home.stateVersion  = "23.11";

  programs.home-manager.enable = true;
}
