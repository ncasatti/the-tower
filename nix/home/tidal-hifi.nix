# nix/home/tidal-hifi.nix
# tidal-hifi: package + enforced runtime settings, shared by every host.
#
# config.json is mutable electron-store state (tidal-hifi rewrites it from its
# settings UI and hot-reloads it), so it is NOT a home.file symlink. Instead,
# activation merges the enforced keys into it — on every switch and on boot
# (home-manager-<user>.service) — creating it if absent. Other keys stay
# app-owned.
#
# Enforced:
#   notifications = false — tidal-hifi's track-change Notify (with album art)
#   deadlocks against swaync's MPRIS widget over the session bus: each side
#   waits on the other until the 25 s D-Bus timeout, twice per track (~1 min
#   UI freeze + ANR dialogs). The swaync mpris widget already shows the track.

{ config, lib, pkgs, ... }:

let
  cfg = config.the-grid.tidal-hifi;
  enforced = builtins.toJSON cfg.settings;
in
{
  options.the-grid.tidal-hifi = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.tidal-hifi;
      description = "tidal-hifi package (hosts may pass a wrapped one).";
    };
    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { notifications = false; };
      description = "Keys merged into ~/.config/tidal-hifi/config.json on activation.";
    };
  };

  config = {
    home.packages = [ cfg.package ];

    home.activation.tidalHifiSettings = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      # Compute into a temp file; only `run cp` touches the real file, so
      # dry-run never writes. cp keeps the inode (tidal-hifi's watcher holds it).
      f="$HOME/.config/tidal-hifi/config.json"
      tmp="$(mktemp)"
      if [ -s "$f" ] && ${pkgs.jq}/bin/jq -e . "$f" >/dev/null 2>&1; then
        ${pkgs.jq}/bin/jq --tab --argjson e '${enforced}' '. * $e' "$f" > "$tmp"
      else
        ${pkgs.jq}/bin/jq --tab -n --argjson e '${enforced}' '$e' > "$tmp"
      fi
      if ! cmp -s "$tmp" "$f"; then
        run mkdir -p "$(dirname "$f")"
        run cp "$tmp" "$f"
      fi
      rm -f "$tmp"
    '';
  };
}
