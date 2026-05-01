# nix/packages/wayland.nix
# Wayland compositor tools, notification daemon, and browser
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    hyprpaper
    hyprlock
    hypridle
    pyprland
    waybar
    rofi
    wl-clipboard
    hyprshade
    awww
    swaynotificationcenter
    wallust
  ];
}
