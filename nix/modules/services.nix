# nix/modules/services.nix
# Shared system services: SSH, keyd, avahi, power management, bluetooth, graphics

{ ... }:

{
  # --- SSH DAEMON ---
  services.openssh = {
    enable                        = true;
    settings.PermitRootLogin      = "no";
    settings.PasswordAuthentication = true;
  };

  # --- KEY RE-MAPPING (keyd) ---
  services.keyd.enable = true;
  environment.etc."keyd/default.conf".source = ../../keyd/default.conf;
  # keyd chowns its IPC socket (/var/run/keyd.socket, 0660) to this group when
  # it exists. Members can `keyd bind` at runtime (keyd-application-mapper).
  # Socket access is root-equivalent: it can inject arbitrary keystrokes.
  users.groups.keyd = { };
  # When that group exists keyd calls setgid() at startup. The nixpkgs unit
  # drops CAP_SETGID and filters ~@privileged, so keyd dies with
  # "setgid: Operation not permitted". Re-allow exactly that.
  systemd.services.keyd.serviceConfig = {
    CapabilityBoundingSet = [ "CAP_SETGID" ];
    SystemCallFilter = [ "@setuid" ];
  };
  # default.conf is linked via environment.etc, not the module's `settings`,
  # so a rebuild would not restart keyd on config changes. Tie them.
  systemd.services.keyd.restartTriggers = [ ../../keyd/default.conf ];

  # --- LOCAL NETWORK DISCOVERY (Avahi) ---
  services.avahi.enable   = true;
  services.avahi.nssmdns4 = true;

  # --- POWER MANAGEMENT ---
  services.power-profiles-daemon.enable = true;

  # --- BLUETOOTH ---
  hardware.bluetooth.enable = true;

  # --- GRAPHICS ACCELERATION ---
  hardware.graphics.enable = true;
}
