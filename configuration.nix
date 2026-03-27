# configuration.nix
# Master configuration file for The Grid (NixOS Mainframe)

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan (generated during installation)
      ./hardware-configuration.nix
    ];

  # --- NIX SETTINGS ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # --- BOOTLOADER ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- NETWORKING & DISCOVERY ---
  networking.hostName = "the-grid";
  networking.networkmanager.enable = true;
  # Enables Avahi daemon for local network discovery (matches your active services)
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  # --- LOCALIZATION & CLOCK ---
  time.timeZone = "America/Argentina/Cordoba";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.variant = "colemak";
  console.keyMap = "colemak";

  # --- HARDWARE DAEMONS ---
  hardware.bluetooth.enable = true; # Enables Bluetooth hardware support
  services.power-profiles-daemon.enable = true; # Power management for the notebook

  # --- GRAPHICS ACCELERATION ---
  hardware.graphics.enable = true;

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
  programs.dconf.enable = true;

  # --- WINDOW MANAGER ---
  programs.hyprland = {
      enable = true;
      xwayland.enable = true;
  };

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

    # --- Secret Management ---
    inputs.agenix.packages.x86_64-linux.default  # agenix CLI

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

  # --- SECRETS (agenix) ---
  # Encrypted secrets decrypted at activation time to /run/agenix/
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  age.secrets = {
    # SSH keys
    ssh-key-nc-gh = {
      file = ./secrets/ssh-key-nc-gh.age;
      owner = "flyn";
      group = "users";
      mode = "0600";
      path = "/home/flyn/.ssh/keys/nc-gh";
    };
    ssh-key-ncasatti-aws-puertorico = {
      file = ./secrets/ssh-key-ncasatti-aws-puertorico.age;
      owner = "flyn";
      group = "users";
      mode = "0600";
      path = "/home/flyn/.ssh/keys/ncasatti-aws-puertorico";
    };
    ssh-key-ncasatti-aws-emser = {
      file = ./secrets/ssh-key-ncasatti-aws-emser.age;
      owner = "flyn";
      group = "users";
      mode = "0600";
      path = "/home/flyn/.ssh/keys/ncasatti-aws-emser";
    };
    ssh-key-xionico-devops = {
      file = ./secrets/ssh-key-xionico-devops.age;
      owner = "flyn";
      group = "users";
      mode = "0600";
      path = "/home/flyn/.ssh/keys/xionico-devops-ncasatti-keypair.pem";
    };
    ssh-key-emser-licenses = {
      file = ./secrets/ssh-key-emser-licenses.age;
      owner = "flyn";
      group = "users";
      mode = "0600";
      path = "/home/flyn/.ssh/keys/emserlicensesserver-v2-key.pem";
    };
    ssh-key-emser-supplai = {
      file = ./secrets/ssh-key-emser-supplai.age;
      owner = "flyn";
      group = "users";
      mode = "0600";
      path = "/home/flyn/.ssh/keys/emser-supplai-key.pem";
    };

    # SSH config
    ssh-config = {
      file = ./secrets/ssh-config.age;
      owner = "flyn";
      group = "users";
      mode = "0600";
      path = "/home/flyn/.ssh/config";
    };

    # AWS
    aws-config = {
      file = ./secrets/aws-config.age;
      owner = "flyn";
      group = "users";
      mode = "0600";
      path = "/home/flyn/.aws/config";
    };
    aws-credentials = {
      file = ./secrets/aws-credentials.age;
      owner = "flyn";
      group = "users";
      mode = "0600";
      path = "/home/flyn/.aws/credentials";
    };

    # Rclone
    rclone-config = {
      file = ./secrets/rclone-config.age;
      owner = "flyn";
      group = "users";
      mode = "0600";
      path = "/home/flyn/.config/rclone/rclone.conf";
    };
  };

  # Do NOT change this value.
  system.stateVersion = "23.11"; 
}
