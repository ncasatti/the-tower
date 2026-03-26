# The Tower

A declarative Nix Home Manager dotfiles repository for Arch Linux with Hyprland (Wayland).

Part of **The Grid** — a cohesive system architecture managed through Nix flakes.

---

## Overview

The Tower is a complete, reproducible desktop environment configuration. It uses **Nix Home Manager** (standalone) to manage:

- **Window Manager:** Hyprland (Wayland)
- **Terminal & Shell:** Kitty + Fish
- **Editor:** Neovim (Lazy.nvim, LSP, Treesitter, Telescope)
- **Utilities:** Tmux, Yazi, Starship, Rofi, Lazygit, Ripgrep, FZF
- **Theming:** GTK (Sweet-Ambar-Blue-Dark), Icons (Qogir-dark), Fonts (JetBrains Mono, 3270 Nerd Font)
- **Wayland Ecosystem:** Waybar, Hyprlock, Hypridle, Sway Notification Center, Wallust

All configuration is declarative and version-controlled. Secrets are kept external.

---

## Directory Structure

```
.
├── flake.nix                 # Nix flake entry point (nixpkgs-unstable + home-manager)
├── flake.lock               # Locked dependency versions
├── home.nix                 # Home Manager configuration (flyn profile)
├── configuration.nix        # Additional system configuration
│
├── nvim/                    # Neovim config (Lazy.nvim, LSP, Telescope, obsidian.nvim)
├── hypr/                    # Hyprland + Hyprlock + Hypridle
├── waybar/                  # Waybar status bar (multiple themes)
├── kitty/                   # Kitty terminal emulator
├── fish/                    # Fish shell config
├── rofi/                    # Rofi launcher (multiple themes)
├── tmux/                    # Tmux multiplexer
├── yazi/                    # Yazi file manager
├── starship/                # Starship prompt
├── swaync/                  # Sway Notification Center
├── wallust/                 # Wallust color generation
└── lazygit/                 # Lazygit configuration
```

---

## Quick Start

### Prerequisites

- Arch Linux (or compatible distro)
- Nix package manager installed
- Git

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/kasatto/the-tower ~/.the-grid/the-tower
   cd ~/.the-grid/the-tower
   ```

2. **Set up secrets (required):**
   ```bash
   mkdir -p ~/.the-grid/.private/rclone
   # Place your rclone.conf in ~/.the-grid/.private/rclone/rclone.conf
   ```

3. **Apply the configuration:**
   ```bash
   home-manager switch --flake .#flyn
   ```

4. **Reboot or restart your session** to activate Hyprland and all services.

---

## Configuration

### Home Manager Profile

The flake defines a single profile: **`flyn`** (x86_64-linux).

To apply changes after editing `home.nix` or any config file:
```bash
home-manager switch --flake .#flyn
```

### Secrets Management

Sensitive files (e.g., `rclone.conf`) are **not** version-controlled. They must be manually placed in:
```
~/.the-grid/.private/rclone/rclone.conf
```

The `home.nix` symlinks this file into the appropriate location.

### Theming

- **GTK Theme:** Sweet-Ambar-Blue-Dark-v40
- **Icon Theme:** Qogir-dark
- **Fonts:** JetBrains Mono Nerd Font (primary), 3270 Nerd Font Mono (Kitty), Roboto, Inter
- **Color Generation:** Wallust (auto-generates colors from wallpapers)

Edit `home.nix` to change themes or add new packages.

---

## Key Components

### Neovim
- **Plugin Manager:** Lazy.nvim
- **LSP:** Native LSP with multiple language servers
- **Fuzzy Finder:** Telescope
- **Treesitter:** Syntax highlighting and text objects
- **Knowledge Base:** obsidian.nvim for Zettelkasten integration
- **UI Enhancements:** Snacks.nvim

### Hyprland
- **Window Manager:** Hyprland (Wayland compositor)
- **Lock Screen:** Hyprlock
- **Idle Management:** Hypridle
- **Wallpaper:** Hyprpaper
- **Daemon:** Pyprland (for additional functionality)

### Terminal & Shell
- **Terminal:** Kitty (GPU-accelerated, 3270 Nerd Font Mono)
- **Shell:** Fish (interactive, user-friendly)
- **Prompt:** Starship (fast, customizable)
- **Multiplexer:** Tmux

### Utilities
- **File Manager:** Yazi (fast, keyboard-driven)
- **Launcher:** Rofi (with multiple themes)
- **Git Client:** Lazygit (TUI)
- **Search:** Ripgrep (rg), FZF
- **Clipboard:** wl-clipboard (Wayland)

---

## Development

### Updating Dependencies

To update Nix flake inputs:
```bash
nix flake update
```

Then apply:
```bash
home-manager switch --flake .#flyn
```

### Adding New Packages

Edit `home.nix` and add to the `home.packages` list:
```nix
home.packages = with pkgs; [
  # ... existing packages
  newpackage
];
```

Then run `home-manager switch --flake .#flyn`.

### Adding New Configurations

1. Create a new directory (e.g., `appname/`)
2. Add config files
3. Link them in `home.nix` via `home.file`:
   ```nix
   "~/.config/appname".source = ./appname;
   ```
4. Apply: `home-manager switch --flake .#flyn`

---

## Troubleshooting

### Configuration won't apply
- Ensure `flake.nix` syntax is valid: `nix flake check`
- Check for missing secrets in `~/.the-grid/.private/`
- Review Home Manager logs: `journalctl --user -u home-manager-*`

### Wayland issues
- Verify Hyprland is installed: `hyprland --version`
- Check Hyprland logs: `~/.cache/hyprland/`
- Ensure GPU drivers are installed (AMD/NVIDIA)

### Font rendering issues
- Rebuild font cache: `fc-cache -fv`
- Verify fonts are installed: `fc-list | grep "JetBrains\|3270"`

---

## License

This repository is personal configuration. Use at your own discretion.

---

**Maintained by:** Kasatto  
**System:** Arch Linux + Hyprland + Nix Home Manager  
**Last Updated:** 2026
