# nix/hosts/notebook/default.nix
# Main NixOS configuration for The Grid notebook host.
# Imports sub-modules for audio, secrets, and services.

{ config, pkgs, inputs, ... }:

{
  imports = [
    # Auto-generated hardware scan
    ./hardware-configuration.nix

    # Shared system modules
    ../../modules/nix.nix
    ../../modules/boot-invariants.nix   # Stage 1 mkForce guard
    ../../modules/audio.nix
    ../../modules/services.nix
    ../../modules/kanata.nix
    ../../modules/tailscale.nix
    ../../modules/security.nix
    ../../modules/docker.nix
    ../../modules/fish.nix
    ../../modules/syncthing.nix
    ../../modules/gaming.nix   # Steam + GE-Proton + Faugus (Battle.net)
  ];

  # --- PLATFORM ---
  nixpkgs.hostPlatform = "x86_64-linux";

  # --- BOOTLOADER ---
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Retain at least 5 bootable generations. On hosts with encrypted root this
  # is the difference between a 30-second rollback and a rescue USB. See
  # boot-lockout-postmortem.md §10.4.
  boot.loader.systemd-boot.configurationLimit = 5;

  # --- KERNEL: TEMPORARY PIN TO 6.12 LTS ---
  # Since the 2026-10-21 nixpkgs bump (kernel 6.18.26 -> 6.18.57, systemd
  # 260.1 -> 262) waking from s2idle by opening the lid powers the machine
  # off: PID 1 logs "Received SIGRTMIN+4." with no sender PID (kernel-origin)
  # and starts poweroff.target. 184 resumes on 6.18.26 -> 0 poweroffs;
  # 4 resumes on 6.18.57 -> 4 poweroffs. rtcwake/systemctl-suspend wakes do
  # NOT reproduce it; only lid-open wake does.
  # This pin isolates kernel vs systemd. It tracks the 6.12 LTS branch, so
  # it still receives patch releases. Remove it (back to the default kernel)
  # once a 6.18.x with the fix lands — candidate upstream fix:
  # "ACPI: button: Report wakeup key only for power button wakeups"
  # (fixes 16f70feaabe9). Vault: systems/the-tower (notebook lid poweroff).
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # --- NETWORKING ---
  networking.hostName            = "the-grid-notebook";
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd.enable = true;

  # --- LOCALIZATION & CLOCK ---
  time.timeZone        = "America/Argentina/Cordoba";
  i18n.defaultLocale   = "en_US.UTF-8";
  services.xserver.xkb.layout  = "us";
  services.xserver.xkb.variant = "colemak";
  console.keyMap       = "colemak";

  # --- GLOBAL SHELL --- (fish → modules/fish.nix)
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

  # --- KANATA KEYBOARD REMAPPER ---
  # Module imported above; enable on the host where you're testing kanata.
  # Set to `true` on the active host, leave `false` on the others.
  the-grid.kanata.enable = false;

  # --- CORE SYSTEM PACKAGES ---
  # Only absolute necessities. UI and dev tools go to home modules.
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    eza
    wiremix
    iw
  ];

  services.logind.settings.Login = {
    HandleLidSwitch              = "suspend";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked        = "ignore";
  };

  # Do NOT change this value.
  system.stateVersion = "23.11";
}
