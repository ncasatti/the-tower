# nix/hosts/server/htpc.nix
# Graphical + remote-control layer that turns the infra node into an HTPC.
#
# The TV (HDMI) is the REAL monitor; Hyprland renders to it. hypr-rdp is only a
# remote control and is reachable EXCLUSIVELY over Tailscale (see
# modules/tailscale.nix: tailscale0 is a trusted firewall interface, and port
# 3389 is never opened globally via allowedTCPPorts).

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

  # --- INTEL VA-API (HW video decode + feeds hypr-rdp H.264 encode) ---
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
