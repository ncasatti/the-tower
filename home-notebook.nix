{ config, pkgs, inputs, ... }:

{
  imports = [
    ./tmux/tmux.nix
    ./home-shared.nix
  ];

  home.username = "flyn";
  home.homeDirectory ="/home/flyn";
  home.stateVersion = "23.11"; 
  home.packages = with pkgs; [
    cool-retro-term
    kitty
    brave
  ];
}
