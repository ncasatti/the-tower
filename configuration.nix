# configuration.nix
# Master configuration file for The Grid (NixOS Mainframe)

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan (generated during installation)
      ./hardware-configuration.nix
    ];

  # --- BOOTLOADER ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- NETWORKING & DISCOVERY ---
  networking.hostName = "the-grid-mainframe";
  networking.networkmanager.enable = true;
  # Enables Avahi daemon for local network discovery (matches your active services)
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  # --- LOCALIZATION & CLOCK ---
  time.timeZone = "America/Argentina/Cordoba";
  i18n.defaultLocale = "es_AR.UTF-8";

  # --- HARDWARE DAEMONS ---
  hardware.bluetooth.enable = true; # Enables Bluetooth hardware support
  services.power-profiles-daemon.enable = true; # Power management for the notebook

  # --- KEY RE-MAPPING (keyd) ---
  # Enables the keyd daemon. You can define your layout directly here.
  services.keyd.enable = true;

  # --- SSH DAEMON ---
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = true;
  };

  # --- AUDIO SUBSYSTEM (PipeWire) ---
  # Replaces PulseAudio and JACK. Provides ultra-low latency for Focusrite & Carla.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # CRITICAL: Emulates JACK server natively for Carla
    jack.enable = true; 
  };

  # --- GLOBAL SHELL ---
  programs.fish.enable = true;

  # --- USER IDENTITY ---
  users.users.flyn = {
    isNormalUser = true;
    description = "System Administrator";
    # 'wheel' for sudo, 'keyd' to allow user to reload keyd configs
    extraGroups = [ "networkmanager" "wheel" "audio" "video" "keyd" ];
    shell = pkgs.fish;
  };

  # --- CORE SYSTEM PACKAGES ---
  # Only absolute necessities. UI and dev tools go to home.nix.
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    carla 
  ];

  # Do NOT change this value.
  system.stateVersion = "23.11"; 
}
