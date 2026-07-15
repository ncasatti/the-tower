# nix/hosts/wsl/default.nix
# NixOS-WSL host — full NixOS running as a WSL2 distribution on a Windows box.
# Fourth peer of the Grid. Purpose: the Neovim stack and the Obsidian vault
# (synced via Syncthing into native ext4), driven from inside Windows.
#
# Deployment (run INSIDE the distro): sudo nixos-rebuild switch --flake .#wsl
#
# Deliberately SLIM: no Hyprland/GPU-desktop/audio/keyboard modules — WSL is
# headless and GUI apps render through WSLg. See docs/nixos-wsl.md.

{ pkgs, ... }:

{
  imports = [
    # Shared system modules (headless subset)
    ../../modules/nix.nix
    ../../modules/security.nix
    ../../modules/tailscale.nix
    ../../modules/fish.nix
    ../../modules/syncthing.nix
  ];

  # --- PLATFORM ---
  nixpkgs.hostPlatform = "x86_64-linux";

  # --- WSL ---
  # NixOS-WSL provides the boot integration and hardware layer; no bootloader
  # or hardware-configuration.nix needed here.
  wsl.enable      = true;
  wsl.defaultUser = "flyn";

  # --- NETWORKING ---
  # hostName MUST match the Tailscale MagicDNS name so peers resolve
  # tcp://the-grid-wsl:22000 (see nix/modules/syncthing.nix `grid`).
  networking.hostName = "the-grid-wsl";

  # --- LOCALIZATION & CLOCK ---
  time.timeZone      = "America/Argentina/Cordoba";
  i18n.defaultLocale = "en_US.UTF-8";

  # --- GUI (WSLg) ---
  # Obsidian is an Electron app; it renders through WSLg's Wayland/X11 sockets.
  # mesa (llvmpipe) provides the libGL it needs under software rendering.
  hardware.graphics.enable = true;

  # --- USER IDENTITY ---
  users.users.flyn = {
    isNormalUser = true;
    description  = "System Administrator";
    extraGroups  = [ "wheel" ];
    shell        = pkgs.fish;
  };

  # --- CORE SYSTEM PACKAGES ---
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    eza
  ];

  # Do NOT change this value.
  system.stateVersion = "23.11";
}
