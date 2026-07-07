# nix/hosts/server/htpc.nix
# Graphical + remote-control layer that turns the infra node into an HTPC.
#
# The TV (HDMI) is the REAL monitor; Hyprland renders to it. Sunshine is only a
# remote control (Moonlight on main is the client) and is reachable EXCLUSIVELY
# over Tailscale (see modules/tailscale.nix: tailscale0 is a trusted firewall
# interface, and Sunshine's ports are never opened globally — openFirewall is
# kept false below).

{ pkgs, ... }:

{
  # --- WINDOW MANAGER (parity with main) ---
  programs.hyprland = {
    enable          = true;
    xwayland.enable = true;
  };
  programs.dconf.enable = true;

  # --- FHS binary compatibility (Mason/npm/etc.) ---
  programs.nix-ld.enable = true;

  # --- AUTOLOGIN INTO HYPRLAND (headless boot: no physical keyboard) ---
  # greetd launches Hyprland as `flyn` automatically on boot AND after any
  # logout, so the session always returns without a keyboard. Physical access is
  # already trusted (in-home); remote access is gated by Tailscale. SSH remains
  # the recovery path if the GUI fails to come up.
  services.greetd = {
    enable = true;
    settings = {
      initial_session = { command = "Hyprland"; user = "flyn"; };
      default_session = { command = "Hyprland"; user = "flyn"; };
    };
  };

  # --- REMOTE CONTROL: Sunshine (video/audio stream + input injection) ---
  # Runs as a user service inside the graphical session (autoStart) and
  # captures the single active output (the TV) via wlr-screencopy; H.264
  # encode goes through VA-API (iHD below). One-time setup after rebuild:
  #   on server (ssh):  sunshine --creds <user> <password>   # web UI login
  #   on main:          moonlight pair the-grid-server
  #                     then enter the PIN at https://the-grid-server:47990
  #                     (web UI reachable over Tailscale only).
  services.sunshine = {
    enable       = true;
    autoStart    = true;
    openFirewall = false;  # VPN-only by construction: LAN never sees the ports
  };

  # --- INTEL VA-API (HW video decode + feeds Sunshine's H.264 encode) ---
  # hardware.graphics.enable is already set in modules/services.nix.
  # NOTE: intel-media-driver (iHD) targets Broadwell (Gen8) and newer. If this
  # iGPU is older, VA-API will fail — switch to intel-vaapi-driver and set
  # LIBVA_DRIVER_NAME = "i965".
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
  ];
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  # --- KEYBOARD (parity with main: colemak) ---
  services.xserver.xkb.layout  = "us";
  services.xserver.xkb.variant = "colemak";
}
