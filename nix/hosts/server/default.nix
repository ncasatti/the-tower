# nix/hosts/server/default.nix
# Headless NixOS configuration for The Grid server (DNS + VPN node).
# No GUI, no Hyprland, no Home Manager. Pure infrastructure.
# TODO: Add hardware-configuration.nix after NixOS installation.

{ pkgs, ... }:

{
  imports = [
    # Auto-generated hardware scan (uncomment after installation)
    ./hardware-configuration.nix

    # Shared system modules
    ../../modules/nix.nix
    ../../modules/services.nix
    ../../modules/tailscale.nix
    ../../modules/security.nix

    # Server-specific
    ./adguard.nix
  ];

  # --- PLATFORM ---
  nixpkgs.hostPlatform = "x86_64-linux";

  # --- BOOTLOADER ---
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- NETWORKING ---
  networking.hostName            = "the-grid-server";
  networking.networkmanager.enable = true;

  # --- LOCALIZATION & CLOCK ---
  time.timeZone      = "America/Argentina/Cordoba";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap     = "colemak";

  # --- SHELL ---
  programs.fish.enable = true;

  # --- USER IDENTITY ---
  users.users.flyn = {
    isNormalUser = true;
    description  = "System Administrator";
    extraGroups  = [ "networkmanager" "wheel" ];
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
