# nix/modules/kanata.nix
# Cross-platform kanata keyboard remapper.
#
# Opt-in per host via `the-grid.kanata.enable = true;`.
# The config is shared at `kanata/kanata.kbd` (repo root), so it can later
# be synchronized with Windows without duplicating logic.

{ config, lib, ... }:

{
  options.the-grid.kanata = {
    enable = lib.mkEnableOption "kanata keyboard remapper";
  };

  config = lib.mkIf config.the-grid.kanata.enable {
    services.kanata = {
      enable = true;
      keyboards.default = {
        # Reference the shared config at repo root.
        configFile = ../../kanata/kanata.kbd;
      };
    };
  };
}
