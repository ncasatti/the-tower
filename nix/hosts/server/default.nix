# nix/hosts/server/default.nix
# NixOS configuration for The Grid server — a rack notebook that wears three
# hats: infra node (DNS + VPN), HTPC (video/music on TV + stereo), and audio
# workstation (Carla + USB interface). Controlled remotely over Tailscale.
# See docs/server-htpc-migration.md for the design.

{ pkgs, ... }:

{
  imports = [
    # Auto-generated hardware scan (uncomment after installation)
    ./hardware-configuration.nix

    # Shared system modules
    ../../modules/nix.nix
    ../../modules/services.nix
    ../../modules/kanata.nix
    ../../modules/tailscale.nix
    ../../modules/security.nix
    ../../modules/audio.nix     # PipeWire + JACK + rtkit (Carla, USB interface)
    ../../modules/fish.nix
    ../../modules/syncthing.nix
    ../../modules/wifi-no-powersave.nix  # RDP streams over Wi-Fi; kill latency spikes

    # Server-specific
    ./adguard.nix
    ./htpc.nix                  # Hyprland + greetd autologin + Intel VA-API
    ./swap.nix
  ];

  # --- PLATFORM ---
  nixpkgs.hostPlatform = "x86_64-linux";

  # --- BOOTLOADER ---
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- NETWORKING ---
  networking.hostName            = "the-grid-server";
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd.enable = true;

  # --- LOCALIZATION & CLOCK ---
  time.timeZone      = "America/Argentina/Cordoba";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap     = "colemak";

  # --- USER IDENTITY ---
  users.users.flyn = {
    isNormalUser = true;
    description  = "System Administrator";
    extraGroups  = [ "networkmanager" "wheel" "audio" "video" "keyd" "uinput" ];
    shell        = pkgs.fish;
  };

  # --- CORE SYSTEM PACKAGES ---
  environment.systemPackages = with pkgs; [
    curl
    wget
    eza
    htop
  ];

  # --- HEADLESS: Prevent suspend on lid close ---
  services.logind.settings.Login = {
    HandleLidSwitch              = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked        = "ignore";
  };

  # Do NOT change this value.
  system.stateVersion = "23.11";
}
