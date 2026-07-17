# NixOS-WSL — Fourth Grid Host

## Goal

Run the Grid's Neovim stack and the Obsidian `zettelkasten` vault from inside a
Windows machine, declaratively, as a full NixOS running under WSL2. The vault
lands on **native ext4** and joins the existing Syncthing mesh as a fourth peer
(`the-grid-wsl`), so edits propagate to/from `main`, `server`, `notebook` and
the phone.

## Why NixOS-WSL (not Nix-on-Ubuntu)

The Grid is a single flake that governs every machine. NixOS-WSL keeps that
invariant: WSL becomes a fourth `nixosConfiguration`, reuses the same
`home/` and `packages/` modules (Neovim comes out **identical**), and runs the
same `modules/syncthing.nix` so mesh membership is free. A package-manager Nix
on Ubuntu would fork the model into a second-class host.

## Design

- **Input**: `nixos-wsl` (`github:nix-community/NixOS-WSL`), `nixpkgs.follows`.
- **Config**: `nixosConfigurations."wsl"` in `flake.nix`, adding
  `inputs.nixos-wsl.nixosModules.default` to the module list.
- **Host dir**: `nix/hosts/wsl/{default.nix,home.nix}` — a **slim** host.
  WSL is headless; GUI apps render through WSLg.
- **hostName** = `the-grid-wsl`, which MUST equal the Tailscale MagicDNS name
  so peers resolve `tcp://the-grid-wsl:22000` (see `nix/modules/syncthing.nix`).

### What the slim host includes / excludes

| Layer  | IN                                                              | OUT                                                                                  |
|--------|----------------------------------------------------------------|-------------------------------------------------------------------------------------|
| System | `nix`, `security`, `tailscale`, `fish`, `syncthing`; `wsl.enable`; `hardware.graphics` (WSLg libGL) | hyprland, nvidia, audio, kanata, wifi-no-powersave, bootloader, `hardware-configuration.nix` (WSL provides its own) |
| Home   | `dotfiles`, `git`, `tmux`; `cli`, `dev`, `ai`, `nvim`, `languages`; `obsidian` | `activation` (declares the Hyprland hy3 plugin — dead GUI dep), `wayland`, `appearance`, `audio`, `latex`, `sioyek`, `polkit` |

`dotfiles.nix` is imported whole: its Wayland symlinks (hypr/waybar/rofi/…) are
inert on WSL, but it delivers the nvim/fish/yazi/starship configs.

## Obsidian under WSLg

Obsidian is an Electron GUI. WSLg (Win11) exposes Wayland + X11 sockets and a
GPU device; `hardware.graphics.enable = true` provides the mesa `libGL` Electron
needs (llvmpipe software rendering is fine). The vault path
`~/.the-grid/zettelkasten` lives on ext4, so Obsidian and nvim both read it at
native speed — **never** put the vault under `/mnt/c` (9P/DrvFs: slow,
case-insensitive, no usable inotify — breaks Syncthing and git).

If Obsidian renders oddly, force the Electron platform:
`ELECTRON_OZONE_PLATFORM_HINT=wayland` (falls back to XWayland otherwise).

## Rollout (two stages)

Device IDs are generated on the service's first start — they can't be
pre-declared. `the-grid-wsl` sits in the module's `grid` attrset with `id = null`
(skipped by the `peers` filter) until then.

1. **Stage 1 — on the Windows box (yours):**
   - Import the NixOS-WSL tarball as a distro (`wsl --import`), launch it.
   - Point it at this flake and rebuild:
     `sudo nixos-rebuild switch --flake .#wsl`
   - Bring up the VPN: `sudo tailscale up` (hostname must become
     `the-grid-wsl` on the tailnet).
   - Read the generated Syncthing ID:
     `journalctl -u syncthing | grep "My ID"`
2. **Stage 2 — paste the ID:** set `the-grid-wsl.id` in
   `nix/modules/syncthing.nix`, rebuild all hosts. `zettelkasten` and
   `privateConfig` (both `devices = lib.attrNames peers`) auto-include the new
   peer — no folder edits. The vault syncs into ext4; edit with nvim or Obsidian.

## Non-goals / caveats

- Same as the mesh at large: Syncthing is not backup; concurrent offline edits
  produce `.sync-conflict-*` files. See `docs/syncthing-sync.md`.
- `.stignore` is per-folder and NOT synced — recreate it in the WSL vault to
  ignore Obsidian cache/workspace if desired.
