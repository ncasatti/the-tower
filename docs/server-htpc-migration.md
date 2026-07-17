# SDD — Server → HTPC + Audio Workstation

**Status:** Approved · **Target:** `nixosConfigurations.server` · **Date:** 2026-07-01

## 1. Intent

Re-role the `server` host (a rack-mounted notebook) from a purely headless DNS+VPN
infrastructure node into that role **plus** a Home Theater PC and an audio
workstation, controlled remotely over the VPN.

The box is physically wired to a **TV (HDMI)** and a **music system** (switchable
between HDMI, Bluetooth, and analog jack). There is **no physical keyboard/mouse** —
all interaction is remote.

### Use cases
- Play music (Tidal) and video on the TV + stereo.
- Control the desktop remotely (not just SSH) via a Hyprland session.
- Run Carla + a USB audio interface for instruments/effects (local low-latency DSP).

## 2. Key architectural insight

**The TV *is* the monitor.** This is an HTPC, not a headless-virtual-display setup.
Hyprland renders to the physical HDMI output; media plays on real hardware.
`hypr-rdp` is only a **remote control** (it captures the TV output and injects
keyboard/mouse) — it is the control plane, not the media path.

Consequences:
- No virtual headless output is required (the TV provides the output).
- Instrument monitoring latency is **local** (USB → PipeWire/JACK → Carla → stereo);
  RDP latency does **not** affect it.
- Over RDP you see enough to *drive* playback; you do not watch HD video on the client.

## 3. Facts verified against the repo / nixpkgs

| Fact | Value | Source |
|------|-------|--------|
| Hyprland version | 0.54.3 (meets hypr-rdp ≥0.54) | `nix eval nixpkgs#hyprland.version` |
| hypr-rdp | flake `github:MuNeNICK/hypr-rdp`, `packages.default` v0.1.3 | `nix flake show` |
| tidal-hifi | 6.3.1 in nixpkgs | `nix eval` |
| wiremix / carla | 0.10.0 / 2.5.10 in nixpkgs, already in `packages/audio.nix` | `nix eval` |
| PipeWire + JACK + rtkit | already built in `modules/audio.nix` | file |
| Bluetooth + `hardware.graphics` | already enabled in `modules/services.nix` (imported by server) | file |
| SSH | enabled in `modules/services.nix` → recovery path | file |
| Firewall | `tailscale0` is a `trustedInterface` in `modules/tailscale.nix` | file |

## 4. Design

### 4.1 System level (`nix/hosts/server/`)
- **Import `modules/audio.nix`** — PipeWire + JACK + rtkit + realtime PAM limits.
- **New `hosts/server/htpc.nix`:**
  - `programs.hyprland` + `programs.dconf` + `programs.nix-ld` (parity with main).
  - **`greetd` autologin** → launches Hyprland as `flyn` on boot and after logout
    (no physical keyboard; physical access is trusted, remote is Tailscale-gated).
  - **Intel VA-API**: `hardware.graphics.extraPackages = [ intel-media-driver ]` +
    `LIBVA_DRIVER_NAME = "iHD"`. Fallback to `intel-vaapi-driver`/`i965` if the
    iGPU is pre-Broadwell.
  - `services.xserver.xkb` colemak (parity with main).
- **`default.nix`**: add `audio` + `video` groups to `flyn`; import `audio.nix` and
  `htpc.nix`; drop the stale "no GUI / pure infrastructure" header.

### 4.2 hypr-rdp (remote control)
- Flake input `github:MuNeNICK/hypr-rdp` → overlay line (same pattern as `zen-browser`).
- Launched from the Hyprland session via `exec-once = hypr-rdp` (inherits the session's
  Wayland + PipeWire environment — simplest reliable launch). Auto-restart via a
  systemd user service is a hardening follow-up.
- **Credentials NEVER go in the flake/Nix store** (world-readable). They live in
  `~/.config/hypr-rdp/config.toml`, created out-of-band with `chmod 600`.
- **Security posture:** bind `0.0.0.0:3389`; port 3389 is reachable **only** over
  Tailscale because `tailscale0` is trusted and 3389 is never in `allowedTCPPorts`.
  Verify exact TOML keys against `hypr-rdp --help` on the box.
- In `config.toml`: point `output` at the TV (`HDMI-A-1`), and **disable RDPSND audio
  forwarding** so media audio stays on the local sink (the stereo), not the client.

### 4.3 Home Manager (`nix/hosts/server/home.nix`)
- Import home modules: `gtk`, `xdg`, `polkit` (+ existing `dotfiles`, `git`, `tmux`).
- Import package sets: `wayland`, `appearance`, `audio` (Carla/wiremix/plugins arrive here).
- Add packages: `kitty`, `zen-browser`, `tidal-hifi`.
- `mkForce` the per-host `~/.config/hypr-host.conf` (see 4.4).

### 4.4 Hyprland per-host divergence (the tricky bit)
`hypr/` is a single shared store-copy; `monitors.conf`/`startup.conf` are hardcoded
for main. To diverge without duplicating the config:
- Append one line to shared `hypr/hyprland.conf`: `source = $HOME/.config/hypr-host.conf`
  (sourced **last** → overrides `monitors.conf`).
- Shared `nix/home/dotfiles.nix` provides an **empty default** `~/.config/hypr-host.conf`
  (no behavior change for main/notebook).
- `server/home.nix` overrides it with `lib.mkForce`: disable `DP-1`, place `HDMI-A-1`
  at `0x0`, and `exec-once = hypr-rdp`.
- Result: the server reuses the entire main look/feel; only the monitor + RDP launch differ.

## 5. Known warts (v1, cosmetic / follow-up)
- Shared `startup.conf` autostarts `obsidian`, `ags`, `cliphist` and reloads the `hy3`
  plugin. On the server these commands are absent → they log errors and no-op (Hyprland
  falls back to dwindle if `hy3` isn't loaded). Harmless; trim later if desired.
- `LIBVA_DRIVER_NAME` via `environment.sessionVariables` — if it does not reach the
  greetd session, set it in `hypr/configs/env.conf` instead.
- **TV-off resilience**: if the TV drops the HDMI link, Hyprland may lose its only
  output. Fallback: create a `HEADLESS-1` virtual output. Deferred until observed.
- hypr-rdp is young (v0.1.3) — pin/watch the flake input.

## 6. Recovery
SSH over Tailscale is the safety net. If the GUI fails to come up, the box is still
reachable headless for rollback (`nixos-rebuild switch --rollback`).

## 7. Out of scope (deliberately)
- `musnix` / realtime kernel — `rtkit` + PAM limits suffice (same as main).
- Splitting the HTPC into a separate host — kept on one box (homelab pragmatism).
