# nix/hosts/main/home.nix
# Home Manager configuration for NixOS main host, user: flyn
# Injected via home-manager.users.flyn in the flake.

{ pkgs, ... }:

{
  imports = [
    # --- Home modules ---
    ../../home/dotfiles.nix
    ../../home/git.nix
    ../../home/gtk.nix
    ../../home/tmux.nix
    ../../home/activation.nix
    ../../home/xdg.nix
    ../../home/sioyek.nix
    ../../home/polkit.nix
    ../../home/moonlight.nix    # Moonlight client + paired config
    # ../../home/secrets.nix  # agenix — disabled for now

    # --- AI module (LiteLLM proxy + gbrain bootstrap) ---
    ../../modules/ai.nix

    # --- Package sets ---
    ../../packages/cli.nix
    ../../packages/dev.nix
    ../../packages/ai.nix
    ../../packages/nvim.nix
    ../../packages/languages.nix
    ../../packages/wayland.nix
    ../../packages/appearance.nix
    ../../packages/utilities.nix
    ../../packages/audio.nix
    ../../packages/latex.nix
  ];

  home.username      = "flyn";
  home.homeDirectory = "/home/flyn";
  home.stateVersion  = "23.11";

  # Extra packages specific to main
  home.packages = with pkgs; [
    cool-retro-term
    kitty
    obsidian

    # Screenshot & Multimedia dependencies
    grim
    slurp
    libnotify
    swappy
    xdg-user-dirs
    sound-theme-freedesktop
  ];

  # --- GBRAIN EMBED SCHEDULER ---
  # Re-embeds stale pages every 6h with jitter; persistent (runs missed runs at boot).
  # Note: home-manager systemd.user.timers/services use systemd unit schema
  # (Unit / Timer / Service / Install submodules), NOT flat keys.
  systemd.user.timers."gbrain-embed" = {
    Unit = {
      Description = "Re-embed stale gbrain pages";
    };
    Timer = {
      OnBootSec = "5min";
      OnUnitActiveSec = "6h";
      RandomizedDelaySec = "15min";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  systemd.user.services."gbrain-embed" = {
    Unit = {
      Description = "Embed gbrain pages (oneshot)";
    };
    Service = {
      Type = "oneshot";
      Environment = [
        "BUN_INSTALL=$HOME/.bun"
        "PATH=$HOME/.bun/bin:/run/current-system/sw/bin"
      ];
      ExecStart = "${pkgs.bash}/bin/bash -c 'gbrain embed --all --quiet || journalctl --user -u gbrain-embed --no-pager'";
    };
  };
}
