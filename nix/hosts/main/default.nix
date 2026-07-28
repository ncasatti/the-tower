# nix/hosts/main/default.nix
# Main NixOS configuration for The Grid main host.
# TODO: Add hardware-configuration.nix after NixOS installation.

{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    # Auto-generated hardware scan (uncomment after installation)
    ./hardware-configuration.nix

    # Host-specific
    ./nvidia.nix
    ./storage.nix
    ./swap.nix

    # Shared system modules
    ../../modules/nix.nix
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

  # --- KERNEL PARAMS ---
  # amd_pstate driver fails to load on Ryzen 5 3600 (ACPI reports
  # min/max/nominal_freq=0 → init fails with -19). Force passive mode so it
  # reads ACPI CPPC tables directly; CPU can boost to 4.2 GHz instead of
  # being capped at 3.6 GHz by the acpi-cpufreq fallback.
  boot.kernelParams = [ "amd_pstate=passive" ];

  # --- SSD TRIM (batched, replaces continuous discard) ---
  # hardware-configuration.nix mounts root with 'discard' (continuous TRIM on
  # every file delete = sync I/O). Override to drop discard and rely on
  # fstrim.timer, which batches TRIM commands once per week.
  fileSystems."/".options = lib.mkForce [ "noatime" "nodiratime" ];
  services.fstrim.enable  = true;

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
  # Opt-in enabled: this is the host where kanata is being tested.
  the-grid.kanata.enable = false;

  # Do NOT change this value.
  system.stateVersion = "23.11";
}
