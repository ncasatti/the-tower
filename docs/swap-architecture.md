# Swap Architecture

- Status: Active since 2026-07-30
- Covers: `main` and `server` (both with encrypted root + dedicated swap partition)
- See also: `boot-lockout-postmortem.md` for the root-cause analysis that led here

---

## TL;DR

Each host with a swap partition now uses **two layers**:

1. **zramSwap** — compressed RAM-backed swap, zstd, high priority. Hot path.
2. **randomEncryption** — the dedicated swap partition is opened with a per-boot random key, no passphrase, no static LUKS header. Low priority, overflow only.

This replaced a single static LUKS swap that was a mandatory stage 1 dependency. The original design failed silently on every boot (90s timeout for a mapper that was never opened); even after a manual fix that made it work, it kept the bomb class. This document covers what the system does now, why, and how to reproduce it on a fresh install.

---

## Current state

### `main` — 15 GiB RAM, dedicated swap partition on `sda3`

| Component | Size | Priority | Mechanism |
|---|---|---|---|
| `zram0` | 7.8 GiB raw (~22.5 GiB compressed @ zstd) | 5 (high) | `systemd-zram-setup@zram0.service` |
| `dm-1` (randomEncryption) | 17.1 GiB | -2 (low) | `mkswap-dev-disk-byx2dpartuuid-...service` runs `cryptsetup plainOpen -d /dev/urandom --allow-discards` then `mkswap` |

**Total effective swap: ~39 GiB.** RAM available jumped from 2.7 GiB to 8.4 GiB after the swap layer came up.

### `server` — 3.7 GiB RAM, dedicated swap partition on `sda3`

| Component | Size | Priority | Mechanism |
|---|---|---|---|
| `zram0` | 1.85 GiB raw (~5.5 GiB compressed @ zstd) | 5 (high) | `systemd-zram-setup@zram0.service` |
| `dm-1` (randomEncryption) | 8.2 GiB | -2 (low) | `mkswap-dev-disk-byx2dpartuuid-...service` |

**Total effective swap: ~13.7 GiB.** RAM available jumped from 881 MiB to ~2.7 GiB. zram is critical here — without it, the 3.7 GiB physical memory would OOM under any pressure.

### Generated systemd units

After `nixos-rebuild switch`, the new generation contains:

- `systemd-zram-setup@.service.d/overrides.conf` — configures zram algorithm and size
- `mkswap-dev-disk-byx2dpartuuid-...service` — opens the partition with `cryptsetup plainOpen -d /dev/urandom --allow-discards`, then runs `mkswap`
- `dev-mapper-dev-disk-byx2dpartuuid-...swap.{requires,wants}` — swap.target dependencies

There is **no `boot.initrd.luks.devices` entry for the swap partition** in the initrd. The partition is opened entirely in stage 2 by a mkswap service. This is the architectural change that closes the original boot-lockout class.

To inspect the generated mkswap script after a rebuild:

```bash
cat /nix/store/*-unit-script-mkswap-dev-disk-byx2dpartuuid-*/bin/mkswap-*-start
```

It contains exactly two lines: `cryptsetup plainOpen ... && mkswap ...`. No header, no passphrase, no keyfile.

---

## Why — the root cause from a fresh install

### What the NixOS installer does

`nixos-generate-config` produces `hardware-configuration.nix` based on detected hardware. For a system with LUKS-encrypted root + a separate LUKS swap partition, the file looks like this:

```nix
# Root LUKS: installer generates the initrd entry automatically
boot.initrd.luks.devices."luks-<ROOT-UUID>" = {
  device = "/dev/disk/by-uuid/...";
  # ... options ...
};

fileSystems."/" = {
  device = "/dev/mapper/luks-<ROOT-UUID>";
  fsType = "ext4";
  options = [ "noatime" "nodiratime" ];
};

# Swap LUKS: only the mapper reference, NO initrd entry
swapDevices = [ { device = "/dev/mapper/luks-<SWAP-UUID>"; } ];
# ⚠️ MISSING: boot.initrd.luks.devices."luks-<SWAP-UUID>"
```

The installer auto-generates `boot.initrd.luks.devices` for filesystems declared in `fileSystems` with `neededForBoot = true`. Root qualifies; swap does not — it lives in `swapDevices`, not in `fileSystems`. The installer has no rule that says "also open swap LUKS in initrd", so the entry is missing.

### The silent failure at every boot

1. Initrd opens root LUKS, mounts `/`, `switch_root` to stage 2.
2. Stage 2 systemd activates `swap.target`.
3. `swap.target` requires `/dev/mapper/luks-<SWAP-UUID>`.
4. The mapper doesn't exist — nothing in initrd opened the swap LUKS.
5. `swap.target` waits 90 seconds, then fails with `result 'dependency'`.
6. Boot continues without swap.

The system works, but takes 90 seconds longer and runs without swap. The 90-second timeout was the only visible symptom; it stays invisible until memory pressure surfaces it.

### Why the fix evolved

**Initial fix (commit `38cb524`):** added `nix/hosts/main/swap.nix` declaring `boot.initrd.luks.devices."luks-<swap-uuid>"` manually. The initrd opened the swap LUKS and the system got swap. Worked, but kept the bomb class:

- The swap remained a mandatory stage 1 dependency.
- A future initrd LUKS open failure on the swap would drag the boot into `emergency.target`.
- On `server` (headless), that would be unrecoverable — no console, no boot menu.

**Current design (commits `7ddcf3c`, `37a0553`):** removed the initrd entry entirely. The swap is opened in stage 2 by `randomEncryption`, which uses `cryptsetup plainOpen -d /dev/urandom`. The old LUKS header is overwritten by the first `mkswap`. No key material at rest, no passphrase prompt, forward secrecy per boot.

A shared assertion (`nix/modules/boot-invariants.nix`) ensures a future `lib.mkForce` on `fileSystems.<x>.options` cannot reintroduce the original brick — `nix flake check` catches it at evaluation time.

---

## Why two layers (zram + randomEncryption) instead of one

| Concern | zram alone | randomEncryption alone | Both |
|---|---|---|---|
| Speed | RAM-speed | Disk-speed (5400 RPM SMR on `main`) | RAM-speed hot, disk-speed overflow |
| Capacity | Limited to ~50% of RAM | Full partition size | RAM + disk |
| Failure mode | OOM if pressure exceeds zram | Disk failure kills swap | Either layer can fail without losing all swap |
| Encryption | None (RAM is volatile) | Plain dm-crypt with per-boot random key | Both addressed |
| Stage 1 dependency | No (kernel-level) | No (stage 2) | No |
| Forward secrecy | N/A (RAM) | Yes (new key each boot) | Yes |

For `server` specifically (3.7 GiB RAM, 881 MiB available observed on multiple boots), zram is mandatory — without it, any pressure triggers the OOM killer. The disk swap alone is too slow to absorb burst pressure at 5400 RPM.

---

## How to install a fresh host (reproducibility)

### Same hardware as an existing host (e.g. fresh `main`)

```bash
# 1. Boot the NixOS installer ISO (Flakes enabled)
# 2. Partition, set up LUKS, mount filesystems via the installer GUI
#    (or manually for scripted installs)
# 3. Install base system, reboot

# 4. In the new system:
nix-env -iA nixos.git
git clone https://github.com/ncasatti/the-tower /etc/nixos/the-tower

# 5. Replace the installer's hardware-configuration.nix with the repo's
sudo cp /etc/nixos/hardware-configuration.nix \
        /etc/nixos/the-tower/nix/hosts/main/hardware-configuration.nix

# 6. Apply
cd /etc/nixos/the-tower
sudo nixos-rebuild switch --flake .#main

# 7. Reboot into the declarative system
```

The committed `hardware-configuration.nix` for `main` references the LUKS container UUIDs and partition UUIDs of the specific machine it was generated for. If the fresh install is on the same hardware, those UUIDs will match. If not, the installer's hardware scan will produce a different `hardware-configuration.nix` that needs to be committed and adjusted.

### Different hardware (new host)

```bash
# 1-4. Same as above

# 5. Generate a fresh hardware-configuration.nix
nixos-generate-config --show-hardware-config \
  > /etc/nixos/the-tower/nix/hosts/<new-host>/hardware-configuration.nix

# 6. Copy a similar host's default.nix as a template and adjust:
#      notebook   → laptop
#      main       → desktop with NVIDIA
#      server     → headless

# 7. Add the host to flake.nix (nixosConfigurations)

# 8. Apply
sudo nixos-rebuild switch --flake .#<new-host>
```

### What the repo guarantees vs what it does not

**Guaranteed by the repo (any host with the same hardware profile):**

- Same packages, services, user config
- Same network (Tailscale), same firewall, same SSH config
- Same modular structure (`nix/modules/` shared across hosts)
- Same design decisions: zram + randomEncryption, `noauto`+`automount` for `/mnt/data`, boot-invariants assertion, `configurationLimit = 5`

**NOT guaranteed by the repo (must come from the install itself):**

- LUKS keys / passphrases — generated at install time, hardware-specific, not in the repo
- Syncthing device IDs — generated on first start of each peer, rotate per install
- Tailscale auth key — needs to come from outside the repo (currently via interactive login; `agenix` is dormant in `nix/home/secrets.nix`)
- The `hardware-configuration.nix` UUIDs — change with each install

### Future architecture (not yet implemented)

For `nixos-rebuild switch --flake github://ncasatti/the-tower#main` to work on a fresh machine without manual intervention:

1. **Re-activate `agenix`** (`nix/home/secrets.nix`) — encrypt secrets with a host key, commit them to the repo. Currently dormant.
2. **Bootstrap script** in `nix/hosts/<host>/bootstrap.nix` — detect a fresh install (no host key present), generate secrets, register peers.
3. **Disko-style declarative partitioning** — replace the installer GUI step with a Nix module that creates partitions and LUKS containers from a declarative spec.
4. **First-boot Syncthing device-ID registration** — automate the 4-step rollout documented in `nix/modules/syncthing.nix`.

Until those land, fresh installs require manual intervention at the LUKS, secrets, and device-ID steps. The repo gives you **design portability**, not full automation.

---

## Related

- `boot-lockout-postmortem.md` — full postmortem of the swap LUKS initrd issue and the commits that fixed it
- `docs/adr/004-secondary-storage-on-main.md` — ADR for the `/mnt/data` mount (uses `noauto`+`x-systemd.automount` to avoid the same bomb class for stage 2)
- `nix/modules/boot-invariants.nix` — assertion that catches the original bug class at `nix flake check` time
- `nix/hosts/{main,server}/hardware-configuration.nix` — where the swap partition is declared
