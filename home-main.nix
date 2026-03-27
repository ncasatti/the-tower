{ config, pkgs, inputs, ... }:

{
  imports = [
    ./tmux/tmux.nix
    ./home-shared.nix
  ];

  home.username = "ncasatti";
  home.homeDirectory ="/home/ncasatti";
  home.stateVersion = "23.11"; 
}
