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
{ inputs, config, pkgs, lib, ... }:

let
  cfgGrid = config.the-grid.hermes;

  # Session token shared by hermes-backend and the hermes-desktop wrapper.
  # Runtime path (never a Nix path literal: that would copy the secret into
  # the world-readable store).
  desktopTokenFile = "/home/flyn/.hermes/secrets/desktop-token";

  # Idempotent: creates the token only when absent or empty, never rotates
  # an existing one (rotation would 401 any open desktop session).
  ensureDesktopToken = pkgs.writeShellScript "hermes-ensure-desktop-token" ''
    set -eu
    PATH=${lib.makeBinPath [ pkgs.coreutils ]}
    f=${lib.escapeShellArg desktopTokenFile}
    if [ -s "$f" ]; then exit 0; fi
    umask 077
    install -d -m 0700 "$(dirname "$f")"
    tmp="$(mktemp "$f.XXXXXX")"
    head -c 32 /dev/urandom | base64 | tr '+/' '-_' | tr -d '=\n' > "$tmp"
    chmod 0600 "$tmp"
    mv -f "$tmp" "$f"
    echo "hermes-ensure-desktop-token: minted new session token at $f" >&2
  '';

  # pkgs.hermes-agent is the overlay alias (minimal build). Add only the
  # dependency groups a phase needs; `anthropic` = the Claude/Anthropic SDK
  # (initializes the provider; calling Claude still needs an API key/auth).
  hermesPkg = pkgs.hermes-agent.override {
    extraDependencyGroups = [
      "anthropic"
      "messaging"
    ];
  };

  # The upstream HM module bakes HERMES_MANAGED=home-manager into the
  # desktop launcher via desktop.package.override { extraEnv = ...; }.
  # The env var wins over the ~/.hermes/.managed marker, so the desktop app
  # (and every terminal/CLI it spawns) stays read-only even though the
  # services and the marker say "false". Wrap override so our value lands
  # last in extraEnv.
  #
  # With backend.sessionTokenFile set, upstream also exports
  # HERMES_DESKTOP_REMOTE_URL=http://127.0.0.1:9119. The desktop treats that
  # env var as a launch-time override that beats the saved connection, so
  # Settings -> Gateways is locked ("set outside Hermes"). Hosts whose desktop
  # must reach ANOTHER host's gateway drop it (pinLocalBackend = false); the
  # token export that remains in extraRun is ignored without the URL.
  hermesDesktopBase = hermesPkg.hermesDesktop;
  hermesDesktopUnmanaged = hermesDesktopBase // {
    override = args: hermesDesktopBase.override (args // {
      extraEnv =
        (builtins.removeAttrs (args.extraEnv or { })
          (lib.optional (!cfgGrid.desktop.pinLocalBackend) "HERMES_DESKTOP_REMOTE_URL"))
        // { HERMES_MANAGED = "false"; };
    });
  };
in
{
  imports = [
    inputs.hermes-agent.homeManagerModules.default
    # Inline module: declaring `options` here would force the rest of this
    # file under `config = { ... }`.
    {
      options.the-grid.hermes.desktop.pinLocalBackend = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Pin the desktop app to this host's own backend via
          HERMES_DESKTOP_REMOTE_URL. Set false on hosts whose desktop connects
          to a remote gateway, so the saved connection in Settings -> Gateways
          applies.
        '';
      };
    }
  ];

  # ── CLI + Desktop app ─────────────────────────────────────────────────
  programs.hermes-agent = {
    enable = true;
    package = hermesPkg;
    desktop.enable = true;
    desktop.package = hermesDesktopUnmanaged;
  };

  # ── Services (gateway + web dashboard) ────────────────────────────────
  services.hermes-agent = {
    enable = true;

    # Config (model, TTS, STT, display, capabilities) is fully mutable —
    # managed via UI / Syncthing, not declared here. Only host-specific
    # settings that need NixOS store paths stay in Nix.
    settings = {
      terminal.shell = "/run/current-system/sw/bin/fish";
    };

    # Messaging gateway (Telegram, Discord, etc.) — starts as
    # systemd.user.services.hermes-agent
    gateway.enable = true;

    # Tools on the unit PATH (the module's default is only bash, coreutils
    # and git). systemd provides `systemd-run`: the gateway probes
    # `systemd-run --user --scope` via shutil.which() before spawning
    # Kanban workers / background processes into restart-safe scopes.
    # Without it on PATH the probe fails and every Kanban dispatch is
    # deferred with "cannot create restart-safe systemd scope".
    extraPackages = [ pkgs.systemd ];

    # Web dashboard + backend API (JSON-RPC/WS on :9119) — starts as
    # systemd.user.services.hermes-backend
    # "dashboard" = "serve" + browser admin panel on the same port.
    backend = {
      mode = "dashboard";
      host = "127.0.0.1";
      port = 9119;
      # Stable session token shared between the systemd backend and the
      # desktop app.  Without this, the backend mints a random token on
      # every restart and the desktop loses auth (401 loop on /api/*,
      # which breaks transcript hydration and makes messages vanish).
      # Self-provisioned: hermes-backend's ExecStartPre (below) mints the
      # file when missing, so wiping ~/.hermes no longer bricks the backend
      # (1300+ restart loop) and the desktop app ("REMOTE_TOKEN is not set").
      sessionTokenFile = desktopTokenFile;
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

  # ── Disable HERMES_MANAGED guard ──────────────────────────────────────
  # The upstream HM module sets HERMES_MANAGED=home-manager on every
  # systemd unit and writes a ~/.hermes/.managed marker file.  This blocks
  # ALL config writes — CLI `hermes config set`, the desktop UI toggles,
  # and save_config() in Python.  Since we deliberately manage config as
  # mutable state (UI + Syncthing), override the env var to "false" and
  # neuter the marker file so the application treats config as writable.
  #
  # Side effect: with the guard off, `hermes gateway install` is no longer
  # refused. It writes an unmanaged ~/.config/systemd/user/hermes-gateway.service
  # that races the Nix unit (only one gateway per host may run). Do not run
  # it; manage the gateway via systemctl --user {restart,status} hermes-agent.
  systemd.user.services.hermes-agent.Service.Environment =
    lib.mkAfter [ "HERMES_MANAGED=false" ];
  systemd.user.services.hermes-backend.Service.Environment =
    lib.mkAfter [
      "HERMES_MANAGED=false"

      # ── Browser tools in desktop sessions ─────────────────────────────
      # Desktop sessions run in-process inside hermes-backend, which does
      # NOT load profile .env files. Hermes' browser gate
      # (tools/browser_tool_install.py:_chromium_installed) needs
      # AGENT_BROWSER_EXECUTABLE_PATH or `chromium` on PATH; without it
      # every browser_* tool is silently dropped (cached until restart).
      # The Playwright-bundled Chromium cannot run on NixOS (libglib).
      "AGENT_BROWSER_EXECUTABLE_PATH=${pkgs.chromium}/bin/chromium"
      "AGENT_BROWSER_ARGS=--ozone-platform=wayland"

      # Headed Chromium needs the Wayland socket. The unit starts at boot
      # (linger) before Hyprland imports WAYLAND_DISPLAY into the systemd
      # user manager, and graphical-session.target is never reached here
      # (see polkit.nix), so ordering cannot fix it. Hyprland's socket is
      # stable at wayland-1 on this host.
      "WAYLAND_DISPLAY=wayland-1"
    ];

  # ── Session token self-provisioning ──────────────────────────────────
  # Runs before every backend start (including Restart= retries), so a
  # deleted token heals within one restart cycle. The upstream module
  # defines no ExecStartPre, so there is nothing to merge with.
  systemd.user.services.hermes-backend.Service.ExecStartPre = [
    "${ensureDesktopToken}"
  ];

  # Also at activation, so the desktop wrapper finds the token right after
  # a rebuild even if the backend has not restarted yet.
  home.activation.hermesDesktopToken =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${ensureDesktopToken}
    '';

  home.activation.hermesDisableManaged =
    lib.hm.dag.entryAfter [ "hermesAgentSetup" ] ''
      $DRY_RUN_CMD install -m 0600 /dev/stdin "$HOME/.hermes/.managed" <<< "false"
    '';
}
