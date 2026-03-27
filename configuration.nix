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
  services.keyd.enable = true;
  environment.etc."keyd/default.conf".source = ./keyd/default.conf;

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
    # --- Core Utilities ---
    git
    curl
    wget

    # --- Pro Audio: DAWs & Hosts ---
    ardour          # Professional DAW
    carla           # Plugin host (LV2, VST, SF2, SFZ)
    qjackctl        # JACK control GUI
    qpwgraph        # PipeWire graph GUI

    # --- Pro Audio: LV2/LADSPA Plugins ---
    calf            # LV2 plugin suite (EQ, compressors, reverbs)
    x42-plugins     # Professional meters, EQ, analyzers
    gxplugins-lv2   # Guitarix LV2 plugins (amp sims, effects)

    # --- Pro Audio: Libraries & Engines ---
    fluidsynth      # SoundFont synthesizer (used by Carla for SF2)
    lilv            # LV2 plugin host library
    lv2             # LV2 plugin standard
    aubio           # Audio analysis (pitch detection, onset)

    # --- Audio Utilities ---
    pavucontrol     # PipeWire/PulseAudio volume control GUI
    pamixer         # CLI mixer
  ];

  # --- REALTIME AUDIO LIMITS (Pro Audio) ---
  # Required for low-latency operation with Focusrite interface.
  security.pam.loginLimits = [
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "rtprio";  type = "-"; value = "99"; }
    { domain = "@audio"; item = "nice";    type = "-"; value = "-19"; }
  ];

  # Do NOT change this value.
  system.stateVersion = "23.11"; 
}
