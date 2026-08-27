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
      id = "KXCDLUP-QP52DDO-QJYUFCJ-4Y4CAYH-YN2FU5Z-AY23NVL-QNI2SFE-GJYZQQJ";
    };
    the-grid-server = {
      id = "EA3U4EI-ZNLSIX5-7UILELT-5LKJ4HK-PEAWSXX-V7T6Y5H-JZOCV5X-765SYAQ";
    };
    the-grid-notebook = {
      id = "XXGQNZT-YYMWDPU-7WFQO5I-7RKA5FZ-PQYCT6C-ADEXIU4-GSZWJMG-G4CLTQ2";
    };
    # NixOS-WSL peer. id is generated on the first `nixos-rebuild` INSIDE the
    # distro (null until then → skipped by the `peers` filter). Then paste it
    # here and rebuild all hosts. See docs/nixos-wsl.md.
    the-grid-wsl = {
      id = "CRZHJQ2-LZNOM4F-ZIEPHWJ-BAQVTUF-GC2KSHA-62TPS42-NL25SRM-BVJR3AW";
    };
    # Mobile peer (Syncthing-Fork). Key matches its Tailscale MagicDNS name so
    # the tcp:// address resolves. Only accepts `zettelkasten` on the phone.
    motorola-edge-70-fusion = {
      id = "ZT6QWVS-KOJ2XGL-MEB2ALF-VT6ASTI-PFAID2M-UITRIEW-6ZBOTFS-WHF7IQG";
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

    # Tolerate a config schema newer than the pinned binary. Syncthing writes
    # a bumped schema when a newer nixpkgs build runs; a later downgrade (flake
    # update rollback / GC) would otherwise crash-loop `initialize config`
    # (start-limit-hit). Vendor-sanctioned post-downgrade flag; the declarative
    # devices/folders are re-asserted via the init API on every boot regardless.
    extraFlags = [ "--allow-newer-config" ];

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

        # Obsidian vault. Replaces Obsidian Sync. Per-device ignore patterns
        # (Obsidian layout/cache, trash, versions) live in the folder's
        # .stignore — NOT synced by Syncthing, so it must exist on every peer.
        zettelkasten = {
          path = "/home/flyn/.the-grid/zettelkasten";
          devices = lib.attrNames peers;
          versioning = {
            type = "trashcan";
            params.cleanoutDays = "14";
          };
        };

        grid-vault = {
          path = "/home/flyn/.local/share/the-grid/";
          devices = lib.attrNames peers;
          versioning = {
            type = "trashcan";
            params.cleanoutDays = "14";
          };
        };

        books = {
          path = "/home/flyn/.the-grid/books";
          devices = lib.attrNames peers;
          versioning = {
            type = "trashcan";
            params.cleanoutDays = "14";
          };
        };
      };
    };
  };
}
