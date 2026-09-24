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

    # Config (model, TTS, STT, display, capabilities) is fully mutable —
    # managed via UI / Syncthing, not declared here. Only structural
    # service settings (gateway, backend, mcpServers) stay in Nix.

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
    # IMPORTANT: `command` MUST be an absolute path on NixOS. The Hermes
    # scheduler spawns MCP subprocesses with a minimal PATH (/usr/bin:/bin),
    # which does not include `/etc/profiles/per-user/flyn/bin` where `bun`
    # lives. Using just "bun" causes `FileNotFoundError: 'bun'` and the MCP
    # parks without retries. The `PATH` env var is also injected so that
    # anything the MCP server spawns (subagent runners, etc.) can find
    # curl, jq, and friends.
    mcpServers = {
      the-grid = {
        command = "/etc/profiles/per-user/flyn/bin/bun";
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
          PATH = "/etc/profiles/per-user/flyn/bin:/run/current-system/sw/bin:/usr/bin:/bin";
        };
      };
    };
  };

  # Opus codec for Discord voice bubbles is handled by patching
  # discord/opus.py in nix/overlays/default.nix (find_library cache poisoning
  # makes LD_LIBRARY_PATH unreliable for ctypes-based lazy loaders).
}
