# nix/modules/hermes.nix
# Hermes Agent (NousResearch) — home-level install for user flyn.
#
# The package is aliased in nix/overlays/default.nix (pkgs.hermes-agent), like
# the other third-party flakes. The Home Manager MODULE, however, is not a
# package and cannot go through the overlay — `imports` must reference it at
# inputs.hermes-agent.homeManagerModules.default. Keeping both here leaves the
# host home.nix clean (relative-path imports only), consistent with ai.nix.
#
# Phase 0: CLI install                         ✓ (programs.enable)
# Phase 1: backend + gateway as systemd --user ← this change
#
# IMPORTANT: the NixOS host config must set `users.users.flyn.linger = true`
# so systemd keeps the user slice alive after logout.
{ inputs, pkgs, ... }:

{
  imports = [ inputs.hermes-agent.homeManagerModules.default ];

  # ── CLI + Desktop app ─────────────────────────────────────────────────
  programs.hermes-agent = {
    enable = true;
    # pkgs.hermes-agent is the overlay alias (minimal build). Add only the
    # dependency groups a phase needs; `anthropic` = the Claude/Anthropic SDK
    # (initializes the provider; calling Claude still needs an API key/auth).
    package = pkgs.hermes-agent.override {
      extraDependencyGroups = [
        "anthropic"
        "messaging"
      ];
    };
    desktop.enable = true;
  };

  # ── Services (gateway + web dashboard) ────────────────────────────────
  services.hermes-agent = {
    enable = true;

    # Declarative settings merged into config.yaml on activation.
    settings = {
      display.skin = "the-grid";
      # Primary model. Hermes reads `model.default` + `model.provider`
      # (there is no `default_model` key).
      model = {
        default = "MiniMax-M3";
        provider = "minimax";
      };
      fallback_model = {
        provider = "minimax";
        model = "MiniMax-M3";
      };
      # Voice: speech-to-text (Groq cloud — whisper-large-v3)
      # Free tier: 20 RPM, 2K RPD, 8h audio/day. Works from any client.
      # Fallback: local faster-whisper small on CPU (1.5 GB RAM)
      stt = {
        enabled = true;
        provider = "groq";
        language = "es";
      };
      # Voice: text-to-speech
      # Edge TTS alternatives (free, no API key):
      #   es-MX-DaliaNeural (preferred Edge voice)
      #   es-AR-TomasNeural, es-AR-ElenaNeural
      #   en-US-GuyNeural, en-US-AriaNeural
      tts = {
        provider = "gemini";
        gemini.voice = "Kore";
      };
    };

    # Messaging gateway (Telegram, Discord, etc.) — starts as
    # systemd.user.services.hermes-agent
    gateway.enable = true;

    # Web dashboard + backend API (JSON-RPC/WS on :9119) — starts as
    # systemd.user.services.hermes-backend
    # "dashboard" = "serve" + browser admin panel on the same port.
    backend = {
      mode = "dashboard";
      host = "127.0.0.1";
      port = 9119;
    };

    # ── Declarative MCP servers ───────────────────────────────────────
    mcpServers = {
      the-grid = {
        command = "bun";
        args = [
          "run"
          "--cwd"
          "/home/flyn/.the-grid/systems/grid/packages/mcp"
          "start"
        ];
        env = {
          VAULT_PATH = "/home/flyn/.local/share/the-grid";
          DB_PATH = "/home/flyn/.local/state/the-grid/.grid.db";
          MCP_ACTOR = "agent/hermes";
        };
      };
    };
  };

  # ── Opus codec for Discord voice bubbles ──────────────────────────────
  # discord.py loads libopus via ctypes.util.find_library('opus'), which
  # needs LD_LIBRARY_PATH on NixOS. The overlay also patches the wrapper,
  # but the systemd service must carry the env var too.
  systemd.user.services.hermes-agent.Service.Environment = [
    "LD_LIBRARY_PATH=${pkgs.libopus}/lib"
  ];
}
