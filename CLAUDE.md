# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

**The Tower** — declarative Nix-flake configuration deploying a Hyprland/Wayland desktop across three NixOS hosts. There is no application code here; everything is configuration (Nix modules + dotfiles symlinked via Home Manager).

## Deployment Targets (defined in `flake.nix`)

All three targets are `nixosConfigurations` — `main` is **NOT** Home-Manager-standalone despite what `README.md` claims. The README is partially stale; `AGENTS.md` and `flake.nix` are authoritative.

| Target     | Role                              | Rebuild command                                 |
|------------|-----------------------------------|-------------------------------------------------|
| `notebook` | Portable workstation              | `sudo nixos-rebuild switch --flake .#notebook`  |
| `main`     | Primary workstation               | `sudo nixos-rebuild switch --flake .#main`      |
| `server`   | Headless infra node (DNS + VPN)   | `sudo nixos-rebuild switch --flake .#server`    |

Entry points: `nix/hosts/<target>/default.nix` (system) and `nix/hosts/<target>/home.nix` (per-host Home Manager).

## Common Commands

```bash
nix flake check          # Validate flake syntax / evaluation
nix flake update         # Bump all inputs
nix fmt                  # If formatter is wired; otherwise nixpkgs-fmt manually
```

For a single host eval test without switching: `nixos-rebuild build --flake .#<target>`.

## Architecture

The repo splits into two layers — **Nix definitions** under `nix/`, and **raw dotfiles** at the repo root (`nvim/`, `hypr/`, `kitty/`, `waybar/`, etc.) that are symlinked into `~/.config/` by `nix/home/dotfiles.nix`.

### Nix layer (`nix/`)

- **`hosts/<target>/`** — per-host system config. Each host has `default.nix`, `hardware-configuration.nix`, `home.nix`, and host-specific modules (`audio.nix`, `services.nix`, `secrets/`).
- **`home/`** — shared Home Manager modules imported by each host's `home.nix`. Key files:
  - `dotfiles.nix` — the symlink table mapping repo dirs → `~/.config/*`. **Adding a new app config requires editing this file.**
  - `git.nix`, `gtk.nix`, `tmux.nix`, `xdg.nix`, `sioyek.nix`, `activation.nix`, `secrets.nix`.
- **`packages/`** — categorical package lists merged into `home.packages`. Categories: `cli.nix`, `dev.nix`, `languages.nix`, `wayland.nix`, `appearance.nix`, `audio.nix`, `utilities.nix`, `nvim.nix`, `cursor-theme.nix`, `gentle-ai.nix`, plus `custom/` for derivations not in nixpkgs.
- **`overlays/default.nix`** — applied to every host via `nixpkgs.overlays`. Pulls in `inputs` (zen-browser, opencode-nix, clingy, antigravity-nix).
- **`modules/`** — reusable NixOS modules (non-host-specific).

### Dotfile layer (repo root)

Each top-level dir (`nvim/`, `hypr/`, `waybar/`, `kitty/`, `fish/`, `rofi/`, `tmux/`, `yazi/`, `starship/`, `swaync/`, `wallust/`, `lazygit/`, `wezterm/`, `posting/`, `keyd/`, `hyprshade/`, `themes/`, `fonts/`, `cool-retro-term/`) is a plain config directory — **not Nix-managed internally**. `dotfiles.nix` maps each with `source = ../../<dir>; recursive = true`, which is a **flake store copy**, not a live symlink. Consequences: **editing any dotfile requires `sudo nixos-rebuild switch`** to take effect, and **new files must be `git add`-ed first** (the flake copies only git-tracked files, so an untracked file is invisible at runtime).

Modules with their own docs: [`nvim/`](nvim/README.md), [`hypr/`](hypr/README.md), `tmux/` (`TMUX_KEYBINDINGS.md`, `TMUX_PLUGINS.md`). The root [`README.md`](README.md) indexes them under **Documentation Map**.

### Flake inputs of note

- `agenix` — encrypted secrets. Secrets live under `nix/hosts/<target>/secrets/` and are referenced via `config.age.secrets.<name>.path`. Currently marked legacy in AGENTS.md.
- `zen-browser`, `opencode-nix`, `clingy`, `antigravity-nix` — third-party flakes wired through the overlay.

## Workflow Rules

### Adding a package
1. Pick the right category in `nix/packages/` (CLI tool → `cli.nix`, Wayland component → `wayland.nix`, dev tool → `dev.nix`, etc.).
2. Append to `home.packages = with pkgs; [ ... ]`.
3. Rebuild the target.

### Adding a new app config
1. Drop the config directory at the repo root.
2. Add a `home.file.".config/<name>".source = ../../<name>;` entry in `nix/home/dotfiles.nix`.
3. Rebuild.

### Custom derivations
Place new derivations under `nix/packages/custom/` and reference them from a category file via the overlay.

## Source-of-truth conflicts

- **`flake.nix` is authoritative** on the deployment model — three `nixosConfigurations` (`notebook`, `main`, `server`), each pulling Home Manager via `nix/hosts/<target>/home.nix`. `README.md` and `AGENTS.md` are now aligned to this; if any doc drifts again, trust `flake.nix`.
- **Module docs are the source of truth for their tool** — `nvim/README.md`, `hypr/README.md`, `tmux/TMUX_*.md`. When a module doc and the code disagree, the code wins: fix the doc and cite `file:line`.
