# nix/hosts/main/default.nix
# Main NixOS configuration for The Grid main host.

{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    # Host-specific
    ./nvidia.nix
    ./storage.nix
    ./swap.nix

    # Shared system modules
    ../../modules/nix.nix
    ../../modules/boot-invariants.nix   # Stage 1 mkForce guard
    ../../modules/audio.nix
    ../../modules/services.nix
    ../../modules/journald.nix
    ../../modules/kanata.nix
    ../../modules/tailscale.nix
    ../../modules/security.nix
    ../../modules/docker.nix
    ../../modules/metabase.nix  # BI, on-demand (systemctl start metabase)
    ../../modules/fish.nix
    ../../modules/syncthing.nix
    ../../modules/wifi-no-powersave.nix  # RDP client side; kill latency spikes
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

  # --- STAGE 1 RESCUE ACCESS ---
  # Unauthenticated root shell when the initrd drops to emergency.target.
  # This is not a security regression: systemd-boot's cmdline editor is enabled,
  # so anyone with physical access can already obtain an initrd root shell with
  # rd.systemd.debug_shell (debug-shell.service is ExecStart=/bin/sh, no
  # sulogin). Leaving this false locks out nobody but us -- the data is
  # protected by LUKS either way, not by the initrd shadow file.
  boot.initrd.systemd.emergencyAccess = true;

  # --- SSD TRIM (batched, replaces continuous discard) ---
  # 'discard' is dropped directly in hardware-configuration.nix, NOT overridden
  # from here.
  #
  # NEVER write `fileSystems."/".options = lib.mkForce [ ... ]`.
  # nixos/modules/tasks/filesystems.nix:229-244 builds that list with mkMerge
  # and injects "x-initrd.mount" for every boot-critical filesystem. mkForce
  # (priority 50) replaces the entire merge and silently drops that flag.
  # Without it systemd-fstab-generator never creates sysroot.mount, the root is
  # never mounted in stage 1, and initrd-find-nixos-closure resolves init=
  # against an empty /sysroot and fails -> emergency.target with a poisoned
  # transaction that not even the correct passphrase can rescue.
  services.fstrim.enable = true;

  # --- NETWORKING ---
  networking.hostName            = "the-grid";
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

  # --- OLLAMA (local embedding server for gbrain) ---
  services.ollama = {
    enable = true;
    host = "127.0.0.1";
    port = 11434;
    openFirewall = false;
  };

  # --- KANATA KEYBOARD REMAPPER ---
  # Module imported above; enable on the host where you're testing kanata.
  # Set to `true` on the active host, leave `false` on the others.
  the-grid.kanata.enable = false;

  # Do NOT change this value.
  system.stateVersion = "23.11";
}
