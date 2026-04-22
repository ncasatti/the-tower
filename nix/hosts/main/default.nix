# nix/hosts/main/default.nix
# Main NixOS configuration for The Grid main host.
# TODO: Add hardware-configuration.nix after NixOS installation.

{ config, pkgs, inputs, ... }:

{
  imports = [
    # Auto-generated hardware scan (uncomment after installation)
    ./hardware-configuration.nix

    # Host-specific
    ./nvidia.nix

    # Shared system modules
    ../../modules/nix.nix
    ../../modules/audio.nix
    ../../modules/services.nix
    ../../modules/tailscale.nix
  ];

  # --- PLATFORM ---
  nixpkgs.hostPlatform = "x86_64-linux";

  # --- BOOTLOADER ---
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- NETWORKING ---
  networking.hostName            = "the-grid";
  networking.networkmanager.enable = true;

  # --- LOCALIZATION & CLOCK ---
  time.timeZone        = "America/Argentina/Cordoba";
  i18n.defaultLocale   = "en_US.UTF-8";
  services.xserver.xkb.layout  = "us";
  services.xserver.xkb.variant = "colemak";
  console.keyMap       = "colemak";

  # --- GLOBAL SHELL ---
  programs.fish = {
    enable = true;
    shellAliases = {
      l = null;
      ll = null;
      ls = null;
    };
  };
  programs.dconf.enable = true;

  # --- WINDOW MANAGER ---
  programs.hyprland = {
    enable          = true;
    xwayland.enable = true;
  };

  # --- NIX-LD (FHS binary compatibility for Mason/npm/etc.) ---
  programs.nix-ld.enable = true;

  # --- USER IDENTITY ---
  users.users.flyn = {
    isNormalUser = true;
    description  = "System Administrator";
    extraGroups  = [ "networkmanager" "wheel" "audio" "video" "keyd" ];
    shell        = pkgs.fish;
  };

  # --- CORE SYSTEM PACKAGES ---
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    eza
    iw
  ];

  # Do NOT change this value.
  system.stateVersion = "23.11";
}
