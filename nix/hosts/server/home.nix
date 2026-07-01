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
    # === HTPC host overrides (server) ===
    # The TV is the only output. Disable main's second monitor and place the TV
    # at the origin. Set an explicit mode if `preferred` misdetects the TV.
    monitor = DP-1, disable
    monitorv2 {
        output = HDMI-A-1
        mode = preferred
        position = 0x0
        scale = 1
    }

    # === Remote control: hypr-rdp ===
    # Reads bind/output/credentials from ~/.config/hypr-rdp/config.toml (create
    # it manually, chmod 600 — NEVER commit credentials to the flake/store).
    # Port 3389 is reachable ONLY over Tailscale (tailscale0 is trusted; 3389 is
    # never in networking.firewall.allowedTCPPorts).
    exec-once = hypr-rdp
  '';
}
