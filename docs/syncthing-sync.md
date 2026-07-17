# Syncthing — Multi-Device Folder Sync

## Goal

Replace the manual, unidirectional `clingy-sync` (rclone → Google Drive) with
continuous P2P bidirectional sync across the three hosts. No cloud storage
involved; data lives only on the peers.

## Design

- **Module**: `nix/modules/syncthing.nix`, imported by all three hosts
  (same pattern as `fish.nix`).
- **Topology**: full mesh. The always-on `server` host is the de-facto
  permanent seed — any machine syncs against it even when the others are off.
- **Transport**: Tailscale MagicDNS names as static device addresses
  (`tcp://<hostname>:22000`) with `dynamic` (local discovery) as fallback,
  so sync works on any network. `openDefaultPorts` opens 22000/tcp+udp and
  21027/udp; `tailscale0` is already a trusted interface.
- **Declarative config**: devices and folders live in `settings.*` and
  override GUI edits on rebuild. GUI (localhost:8384) is for monitoring.
- **Service user**: runs as `flyn`, state in `~/.local/state/syncthing`.

## Folders

| Folder ID      | Path                             | Devices | Versioning        |
|----------------|----------------------------------|---------|-------------------|
| `zettelkasten` | `~/.the-grid/zettelkasten`       | all     | trashcan, 14 days |

Add new folders by extending `settings.folders` in the module. Per-folder
ignore patterns go in `<folder>/.stignore` (gitignore-like syntax).

## Rollout (two stages)

Device IDs are derived from each host's TLS certificate, generated on the
service's **first start** — they cannot be pre-declared. Hosts with `id = null`
in the module's `grid` attrset are skipped, keeping the config valid mid-rollout.

1. **Stage 1** — rebuild each host with the module enabled. On each host read
   the generated ID:
   ```bash
   journalctl -u syncthing | grep "My ID"
   ```
2. **Stage 2** — paste the three IDs into `grid` in
   `nix/modules/syncthing.nix`, rebuild all hosts. Peers connect and the
   mesh is live.

## Non-goals / caveats

- **Syncthing is not backup**: local deletions propagate to all peers.
  Trashcan versioning only retains files deleted/overwritten *by remote
  peers*. The existing rclone → Drive flow stays as the backup layer
  (candidate: periodic `rclone sync` timer on `server`).
- **Conflicts are not merged**: concurrent edits on two offline machines
  produce `.sync-conflict-*` files for manual resolution.
