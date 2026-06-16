# nix/home/polkit.nix
# Hyprland Policykit authentication agent (declarative).
#
# Replaces the FHS-path `scripts/system/polkit.sh`, which only knew Debian/Arch
# paths (/usr/lib/polkit-*) and silently no-ops on NixOS, leaving GUI auth
# prompts (pkexec, mounts, GParted, etc.) non-functional.
#
# Home Manager DEFINES the systemd user service; Hyprland STARTS it explicitly
# from configs/startup.conf, since this session is launched via exec-once and
# never reaches graphical-session.target on its own.
{ ... }:

{
  services.hyprpolkitagent.enable = true;
}
