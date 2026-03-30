# nix/packages/appearance.nix
# Fonts and GTK/icon themes

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # --- Fonts ---
    nerd-fonts.jetbrains-mono
    roboto
    inter

    # --- Themes ---
    sweet
    qogir-icon-theme
  ];
}
