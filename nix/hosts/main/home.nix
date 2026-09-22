# nix/hosts/main/home.nix
# Home Manager configuration for NixOS main host, user: flyn
# Injected via home-manager.users.flyn in the flake.

{ pkgs, ... }:

let
  # tidal-hifi (Electron/Chromium) has no working VA-API on this NVIDIA host
  # (no nvidia-vaapi-driver). Its video-decode path stalls the shared GPU and
  # freezes the compositor + other GPU clients (e.g. Zen). Disable VA-API
  # decode/encode; GPU compositing/rasterization is kept. See ADR-002.
  # (let-bound name shadows pkgs.tidal-hifi inside `with pkgs` below.)
  tidal-hifi = pkgs.symlinkJoin {
    name = "tidal-hifi-no-vaapi";
    paths = [ pkgs.tidal-hifi ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/tidal-hifi \
        --add-flags "--disable-features=VaapiVideoDecoder,VaapiVideoEncoder"
    '';
  };
in
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

    # --- AI module (LiteLLM proxy) ---
    ../../modules/ai.nix

    # --- Hermes Agent (NousResearch) — see nix/modules/hermes.nix ---
    ../../modules/hermes.nix

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

  # --- Hyprland monitor layout (host-scoped, ADR-003) ---
  # hyprland.conf sources configs/monitors.local.conf; we point it at this
  # host's file. The shared configs/monitors.conf is no longer sourced.
  home.file.".config/hypr/configs/monitors.local.conf".source =
    ../../../hypr/configs/hosts/main.conf;

  # Extra packages specific to main
  home.packages = with pkgs; [
    cool-retro-term
    kitty
    obsidian
    tidal-hifi   # wrapped above: VA-API decode disabled (ADR-002)

    # Screenshot & Multimedia dependencies
    grim
    slurp
    libnotify
    swappy
    xdg-user-dirs
    sound-theme-freedesktop
  ];
}
