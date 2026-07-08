# nix/modules/ai.nix
# AI-specific Home Manager wiring: LiteLLM proxy (MiniMax-M3 / M2.7-highspeed),
# gbrain activation bootstrap (config dir + secrets.env placeholder + ollama model pull),
# and the litellm systemd --user service.
# Auto-managed by home-manager; do not hand-edit ~/.config/litellm/config.yaml.

{ config, pkgs, lib, ... }:

{
  # --- LITELLM PROXY CONFIG (declarative) ---
  # This file is auto-managed by home-manager. Edit this Nix module instead.
  home.file.".config/litellm/config.yaml".text = ''
    model_list:
      - model_name: minimax-m3
        litellm_params:
          model: anthropic/MiniMax-M3
          api_key: os.environ/MINIMAX_API_KEY
          api_base: https://api.minimaxi.io/anthropic
      - model_name: minimax-fast
        litellm_params:
          model: anthropic/MiniMax-M2.7-highspeed
          api_key: os.environ/MINIMAX_API_KEY
          api_base: https://api.minimaxi.io/anthropic

    litellm_settings:
      drop_params: true
  '';

  # --- GBRAIN ACTIVATION BOOTSTRAP ---
  # Creates the gbrain config dir, ensures secrets.env exists (chmod 600),
  # and pre-pulls the ollama embedding model. Idempotent.
  home.activation.bootstrap-gbrain = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/gbrain"
    chmod 700 "$HOME/.config/gbrain"
    [ -f "$HOME/.config/gbrain/secrets.env" ] || { umask 077; : > "$HOME/.config/gbrain/secrets.env"; }
    if command -v ollama >/dev/null 2>&1; then
      ollama pull nomic-embed-text 2>/dev/null || true
    fi
  '';

  # --- LITELLM SYSTEMD --USER SERVICE ---
  # Note: home-manager's systemd.user.services.<name> uses the systemd unit
  # schema (Unit / Service / Install submodules), NOT flat keys.
  systemd.user.services.litellm = {
    Unit = {
      Description = "LiteLLM proxy: MiniMax-M3 and MiniMax-M2.7-highspeed";
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.litellm}/bin/litellm --config %h/.config/litellm/config.yaml --host 127.0.0.1 --port 4000";
      EnvironmentFile = "%h/.config/gbrain/secrets.env";
      Restart = "on-failure";
      RestartSec = "5s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
