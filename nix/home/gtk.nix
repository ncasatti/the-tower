# nix/home/gtk.nix
# Declarative GTK theming

{ config, pkgs, ... }:

let
  cursor-theme = pkgs.callPackage ../packages/cursor-theme.nix {};
in

{
  home.pointerCursor = {
    name = "DeppinDark-cursors";
    package = cursor-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      name    = "Sweet-Ambar-Blue-Dark-v40";
      package = pkgs.sweet;
    };
    iconTheme = {
      name    = "Qogir-dark";
      package = pkgs.qogir-icon-theme;
    };
    font = {
      name = "Roboto Light";
      size = 10;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-cursor-theme-name             = "DeppinDark-cursors";
      gtk-cursor-theme-size             = 24;
      gtk-decoration-layout             = "icon:minimize,maximize,close";
      gtk-enable-animations             = true;
      gtk-xft-antialias                 = 1;
      gtk-xft-hinting                   = 1;
      gtk-xft-hintstyle                 = "hintslight";
      gtk-xft-rgba                      = "rgb";
    };
    gtk4.theme       = config.gtk.theme;
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-cursor-theme-name             = "DeppinDark-cursors";
      gtk-cursor-theme-size             = 24;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
