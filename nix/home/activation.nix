# nix/home/activation.nix
# Activation scripts and Hyprland plugin declarations

{ config, pkgs, ... }:

{
  # --- CACHE & SYMLINKS: Runtime mutable state ---
  home.activation.createCacheAndSymlinks = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.cache/hypr/wallust"
    ln -sfn "$HOME/.cache/hypr/wallust"           "$HOME/.config/waybar/wallust"
    ln -sfn "$HOME/.cache/hypr/wallust"           "$HOME/.config/rofi/wallust"
  '';

  # --- HYPRLAND PLUGINS (Declarative) ---
  home.file.".config/hypr-nix-plugins.conf".text = ''
    plugin = ${pkgs.hyprlandPlugins.hy3}/lib/libhy3.so
  '';
}
