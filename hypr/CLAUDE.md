# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Hyprland configuration repository for a Wayland desktop environment. Hyprland is a dynamic tiling compositor that uses modular configuration files and shell scripts for theming, automation, and window management.

## Core Architecture

### Configuration System
The configuration follows a modular design where `hyprland.conf` sources all other configs from `configs/`:

- **hyprland.conf** - Main entry point that sources all modular configs
- **configs/settings.conf** - Core settings: displays, input, animations, decorations, layout manager (hy3)
- **configs/keybinds.conf** - Keyboard shortcuts using Colemak layout (n=left, i=right, u=up, e=down)
- **configs/monitors.conf** - Display configuration
- **configs/workspaces.conf** - Workspace rules
- **configs/windows.conf** - Window rules, opacity settings, floating behavior
- **configs/env.conf** - Environment variables
- **configs/startup.conf** - Auto-start applications (waybar, ags, swaync, etc.)
- **configs/laptop.conf** - Laptop-specific settings

### Key Modifiers
- `$mod = ALT` - Primary modifier for navigation and window management
- `$super = SUPER` - Secondary modifier for application launches and special functions
- `$ctrl_alt = CTRL ALT` - System functions (wallpaper, lock, refresh)
- `$mod_shift = ALT SHIFT` - Window manipulation

### Layout Manager
Currently configured to use **master** layout (see `configs/settings.conf:34`). The system also supports dwindle layout and has hy3 plugin available:
- Master layout: Maintains one main window with others stacked
- Can switch layouts using `scripts/settings/change-layout.sh`
- Movement: `movefocus` and `movewindow` for navigation

### Theming System
Dynamic theming powered by **wallust**:
1. User selects wallpaper via `scripts/theme/wallpaper-select.sh`
2. Wallpapers stored in `~/.config/konfig/themes/wallpapers`
3. `wallust` extracts color palette from wallpaper image
4. Colors written to `wallust/wallust-hyprland.conf`
5. Current wallpaper tracked in `wallpaper_effects/.wallpaper_current`
6. Colors sourced by main config as `$color0` through `$color15`
7. Applied to borders, waybar, rofi, kitty, GTK themes

### Script Organization
Scripts in `scripts/` are organized by function:

**System Operations** (`scripts/system/`):
- `refresh.sh` - Restart waybar, ags, swaync after theme/config changes
- `autostart.sh` - Custom startup commands (called from startup.conf)
- `lock-screen.sh` - Lock screen via hypridle/hyprlock
- `kill-active-process.sh` - Force kill active window process

**Theme Management** (`scripts/theme/`):
- `wallpaper-select.sh` - Interactive rofi menu with folder navigation
- `wallpaper-colors.sh` - Extract colors using wallust
- `wallpaper-random.sh` - Random wallpaper from directory
- `wallpaper-autochange.sh` - Automated wallpaper rotation
- `wallpaper-effects.sh` - Apply visual effects to wallpapers
- `change-blur.sh` - Toggle blur settings
- `rainbow-borders.sh` - Animated rainbow window borders
- `waybar-layout.sh` - Switch between waybar configurations
- `waybar-styles.sh` - Change waybar visual styles
- `waybar-cava.sh` - Audio visualizer integration

**Settings** (`scripts/settings/`):
- `change-layout.sh` - Switch between dwindle/master/hy3 layouts
- `switch-keyboard-layout.sh` - Cycle keyboard layouts
- `clip-manager.sh` - Clipboard history (cliphist)

**User Utilities** (`scripts/utils/`):
- `screenshot.sh` - Screenshot tool with area selection
- `music.sh` - Online music launcher

**Hardware Controls** (root level):
- `Brightness.sh` - Screen brightness
- `BrightnessKbd.sh` - Keyboard backlight
- `Volume.sh` - Audio volume
- `TouchPad.sh` - Touchpad toggle
- `MediaCtrl.sh` - Media playback controls

## Essential Commands

### Configuration Reload
After modifying configuration files:
```bash
# Restart Hyprland components (waybar, ags, swaync)
# Also toggles hyprshade blue-light-filter and relaunches rainbow-borders if enabled
./scripts/system/refresh.sh

# Or use the keybind: Ctrl+Alt+R
```

### Theme Management
```bash
# Interactive wallpaper selection with rofi
./scripts/theme/wallpaper-select.sh
# Keybind: Ctrl+Alt+W

# Random wallpaper from ~/.config/konfig/themes/wallpapers
./scripts/theme/wallpaper-random.sh
# Keybind: Alt+Shift+W

# Generate color scheme from current wallpaper
./scripts/theme/wallpaper-colors.sh

# Toggle blur effects
./scripts/theme/change-blur.sh
# Keybind: Alt+Shift+B

# Switch waybar layout/configuration
./scripts/theme/waybar-layout.sh

# Change waybar visual style
./scripts/theme/waybar-styles.sh
```

### Screen Shaders
Uses **hyprshade** for visual effects:
```bash
# Toggle vibrance effect
hyprshade toggle blue-light-vibrance
# Keybind: Super+V

# Toggle blue light filter
hyprshade toggle blue-light-filter
# Keybind: Super+N
```

### Testing Configuration Changes
To test keybinds without restarting:
```bash
hyprctl reload
```

To view current configuration:
```bash
hyprctl clients      # List all windows with class names
hyprctl monitors     # Monitor information
hyprctl workspaces   # Workspace status
```

## Key Implementation Patterns

### Wallpaper Workflow
Complete wallpaper change sequence:
1. Check/kill existing `swaybg` processes (conflicts with swww)
2. Use `swww img` with transition parameters for smooth wallpaper change
3. Call `wallpaper-colors.sh` to extract color palette with wallust
4. Call `refresh.sh` to apply theme to all components
5. Send desktop notification for user feedback

### Rofi Integration
All interactive menus use rofi:
- Custom config files: `~/.config/rofi/config-wallpaper.rasi`
- Always check for existing rofi processes and kill before launching
- Image preview support via `\x00icon\x1f` escape sequences

### Keybind Standards
- Workspace switching uses key codes (`code:10-19` for 1-0) to support multiple keyboard layouts
- Application variables defined at top of `keybinds.conf` for easy modification
- Movement uses Colemak home row (n/e/i/u instead of h/j/k/l)

### Window Rules Pattern
Window rules in `windows.conf`:
```conf
$appname = class-regex
windowrulev2 = opacity $opacity8, class:^($appname)$
windowrulev2 = workspace N, class:^($appname)$
```

### Startup Dependencies
Critical startup order in `startup.conf`:
1. `swww-daemon` - Wallpaper daemon
2. `dbus-update-activation-environment` - Wayland environment
3. `polkit.sh` - Authentication agent
4. `waybar`, `ags`, `swaync` - UI components
5. `cliphist` - Clipboard history
6. `hypridle` - Idle management
7. `pypr` - Python plugin manager (scratchpads, magnify)

## Pyprland Integration
Uses **pyprland** for additional features:
- Scratchpads: Drop-down terminal (`kitty-dropterm`)
- Magnify: Screen magnification tool

## Color Variables
Wallust generates colors available in configs:
- `$color0` through `$color15` - Standard 16-color palette
- Active borders: `$color12` (bright blue)
- Inactive borders: `rgba(000000ff)` (black)
- Used in window borders, waybar, rofi, terminal themes

## External Dependencies
Core tools required:
- **swww** - Wallpaper daemon with transitions
- **wallust** - Color scheme generator
- **rofi** - Application launcher and menus
- **waybar** - Status bar
- **ags** - Additional UI widgets
- **swaync** - Notification daemon
- **hyprshade** - Screen shader effects
- **cliphist** - Clipboard manager
- **pypr** - Python plugins for Hyprland
- **hypridle/hyprlock** - Idle and lock screen management

## Common Modifications

### Customizing Default Applications
Edit `configs/keybinds.conf` (lines 9-15) to change default applications:
```conf
$files = thunar              # File manager
$term = cool-retro-term      # Terminal (alternatives: kitty, wezterm, warp-terminal)
$code = windsurf             # Code editor (alternatives: code, cursor)
$whatsapp = whatsdesk        # WhatsApp client
$explorer = zen-browser      # Web browser
$android = ~/.local/share/Uts/android-studio/bin/studio.sh  # Android Studio path
```

### Adding New Keybinds
Edit `configs/keybinds.conf`:
```conf
bind = $mod, KEY, action, parameters
# For Colemak layout: n=left, i=right, u=up, e=down
```

### Adding Window Rules
Edit `configs/windows.conf`:
```conf
$appvar = window-class-regex
windowrulev2 = rule, class:^($appvar)$
```

### Adding Startup Applications
Edit `configs/startup.conf`:
```conf
exec-once = command &
```

### Modifying Theme Colors
Colors auto-generate from wallpaper, but can override in:
- `wallust/wallust-hyprland.conf` - Hyprland-specific colors
- Wallust templates in parent konfig repository

## File Modification Workflow

When modifying configs:
1. Edit the relevant modular config file (not hyprland.conf directly)
2. Test with `hyprctl reload` or restart individual components
3. For major changes, run `./scripts/system/refresh.sh`
4. Check logs with `journalctl --user -u hyprland`
