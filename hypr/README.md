# Hyprland Configuration

Hyprland (Wayland tiling compositor) configuration for Arch Linux, managed via Nix Home Manager.

## Overview

- **Compositor:** Hyprland (Wayland)
- **Origin:** Heavily customized from JaKooLit's Hyprland dotfiles
- **Management:** Nix Home Manager (symlinked from `~/.the-grid/the-tower/hypr/` to `~/.config/hypr/`)
- **Keyboard Layout:** Colemak (movement: n=left, i=right, u=up, e=down)

## Configuration Structure

### Main Entry Point

`hyprland.conf` sources modular configs from `configs/`:

| File | Purpose |
|------|---------|
| `settings.conf` | Core settings: input, animations, decorations, hy3 plugin layout |
| `keybinds.conf` | Active keyboard shortcuts (Colemak layout) |
| `keybinds-old.conf` | Legacy keybinds (kept for reference) |
| `monitors.conf` | Display configuration |
| `workspaces.conf` | Workspace rules |
| `windows.conf` | Window rules, opacity, floating behavior |
| `env.conf` | Environment variables |
| `startup.conf` | Auto-start applications |
| `laptop.conf` | Laptop-specific binds (brightness, touchpad, lid) |
| `hy3.conf` | hy3 plugin configuration |

### Root-Level Configs

- `hypridle.conf` — Idle management
- `hyprlock.conf` — Lock screen configuration
- `pyprland.toml` — Pyprland plugin config (scratchpads, magnify)

## Key Modifiers

| Modifier | Binding | Purpose |
|----------|---------|---------|
| `$mod` | ALT | Navigation, window management |
| `$super` | SUPER | App launches, special functions |
| `$ctrl_alt` | CTRL ALT | System functions |
| `$mod_shift` | ALT SHIFT | Window manipulation |

## Scripts Organization

Scripts are organized by category in lowercase kebab-case:

### `hardware/`
Hardware controls and input management.
- `brightness.sh` — Display brightness
- `brightness-kbd.sh` — Keyboard brightness
- `media-ctrl.sh` — Media playback control
- `touchpad.sh` — Touchpad settings
- `volume.sh` — Audio volume control

### `settings/`
Dynamic configuration and runtime settings.
- `change-layout.sh` — Change window layout
- `clip-manager.sh` — Clipboard management
- `refresh-no-waybar.sh` — Refresh without waybar
- `switch-keyboard-layout.sh` — Toggle keyboard layout

### `system/`
System operations and core functionality.
- `airplane-mode.sh` — Toggle airplane mode
- `autostart.sh` — Startup sequence
- `kill-active-process.sh` — Terminate active window process
- `lock-screen.sh` — Lock screen
- `polkit.sh` — PolicyKit agent
- `polkit-nixos.sh` — NixOS-specific PolicyKit (kept for future migration)
- `portal-hyprland.sh` — XDG portal restart
- `refresh.sh` — Main refresh: waybar, swaync, ags, hyprshade
- `wlogout.sh` — Logout menu

### `theme/`
Theming, visuals, and wallpaper management.
- `change-blur.sh`, `change-blur-2.sh`, `change-blur-3.sh` — Blur effect variants (pending consolidation)
- `rainbow-borders.sh` — Rainbow border animation
- `wallpaper-autochange.sh` — Auto-rotate wallpapers
- `wallpaper-colors.sh` — Extract and apply wallpaper colors
- `wallpaper-effects.sh` — Apply visual effects to wallpaper
- `wallpaper-random.sh` — Set random wallpaper
- `wallpaper-select.sh` — Interactive wallpaper selection
- `waybar-cava.sh` — Waybar audio visualizer
- `waybar-layout.sh` — Waybar layout switching
- `waybar-styles.sh` — Waybar style management

### `utils/`
Utility scripts and miscellaneous tools.
- `gamemode.sh` — Gaming mode toggle
- `music.sh` — Music player control
- `screenshot.sh` — Screenshot capture
- `sounds.sh` — Sound effects
- `uptime-nixos.sh` — System uptime (NixOS-specific)

## Theming System

Dynamic theming via wallust:

1. User selects wallpaper (`wallpaper-select.sh` or `wallpaper-random.sh`)
2. `wallust` extracts color palette from image
3. Colors written to `~/.cache/wallust/wallust-hyprland.conf`
4. Colors sourced as `$color0` through `$color15`
5. Applied to borders, waybar, rofi, kitty

## Dependencies

**Core tools:**
swww, wallust, rofi, waybar, ags, swaync, hyprshade, cliphist, pyprland, hypridle, hyprlock, wl-clipboard

## Pending Cleanup

- [ ] Merge three blur scripts (`change-blur.sh`, `change-blur-2.sh`, `change-blur-3.sh`) into one
- [ ] Review and clean `keybinds-old.conf` (legacy from JaKooLit)
- [ ] Review backup files in `configs/` (`keybinds.bak`, `windows.conf.bak`)
- [ ] Audit `laptop.conf` for relevance
- [ ] Review `.configs/` hidden directory (unknown purpose)
- [ ] Review `wallpaper_effects/` directory
- [ ] Review `wallust/` directory
