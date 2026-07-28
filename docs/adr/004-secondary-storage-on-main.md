# ADR-004: Secondary HDD on `main` mounted as `/mnt/data` (SMR-aware ext4)

- Status: Accepted
- Date: 2026-07-28

## Context

The `main` host's LUKS-encrypted root (`sdc2`, ext4 directly on LUKS, no LVM
layer) is small (92G) and was at 96% used (4G free) when this decision was
made. Symptoms traced to:

- Long-lived `nix-profile` generations accumulating from `nixos-rebuild switch`
  over weeks of kernel upgrades.
- Build outputs and caches checked into `/nix/store` (small files, randomized
  write patterns).
- User data (`~/`) growing steadily (projects, downloads, scratch).

Available hardware: a 1 TB 2.5" SATA HDD (`WDC WD10SPZX-21Z10T0`,
/dev/sdb1) was physically attached but had no `fileSystems` entry in
`nix/hosts/main/`. It had been formatted as ext4 (label `Internal Disk`) by
the User and was sitting unmounted.

The disk's critical hardware property — **Shingled Magnetic Recording (SMR)** — was
uncovered during the SMART inspection. SMR drives pack tracks like roof shingles
for higher density, at the cost of write amplification: random writes and rewrites
force the controller to read-modify-write neighbouring tracks, and throughput
collapses relative to conventional magnetic recording (CMR).

- Sequential read: comparable to CMR (~110 MB/s on this drive).
- Sequential write: comparable to CMR.
- Random write / rewrite: **substantially worse** — observed cliff in real-world
  use when a write hits an already-populated shingled zone.

A read-only SMART pass on `sdb` confirmed the disk is otherwise healthy:
- `Reallocated_Sector_Ct`: 0
- `Current_Pending_Sector`: 0
- `Offline_Uncorrectable`: 0
- `UDMA_CRC_Error_Count`: 0 (cable healthy)
- `Power_On_Hours`: 18218 (~2 years)
- `Temperature_Celsius`: 28°C
- Model family: `Western Digital Blue Mobile (SMR)` (firmware 02.01A02).

## Decision

Mount `sdb1` as `/mnt/data` on `main` via a new host-scoped Nix module
`nix/hosts/main/storage.nix`, with a workload split that respects the SMR
penalty.

### Device reference

`/dev/disk/by-id/ata-WDC_WD10SPZX-21Z10T0_WD-WX61A773DN64-part1`. The by-id
symlink is keyed off the disk's burned-in serial, so the mount is hardware-stable
across reboot, cable reseating, and discovery-order changes. Plain `/dev/sdX`
naming was rejected for the same reason documented in this repo's Home Manager
and `fstab` practice: swapping USB sticks or flaky cables can remap `sdX` under
foot.

### Filesystem

ext4 (already in place; no reformat). Considered and rejected:

- **exFAT**: portable to Windows/Mac, but no journaling (data-loss risk on power
  loss), no POSIX permissions, slower on Linux because ext4 owns the journal
  write-amplification behaviour we're tuning. Would have required `exfatprogs`.
- **btrfs**: snapshots and CoW are attractive, but CoW amplifies SMR rewrites
  worse than ext4's journaling; the system already runs ext4 on LUKS, so the
  skill surface stays narrow.
- **xfs / f2fs / zfs**: no advantage for this use case; f2fs is for flash, zfs
  requires pool-level tuning.

### Mount options (`noatime`, `lazytime`, `commit=60`, `errors=remount-ro`)

Each option is justified below; all are tuned to minimise metadata writes
on SMR:

| Option              | Purpose                                                                                                  |
|---------------------|----------------------------------------------------------------------------------------------------------|
| `noatime`           | Skip `atime` updates on every read. Saves one metadata write per file access.                            |
| `lazytime`          | Batch `atime` updates — flush them only when something else triggers a metadata write.                   |
| `commit=60`         | Delay ext4 journal commits from the default 5 s to 60 s. Fewer, larger journal writes → less write amp.   |
| `errors=remount-ro` | On filesystem error, remount read-only. A bad block shouldn't take the system down.                      |

Explicitly **not** included:

- `discard`: TRIM is a no-op on most HDD controllers; SMR drives that support
  it (`TRIM Command: Available` per `smartctl -i`) don't benefit materially
  here. Adding it would also queue background TRIM work that competes with
  reads.
- `nofail`: the disk is internal, always-present, and SMR write cliffs are not
  the kind of failure `nofail` saves you from. Saves nothing on healthy
  hardware; loses the boot-time wait when the disk does fail.
- `data=writeback` / `data=journal`: writeback is faster but loses durability
  on crash; journal is the default. `commit=60` already gives most of the
  throughput upside without the durability regression.
- `barrier` / `nobarrier`: defaults are sane on ext4; touching them is a
  kernel-upgrade footgun.

### Workload split

`/mnt/data` is for:

- Photos, videos, music, static assets, ISOs.
- Old project archives (read-mostly).
- Occasional Android SDK installs (prebuilt tools, not source-tree builds).

`/mnt/data` is explicitly **not** for:

- Nix store (millions of small files; nuke and pave on `nixos-rebuild switch`).
- Build outputs (`target/`, `node_modules/`, `build/`, Go module caches).
- Docker volumes, database data, anything with intensive random writes.
- VM disk images that get rewritten in place.

This split keeps the SMR drive doing what it's good at (sequential reads and
large sequential writes of bulk media) and punts random-write workloads to the
SSD.

### Permissions

`flyn:users 0750` target via `systemd.tmpfiles.rules`
(`d /mnt/data 0750 flyn users - -`). On a fresh mountpoint, `d` type creates
the directory with that ownership and mode.

The current mounted root shows `flyn:users` ownership (correct) but `0755`
mode (cosmetic — `d` type does not retroactively change the mode of an
existing directory, and the underlying ext4 root inode keeps its format-time
`0755`). Functionally identical for `flyn`, who has rwx either way. If a
stricter `0750` mode is wanted in the future, switch the tmpfiles rule to
`e` type (which does set attributes on existing paths):

```diff
-  "d /mnt/data 0750 flyn users - -"
+  "e /mnt/data 0750 flyn users - -"
```

## Deferred — not in this commit

**Remote access to `main:/mnt/data` from `notebook`.** The User explicitly
deferred this for a future iteration. When it lands, the candidate architecture
is **SSHFS** (`pkgs.sshfs` plus a Nix-managed `fileSystems` entry on
`notebook`), because:

- SSH is already running on `main`; no new daemon.
- File managers on `notebook` (Dolphin, Thunar, Nautilus) all support
  `sftp://main/mnt/data` URLs natively — drag-and-drop works without
  sshfs being installed.
- Tailscale MagicDNS already provides a stable hostname for `main`.
- NFS / SMB would require new daemons on `main`, firewall changes, and gain
  nothing for the User's stated "occasional file push from notebook" workload.

When this is implemented: write a follow-up ADR (or extend this one) covering
SSH key distribution, mount options on the `notebook` side, and the SMR-aware
chmod/umask.

## Consequences

- **Pros**:
  - Host reclaims ~24 GB of already-used space from the LUKS root to free
    inode headroom; future `nix-collect-garbage -d` runs and old-generation
    removal recover another ~10–50 GB.
  - Read-mostly personal data lives on the HDD where it doesn't compete with
    system metadata.
  - SMR penalties are bounded by the workload split.
- **Cons**:
  - Two physical disks now contain user data; backup strategy should be
    reconsidered (the SMR disk is a *destination*, not a backup).
  - Build workloads are still cramped on the LUKS root — moving `/nix/store`
    here is **rejected** (see workload split); users with heavy compile cycles
    should consider Option 4 from the original Debian instead: a larger SSD on
    `main`, or a second SSD for `/nix/store` only.
  - The `0755` mode on the mounted root (rather than the `0750` the tmpfiles
    rule nominally specifies) is a minor inconsistency. Cosmetic; single-user
    system.
- **Reversibility**: trivial — `fileSystems` entry can be removed and the
  mount goes away; no data on `sdb1` is touched.
