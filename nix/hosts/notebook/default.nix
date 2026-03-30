# nix/hosts/notebook/default.nix
# Main NixOS configuration for The Grid notebook host.
# Imports sub-modules for audio, secrets, and services.

{ config, pkgs, inputs, ... }:

{
  imports = [
    # Auto-generated hardware scan (stays at repo root)
    ../../../hardware-configuration.nix

    # Host sub-modules
    ./audio.nix
    ./secrets.nix
    ./services.nix
  ];

  # --- NIX SETTINGS ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree          = true;

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
  programs.fish.enable  = true;
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
    # 'wheel' for sudo, 'keyd' to allow user to reload keyd configs
    extraGroups  = [ "networkmanager" "wheel" "audio" "video" "keyd" ];
    shell        = pkgs.fish;
  };

  # --- CORE SYSTEM PACKAGES ---
  # Only absolute necessities. UI and dev tools go to home modules.
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    eza
    # agenix CLI
    inputs.agenix.packages.x86_64-linux.default
  ];

  # Do NOT change this value.
  system.stateVersion = "23.11";
}
