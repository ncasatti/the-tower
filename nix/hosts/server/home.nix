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

  # --- Hyprland monitor layout (host-scoped, ADR-003) ---
  # hyprland.conf sources configs/monitors.local.conf; we point it at this
  # host's file (single TV @ 0x0). Previously this lived in hypr-host.conf and
  # was fighting the shared monitors.conf sourced earlier — hence the TV landing
  # at 1920x0. Now it is the only monitor source, loaded early.
  home.file.".config/hypr/configs/monitors.local.conf".source =
    ../../../hypr/configs/hosts/server.conf;

  # Extra packages specific to the server/HTPC
  home.packages = with pkgs; [
    xdg-user-dirs
    clingy
    kitty
    zen-browser
    tidal-hifi
  ];

  # --- Per-host Hyprland overrides (sourced last by hypr/hyprland.conf) ---
  # Reuses the entire main look/feel; only session-env tweaks differ here.
  # Monitor layout moved to hypr/configs/hosts/server.conf (ADR-003), linked
  # above as monitors.local.conf and sourced early — no longer in this file.
  home.file.".config/hypr-host.conf".text = lib.mkForce ''
    # === HTPC host overrides (server) — sourced LAST by hypr/hyprland.conf ===

    # Re-assert Intel VA-API for anything spawned inside the session (mpv,
    # browsers, Sunshine's encoder). htpc.nix already sets this system-wide;
    # this is belt-and-suspenders for the Hyprland session env on an Intel box.
    env = LIBVA_DRIVER_NAME,iHD

    # Remote control is Sunshine (services.sunshine in htpc.nix) — a systemd
    # user service tied to the graphical session; no exec-once needed here.
  '';
}
