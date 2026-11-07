# nix/home/keyd.nix
# Per-application keyd bindings via keyd-application-mapper.
#
# The mapper watches the focused window (Hyprland exposes
# zwlr_foreign_toplevel_manager_v1) and applies the matching section of
# ~/.config/keyd/app.conf through `keyd bind` on the keyd socket; on focus
# loss it resets to /etc/keyd/default.conf. Requires the user in group
# `keyd` (modules/services.nix).
#
# app.conf is an out-of-store symlink to the repo so it can be iterated on
# without a rebuild:
#   $EDITOR keyd/app.conf
#   systemctl --user restart keyd-application-mapper

{ config, pkgs, ... }:

{
  # CLI on PATH: `keyd bind/reload/monitor`, `keyd-application-mapper -v`.
  home.packages = [ pkgs.keyd ];

  home.file.".config/keyd/app.conf".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.the-grid/the-tower/keyd/app.conf";

  systemd.user.services.keyd-application-mapper = {
    Unit = {
      Description = "keyd per-application key bindings";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.keyd}/bin/keyd-application-mapper";
      # The mapper shells out to `keyd bind`; user units have no keyd on PATH.
      Environment = [ "PATH=${pkgs.keyd}/bin" ];
      Restart = "on-failure";
      RestartSec = "3s";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
