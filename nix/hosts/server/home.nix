# nix/hosts/server/home.nix
# Home Manager configuration for NixOS server host, user: flyn.
# The server wears three hats: infra + HTPC + audio workstation.
# Injected via home-manager.users.flyn in the flake.

{ pkgs, lib, ... }:

{
  imports = [
    # --- Home modules ---
    ../../home/dotfiles.nix
    ../../home/git.nix
    ../../home/tmux.nix
    ../../home/gtk.nix
    ../../home/xdg.nix
    ../../home/polkit.nix
    ../../home/activation.nix   # hy3 plugin load + wallust cache scaffold
    ../../home/session.nix      # session env vars + PATH (migrated from fish)

    # --- Package sets ---
    ../../packages/nvim.nix
    ../../packages/cli.nix
    ../../packages/languages.nix
    ../../packages/wayland.nix     # Hyprland UI stack (waybar, rofi, swaync, awww…)
    ../../packages/appearance.nix  # fonts + GTK/icon themes (main look)
    ../../packages/audio.nix       # Carla, wiremix, qpwgraph + LV2/VST plugins
  ];

  home.username      = "flyn";
  home.homeDirectory = "/home/flyn";
  home.stateVersion  = "23.11";

  # Extra packages specific to the server/HTPC
  home.packages = with pkgs; [
    xdg-user-dirs
    clingy
    kitty
    zen-browser
    tidal-hifi
  ];

  # --- Per-host Hyprland overrides (sourced last by hypr/hyprland.conf) ---
  # Shared hypr/ is hardcoded for main; this overrides monitor + startup for the
  # HTPC. Reuses the entire main look/feel — only these lines differ.
  home.file.".config/hypr-host.conf".text = lib.mkForce ''
    # === HTPC host overrides (server) — sourced LAST by hypr/hyprland.conf ===

    # Re-assert Intel VA-API for anything spawned inside the session (mpv,
    # browsers, Sunshine's encoder). The shared hypr/configs/env.conf sets
    # LIBVA_DRIVER_NAME=nvidia for main's GPU; this box is Intel-only.
    env = LIBVA_DRIVER_NAME,iHD

    # The TV is THE monitor. The notebook lid panel stays disabled: nobody
    # looks at it in the rack, and a second output creates focus/input
    # ambiguity for remote control (windows opening on the unseen screen).
    monitor = HDMI-A-1, 1920x1080@60, 0x0, 1
    monitor = eDP-1, disable

    # Remote control is Sunshine (services.sunshine in htpc.nix) — a systemd
    # user service tied to the graphical session; no exec-once needed here.
  '';
}
