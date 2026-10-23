# nix/modules/gaming.nix
# Windows gaming via Proton. Desktop hosts only (main, notebook).
#
# - Steam: Steam games + non-Steam shortcuts (e.g. Battle.net installer).
#   GE-Proton is offered as a compatibility tool from nixpkgs; it updates
#   with `nix flake update`. Enabling Steam also sets
#   hardware.graphics.enable32Bit (required by Battle.net / DXVK).
# - Faugus Launcher: umu-launcher frontend for non-Steam stores
#   (Battle.net, EA, Ubisoft) and loose .exe installers. Prefixes live in
#   ~/Faugus/<name>; it downloads its own Proton builds into $HOME.
# - gamemode: CPU governor / scheduling boost while a game runs.

{ pkgs, ... }:

{
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    faugus-launcher
  ];
}
