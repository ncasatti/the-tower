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

  # Extra packages specific to the server/HTPC
  home.packages = with pkgs; [
    xdg-user-dirs
    clingy
    kitty
    zen-browser
    tidal-hifi
    hypr-rdp       # native RDP server (overlay → github:MuNeNICK/hypr-rdp)
  ];

  # --- Per-host Hyprland overrides (sourced last by hypr/hyprland.conf) ---
  # Shared hypr/ is hardcoded for main; this overrides monitor + startup for the
  # HTPC. Reuses the entire main look/feel — only these lines differ.
  home.file.".config/hypr-host.conf".text = lib.mkForce ''
    # === HTPC host overrides (server) — sourced LAST by hypr/hyprland.conf ===

    # Force Intel VA-API for hypr-rdp's H.264 encode. The shared
    # hypr/configs/env.conf sets LIBVA_DRIVER_NAME=nvidia (that box has an NVIDIA
    # GPU); it leaks here and makes VA-API init fail → software H.264 (high CPU,
    # low fps). This box is Intel-only. Re-assert iHD; sourced after env.conf and
    # before the exec-once below, so hypr-rdp inherits it.
    env = LIBVA_DRIVER_NAME,iHD

    # The notebook lid panel is the only real output (rack; nobody looks at it,
    # but hypr-rdp mirrors it). Pin scale 1 — auto-detect landed on 0.67, whose
    # aspect normalization fed the RDP presentation-resize loop. No TV yet; when
    # HDMI is plugged in it appears as a second output, e.g.:
    #   monitor = HDMI-A-1, preferred, 1366x0, 1
    monitor = eDP-1, preferred, 0x0, 1

    # === Remote control: hypr-rdp ===
    # Reads bind/output/credentials from ~/.config/hypr-rdp/config.toml (created
    # manually, chmod 600 — NEVER commit credentials to the flake/store). With
    # output = "eDP-1" it MIRRORS the panel above; omit `output` there instead
    # for a managed 1920x1080 headless desktop. Port 7777 is reachable ONLY over
    # Tailscale (tailscale0 trusted; 7777 not in allowedTCPPorts).
    exec-once = hypr-rdp
  '';
}
