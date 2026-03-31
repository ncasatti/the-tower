# nix/packages/wayland.nix
# Wayland compositor tools, notification daemon, and browser

{ pkgs, inputs, ... }:

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
    swww
    swaynotificationcenter
    wallust
    # inputs.zen-browser.packages.x86_64-linux.default  # Zen Browser (community flake)
  ];
}
