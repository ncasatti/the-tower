# nix/hosts/notebook/services.nix
# System services: SSH, keyd, avahi, power management, bluetooth, graphics

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
  environment.etc."keyd/default.conf".source = ../../../keyd/default.conf;

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
