# nix/hosts/main/storage.nix
# Mount the secondary HDD (sdb) as /mnt/data for personal storage.
# Disk: WDC WD10SPZX-21Z10T0 (SMR, 5400 RPM, Advanced Format 4Kn).
# Use for: photos, videos, static files, occasional Android SDK, old projects.
# Do NOT use for: Nix store, builds, or anything with heavy random writes.

{ config, pkgs, lib, ... }:

{
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-id/ata-WDC_WD10SPZX-21Z10T0_WD-WX61A773DN64-part1";
    fsType = "ext4";
    # noauto + x-systemd.automount: the disk is NOT mounted at boot. systemd
    # sets up an automount trigger that mounts on first access to /mnt/data,
    # and unmounts after 10 minutes idle. The HDD stays spun down between
    # sessions (5400 RPM SMR — quieter, cooler, less wear). A disk failure
    # cannot touch local-fs.target. `nofail` is implied by `noauto`.
    #
    # Verified safe: nothing in the repo (services, syncthing, etc.) accesses
    # /mnt/data at boot. The three syncthing folders live in /home/flyn/.
    #
    # See boot-lockout-postmortem.md §9.1 + §10.2.
    options = [
      "noauto"                       # Don't mount at boot.
      "x-systemd.automount"          # Mount on first access.
      "x-systemd.idle-timeout=600"   # Auto-unmount after 10 min idle.
      "noatime"                      # Skip access time updates on reads.
      "lazytime"                     # Batch atime updates with other writes.
      "commit=60"                    # Delay journal commits (default is 5s).
      "errors=remount-ro"            # Remount read-only on filesystem errors.
    ];
  };

  # Mountpoint ownership and permissions: flyn:users 0750.
  systemd.tmpfiles.rules = [
    "d /mnt/data 0750 flyn users - -"
  ];
}
