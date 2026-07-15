# nix/modules/metabase.nix
# Metabase BI — on-demand only. Declared but NOT autostarted.
#
# Usage:
#   sudo systemctl start metabase      # launch when needed
#   sudo systemctl stop metabase       # free the JVM RAM
#   xdg-open http://127.0.0.1:3000     # web UI (first run: create admin)
#
# App DB (Metabase's own metadata: users, dashboards, saved data-source
# connections) is the default H2 file under /var/lib/metabase. Back that
# directory up — your dashboards live there.
#
# Data sources (work / finances / agents DBs) are added at runtime from the
# web UI, NOT here. Bundled JDBC drivers cover Postgres, MySQL, SQLite and
# MongoDB out of the box.

{ lib, ... }:

{
  services.metabase = {
    enable = true;
    listen = {
      ip   = "127.0.0.1";  # local-only; reach via SSH tunnel if remote
      port = 3000;
    };
    openFirewall = false;
  };

  # On-demand: declared but dormant. No boot autostart.
  # Launch manually with `systemctl start metabase`.
  systemd.services.metabase.wantedBy = lib.mkForce [ ];

  # Force te service to use main user
  systemd.services.metabase.serviceConfig.User = "flyn";
}
