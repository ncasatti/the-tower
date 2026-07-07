# nix/modules/syncthing.nix
# Shared Syncthing configuration across all hosts (system scope).
#
# Topology: every host is a peer; the always-on `server` host acts as the
# permanent seed so any machine can sync even when the others are offline.
# Peers reach each other over Tailscale (static address below) with local
# discovery as fallback, so sync works on any network.
#
# Device IDs are derived from each host's TLS certificate, generated on the
# service's FIRST start — they cannot be pre-declared. Rollout per host:
#   1. Rebuild the host with this module (id may still be null here).
#   2. Read its ID:  syncthing --device-id --home=/home/flyn/.local/state/syncthing/.config/syncthing
#      (or: journalctl -u syncthing | grep "My ID")
#   3. Paste the ID into `grid` below and rebuild all hosts.
# Hosts with a null id are skipped, so the config stays valid mid-rollout.

{ config, lib, ... }:

let
  grid = {
    the-grid = {
      id = "G54WKJS-KVGODB6-ZWYQWMS-GD6RO3N-X3P5QRX-ZFC43OB-D26JBE2-ML2DPA4";
    };
    the-grid-server = {
      id = "EA3U4EI-ZNLSIX5-7UILELT-5LKJ4HK-PEAWSXX-V7T6Y5H-JZOCV5X-765SYAQ";
    };
    the-grid-notebook = {
      id = null;
    };
  };

  self = config.networking.hostName;
  peers = lib.filterAttrs (name: dev: name != self && dev.id != null) grid;
in
{
  services.syncthing = {
    enable = true;
    user = "flyn";
    group = "users";

    # Keep state in the user's home; default /var/lib/syncthing is root-owned.
    dataDir = "/home/flyn/.local/state/syncthing";

    # 22000/tcp+udp (transfers) and 21027/udp (local discovery).
    openDefaultPorts = true;

    # settings.devices/folders are authoritative: GUI edits to them are
    # reverted on rebuild (overrideDevices/overrideFolders default to true).
    settings = {
      options.urAccepted = -1; # opt out of usage reporting

      devices = lib.mapAttrs (name: dev: {
        id = dev.id;
        # Tailscale MagicDNS name first, discovery as fallback.
        addresses = [
          "tcp://${name}:22000"
          "dynamic"
        ];
      }) peers;

      folders = {
        privateConfig = {
          path = "/home/flyn/.the-grid/.private";
          devices = lib.attrNames peers;
          versioning = {
            # Safety net: deletes/overwrites RECEIVED from a peer are kept for
            # 14 days under .stversions/ instead of vanishing immediately.
            type = "trashcan";
            params.cleanoutDays = "14";
          };
        };
      };
    };
  };
}
