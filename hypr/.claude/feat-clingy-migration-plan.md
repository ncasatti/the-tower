# SDD: Hyprland Scripts → Clingy CLI Migration + Cache Centralization

> **Status:** PENDING APPROVAL  
> **Author:** CLU (Technical Planner)  
> **Date:** 2026-03-26  
> **Supersedes:** `feat-cache-centralization-plan.md` (cache centralization is now integrated into this plan)  
> **Scope:** Migrate 30+ shell scripts to Clingy Python commands, centralize all runtime files under `~/.cache/hypr/`, fix 8 bugs, remove dead artifacts.

---

## 1. Objective

Transform the Hyprland scripting layer from a collection of fragile, duplicated shell scripts into a unified Python CLI managed by the **Clingy** framework. Simultaneously, centralize all dynamically generated files (wallpaper symlinks, processed images, wallust color outputs) under `~/.cache/hypr/` to eliminate path fragmentation and fix 8 verified bugs.

### End State

- **Interactive:** `clingy` (no args) opens an fzf menu with all Hyprland operations organized hierarchically.
- **CLI:** `clingy wallpaper --random`, `clingy blur --toggle`, etc. — scriptable, composable.
- **Keybinds:** Hyprland keybinds call `clingy <command> --flag` instead of `$scripts/path/to/script.sh`.
- **Cache:** All mutable runtime state lives in `~/.cache/hypr/`, referenced from a single `config.py`.
- **Hardware scripts stay as shell:** Volume, brightness, media, touchpad remain as `.sh` for <50ms latency.

### Target Cache Structure

```
~/.cache/hypr/
├── current-wallpaper          # symlink → active wallpaper image
├── current-wallpaper-copy     # unmodified copy for effects input
├── modified-wallpaper         # ImageMagick output
└── wallust/                   # wallust color outputs
    ├── wallust-hyprland.conf
    ├── colors-rofi.rasi
    ├── colors-waybar.css
    ├── colors-kitty.conf
    ├── colors-bash.sh
    └── colors-swaync.css
```

---

## 2. Architecture / Approach

### 2.1 Clingy Command Architecture

All commands live in `/home/ncasatti/.the-grid/clingy/commands/` and extend `BaseCommand`. Each command file is auto-discovered by Clingy's discovery system. The `config.py` at the clingy project root defines all shared paths and constants.

**Pattern (from existing `sync.py` and `nix.py`):**
```
class CommandName(BaseCommand):
    name = "command-name"           # CLI subcommand name
    help = "Short description"
    description = "Detailed description"

    def add_arguments(self, parser: ArgumentParser): ...
    def execute(self, args: Namespace) -> bool: ...
    def get_menu_tree(self) -> MenuNode: ...
```

**Shared utilities** (not commands) go in a `utils/` module inside the clingy commands directory:
- `commands/utils/__init__.py` — package init
- `commands/utils/hypr.py` — shared Hyprland helpers (subprocess wrappers for `hyprctl`, `swww`, `notify-send`, `wallust`, process management)
- `commands/utils/sounds.py` — sound playback (migrated from `sounds.sh`)

### 2.2 Config Centralization

`config.py` becomes the single source of truth for ALL paths. Every command imports from it. No hardcoded paths in command files.

### 2.3 Separation of Concerns

| Layer | Responsibility | Location |
|-------|---------------|----------|
| **config.py** | Path constants, dependencies, project metadata | `clingy/config.py` |
| **utils/hypr.py** | Subprocess wrappers, process management, notifications | `clingy/commands/utils/hypr.py` |
| **utils/sounds.py** | Sound playback via pw-play/pa-play | `clingy/commands/utils/sounds.py` |
| **Command files** | Business logic, CLI args, menu trees | `clingy/commands/<name>.py` |
| **Hardware scripts** | Latency-critical XF86 key handlers | `the-tower/hypr/scripts/hardware/` |

### 2.4 Bug Inventory (Fixed by This Migration)

| # | Bug | Fixed In |
|---|-----|----------|
| B1 | hyprlock.conf sources stale repo colors (`$HOME/.config/hypr/wallust/`) | Step 5 |
| B2 | wallpaper-random.sh runs wallust twice | Step 3 (eliminated — single `_apply_wallpaper()` pipeline) |
| B3 | wallpaper-effects.sh references `Refresh.sh` (capital R) | Step 3 (eliminated — Python calls refresh directly) |
| B4 | wallpaper-autochange.sh doesn't update symlink/colors | Step 3 (fixed — `_apply_wallpaper()` always runs full pipeline) |
| B6 | Inconsistent wallpaper directories | Step 1 (single `WALLPAPER_DIR` in config.py) |
| B7 | 16 waybar styles reference non-existent wallust path | Step 6 |
| B8 | 10 rofi themes reference non-existent wallust path | Step 6 |
| B9 | swaync hardcoded absolute path | Step 6 (updated to `~/.cache/hypr/wallust/`, username still hardcoded — CSS limitation) |

### 2.5 Dead Artifacts to Remove (Step 9)

| Artifact | Reason |
|----------|--------|
| `hypr/.configs/` | Dead JaKooLit symlink system, `create_links.sh` main() commented out |
| `hypr/wallust/` | Stale color snapshots, never updated at runtime |
| `hypr/wallpaper_effects/` | Runtime files, now in `~/.cache/hypr/` |
| `waybar/wallust/` | Stale snapshot |
| `hypr/scripts/theme/` (all files) | Migrated to clingy commands |
| `hypr/scripts/system/refresh.sh` | Migrated to clingy `refresh` command |
| `hypr/scripts/system/wlogout.sh` | Migrated to clingy `wlogout` command |
| `hypr/scripts/system/lock-screen.sh` | Migrated to clingy `lock` command |
| `hypr/scripts/system/kill-active-process.sh` | Migrated to clingy `kill-window` command |
| `hypr/scripts/system/airplane-mode.sh` | Migrated to clingy `airplane` command |
| `hypr/scripts/settings/change-layout.sh` | Migrated to clingy `layout` command |
| `hypr/scripts/settings/clip-manager.sh` | Migrated to clingy `clipboard` command |
| `hypr/scripts/settings/switch-keyboard-layout.sh` | Migrated to clingy `keyboard` command |
| `hypr/scripts/settings/refresh-no-waybar.sh` | Absorbed into `refresh --no-waybar` |
| `hypr/scripts/utils/screenshot.sh` | Migrated to clingy `screenshot` command |
| `hypr/scripts/utils/gamemode.sh` | Migrated to clingy `gamemode` command |
| `hypr/scripts/utils/music.sh` | Migrated to clingy `music` command |
| `hypr/scripts/utils/sounds.sh` | Migrated to `commands/utils/sounds.py` |

**Kept as shell scripts:**
- `hypr/scripts/hardware/volume.sh`
- `hypr/scripts/hardware/brightness.sh`
- `hypr/scripts/hardware/brightness-kbd.sh`
- `hypr/scripts/hardware/media-ctrl.sh`
- `hypr/scripts/hardware/touchpad.sh`
- `hypr/scripts/system/autostart.sh` (runs at boot before clingy context)
- `hypr/scripts/system/polkit.sh` (runs at boot)
- `hypr/scripts/system/polkit-nixos.sh` (runs at boot)
- `hypr/scripts/system/portal-hyprland.sh` (runs at boot)

---

## 3. Execution Steps

---

### Step 1: Update `config.py` with Hyprland Paths and Dependencies

**Objective:** Establish the single source of truth for all paths, wallpaper settings, and external tool dependencies.

**Files modified:**
- `clingy/config.py` (at `/home/ncasatti/.the-grid/clingy/config.py`)

**Exact changes:**

Replace the entire file content. The new `config.py` must define:

```python
# Project metadata
PROJECT_NAME = "The Grid CLI"
PROJECT_VERSION = "2.0.0"

# ============================================================================
# Paths — Single Source of Truth
# ============================================================================
import os
from pathlib import Path

HOME = Path(os.environ.get("HOME", "/home/ncasatti"))

# Dotfiles repo (symlinked to ~/.config/ by Nix Home Manager)
HYPR_CONFIG = HOME / ".config" / "hypr"
HYPR_SCRIPTS = HYPR_CONFIG / "scripts"

# Cache — all mutable runtime state
CACHE_DIR = HOME / ".cache" / "hypr"
WALLUST_CACHE = CACHE_DIR / "wallust"

# Wallpaper cache files
CURRENT_WALLPAPER = CACHE_DIR / "current-wallpaper"         # symlink → active wallpaper
CURRENT_WALLPAPER_COPY = CACHE_DIR / "current-wallpaper-copy"  # unmodified copy for effects
MODIFIED_WALLPAPER = CACHE_DIR / "modified-wallpaper"        # ImageMagick output

# Wallust output files
WALLUST_HYPRLAND = WALLUST_CACHE / "wallust-hyprland.conf"
WALLUST_COLORS_BASH = WALLUST_CACHE / "colors-bash.sh"
WALLUST_COLORS_ROFI = WALLUST_CACHE / "colors-rofi.rasi"
WALLUST_COLORS_WAYBAR = WALLUST_CACHE / "colors-waybar.css"
WALLUST_COLORS_KITTY = WALLUST_CACHE / "colors-kitty.conf"
WALLUST_COLORS_SWAYNC = WALLUST_CACHE / "colors-swaync.css"

# Wallpaper source directory
WALLPAPER_DIR = HOME / ".config" / "konfig" / "themes" / "wallpapers"

# External config paths
WAYBAR_CONFIGS = HOME / ".config" / "waybar" / "configs"
WAYBAR_CONFIG = HOME / ".config" / "waybar" / "config"
WAYBAR_STYLES = HOME / ".config" / "waybar" / "style"
WAYBAR_STYLE = HOME / ".config" / "waybar" / "style.css"
ROFI_CONFIG_DIR = HOME / ".config" / "rofi"
SWAYNC_ICONS = HOME / ".config" / "swaync" / "icons"
SWAYNC_IMAGES = HOME / ".config" / "swaync" / "images"

# Screenshots
SCREENSHOT_DIR = HOME / "Pictures" / "Screenshots"

# Music
MUSIC_DIR = HOME / "Music"

# swww transition defaults
SWWW_FPS = 144
SWWW_TYPE = "any"
SWWW_DURATION = 0.8
SWWW_BEZIER = ".43,1.19,1,.4"

# ============================================================================
# Items (not used for Hyprland, kept for clingy compatibility)
# ============================================================================
ITEMS = []

# ============================================================================
# Dependencies
# ============================================================================
from clingy.core.dependency import Dependency

DEPENDENCIES = [
    Dependency(name="fzf", command="fzf", description="Fuzzy finder", install_linux="sudo pacman -S fzf", required=True),
    Dependency(name="python", command="python", description="Python 3", install_linux="sudo pacman -S python", required=True),
    Dependency(name="swww", command="swww", description="Wallpaper daemon", install_linux="sudo pacman -S swww", required=True),
    Dependency(name="wallust", command="wallust", description="Color scheme generator", install_linux="cargo install wallust", required=True),
    Dependency(name="hyprctl", command="hyprctl", description="Hyprland control", install_linux="(bundled with hyprland)", required=True),
    Dependency(name="rofi", command="rofi", description="Application launcher", install_linux="sudo pacman -S rofi-wayland", required=True),
    Dependency(name="grim", command="grim", description="Screenshot tool", install_linux="sudo pacman -S grim", required=False),
    Dependency(name="slurp", command="slurp", description="Region selector", install_linux="sudo pacman -S slurp", required=False),
    Dependency(name="magick", command="magick", description="ImageMagick", install_linux="sudo pacman -S imagemagick", required=False),
    Dependency(name="mpv", command="mpv", description="Media player", install_linux="sudo pacman -S mpv", required=False),
]
```

**Verification:**
1. `python -c "from config import CACHE_DIR, WALLPAPER_DIR; print(CACHE_DIR, WALLPAPER_DIR)"` — must print correct paths
2. `clingy --help` — must still work (no import errors)

**Bugs fixed:** B6 (single `WALLPAPER_DIR`)

---

### Step 2: Update `wallust.toml` Output Targets → `~/.cache/hypr/wallust/`

**Objective:** Redirect all wallust output from `~/.cache/wallust/` to `~/.cache/hypr/wallust/`.

**Files modified:**
- `the-tower/wallust/wallust.toml`

**Exact changes — update ALL 6 target paths (cava stays unchanged):**

| Template | Old Target | New Target |
|----------|-----------|------------|
| `hypr.target` | `'~/.cache/wallust/wallust-hyprland.conf'` | `'~/.cache/hypr/wallust/wallust-hyprland.conf'` |
| `rofi.target` | `'~/.cache/wallust/colors-rofi.rasi'` | `'~/.cache/hypr/wallust/colors-rofi.rasi'` |
| `waybar.target` | `'~/.cache/wallust/colors-waybar.css'` | `'~/.cache/hypr/wallust/colors-waybar.css'` |
| `kitty.target` | `'~/.cache/wallust/colors-kitty.conf'` | `'~/.cache/hypr/wallust/colors-kitty.conf'` |
| `bash.target` | `'~/.cache/wallust/colors-bash.sh'` | `'~/.cache/hypr/wallust/colors-bash.sh'` |
| `swaync.target` | `'~/.cache/wallust/colors-swaync.css'` | `'~/.cache/hypr/wallust/colors-swaync.css'` |
| `cava.target` | `'~/.config/cava/config'` | **NO CHANGE** (cava requires config at this exact path) |

**Verification:**
1. `mkdir -p ~/.cache/hypr/wallust/`
2. `wallust run <any-wallpaper> -s`
3. `ls ~/.cache/hypr/wallust/` — must show all 6 files

---

### Step 3: Create Core Clingy Commands (wallpaper, refresh) + Shared Utilities

**Objective:** Build the foundation commands that all other commands depend on. Create the shared utility modules.

**Files created:**
- `clingy/commands/utils/__init__.py`
- `clingy/commands/utils/hypr.py`
- `clingy/commands/utils/sounds.py`
- `clingy/commands/wallpaper.py`
- `clingy/commands/refresh.py`

---

#### 3a. `commands/utils/__init__.py`

Empty file (package marker).

---

#### 3b. `commands/utils/hypr.py` — Shared Hyprland Helpers

**Purpose:** Centralize all subprocess calls to Hyprland tools. Every command imports from here instead of calling `subprocess.run()` directly.

**Functions to implement:**

```
def ensure_cache_dirs() -> None:
    """Create ~/.cache/hypr/ and ~/.cache/hypr/wallust/ if they don't exist.
    Called at the start of any command that writes to cache.
    Uses config.CACHE_DIR and config.WALLUST_CACHE."""

def get_focused_monitor() -> str:
    """Run `hyprctl monitors` and parse to get the focused monitor name.
    Equivalent of: hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}'
    Use `hyprctl -j monitors` (JSON mode) and parse with json module for reliability."""

def swww_set_wallpaper(image_path: str | Path, monitor: str | None = None) -> bool:
    """Set wallpaper using swww img with transition params from config.
    If monitor is None, call get_focused_monitor().
    Params: --transition-fps {SWWW_FPS} --transition-type {SWWW_TYPE} --transition-duration {SWWW_DURATION}
    Returns True on success."""

def swww_ensure_daemon() -> None:
    """Check if swww daemon is running (swww query). If not, start it (swww-daemon --format xrgb).
    Also kill swaybg if running (legacy conflict)."""

def run_wallust(image_path: str | Path) -> bool:
    """Run `wallust run <image_path> -s` (skip tty/terminal changes).
    Returns True on success."""

def update_wallpaper_symlink(image_path: str | Path) -> None:
    """Create/update symlink at config.CURRENT_WALLPAPER pointing to image_path.
    Also copy image to config.CURRENT_WALLPAPER_COPY (for effects input).
    Calls ensure_cache_dirs() first."""

def notify(title: str, body: str = "", urgency: str = "low", icon: str | None = None) -> None:
    """Send desktop notification via notify-send.
    Default icon: config.SWAYNC_IMAGES / 'bell.png'"""

def kill_processes(*names: str) -> None:
    """Kill processes by name using pkill. Silently ignores if not running."""

def hyprctl_keyword(keyword: str, value: str) -> bool:
    """Run `hyprctl keyword <keyword> <value>`. Returns True on success."""

def hyprctl_get_option(option: str) -> Any:
    """Run `hyprctl -j getoption <option>` and return parsed JSON."""

def run_command(cmd: list[str], check: bool = True) -> subprocess.CompletedProcess:
    """Generic subprocess wrapper with error handling and logging."""
```

---

#### 3c. `commands/utils/sounds.py` — Sound Playback

**Purpose:** Direct port of `sounds.sh` logic to Python. Used by `screenshot` and `volume` (volume still calls it via shell, but screenshot command will import it).

**Functions to implement:**

```
def play_sound(sound_type: str) -> None:
    """Play a system sound.
    sound_type: "screenshot" | "volume" | "error"
    
    Logic (ported from sounds.sh):
    1. Map sound_type to glob pattern:
       - "screenshot" → "screen-capture.*"
       - "volume" → "audio-volume-change.*"
       - "error" → "dialog-error.*"
    2. Search for sound file in order:
       a. $HOME/.local/share/sounds/{theme}/stereo/
       b. /run/current-system/sw/share/sounds/{theme}/stereo/ (NixOS)
       c. /usr/share/sounds/{theme}/stereo/
       d. Fallback to "freedesktop" theme in same dirs
       e. Check inherited theme from index.theme
    3. Play with pw-play, fallback to pa-play
    
    theme = "freedesktop" (hardcoded default)
    """
```

---

#### 3d. `commands/wallpaper.py` — Wallpaper Management Command

**Class:** `Wallpaper(BaseCommand)`  
**name:** `"wallpaper"`  
**help:** `"Wallpaper management"`

**CLI arguments:**
```python
def add_arguments(self, parser):
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--random", action="store_true", help="Set random wallpaper")
    group.add_argument("--select", action="store_true", help="Browse and select wallpaper via rofi")
    group.add_argument("--effects", action="store_true", help="Apply visual effects to current wallpaper")
    group.add_argument("--autochange", action="store_true", help="Start auto-change daemon (every 30min)")
```

**Menu tree:**
```python
def get_menu_tree(self) -> MenuNode:
    return MenuNode(
        label="Wallpaper",
        emoji=Emoji.MONITOR,
        children=[
            MenuNode(label="Random", emoji=Emoji.SYNC, action=self._random),
            MenuNode(label="Browse & Select", emoji=Emoji.SEARCH, action=self._select),
            MenuNode(label="Effects", emoji=Emoji.GEAR, action=self._effects),
            MenuNode(label="Auto-change (30min)", emoji=Emoji.TIME, action=self._autochange),
        ],
    )
```

**Core logic (pseudocode for each method):**

```
def _apply_wallpaper(self, image_path: Path) -> bool:
    """THE UNIFIED WALLPAPER PIPELINE. Every entry point calls this.
    Fixes B2 (no duplicate wallust), B4 (always updates symlink+colors).
    
    1. hypr.swww_ensure_daemon()
    2. hypr.swww_set_wallpaper(image_path)
    3. hypr.update_wallpaper_symlink(image_path)  # symlink + copy
    4. hypr.run_wallust(image_path)                # wallust ONCE
    5. self._refresh(no_waybar=False)               # or call refresh command
    6. hypr.notify("Wallpaper changed")
    """

def _random(self) -> bool:
    """Pick random wallpaper from config.WALLPAPER_DIR (recursive find).
    Uses pathlib glob for *.jpg, *.jpeg, *.png, *.gif.
    Calls _apply_wallpaper() with the random pick."""

def _select(self) -> bool:
    """Interactive rofi-based wallpaper browser with folder navigation.
    Port of wallpaper-select.sh logic:
    1. Start at config.WALLPAPER_DIR
    2. Show folders (with random preview icon) and images via rofi
    3. Folder selection → navigate into it
    4. Image selection → call _apply_wallpaper()
    5. "Back" → navigate up (stop at WALLPAPER_DIR)
    
    Rofi config: ~/.config/rofi/config-wallpaper.rasi
    Uses \x00icon\x1f for image previews in rofi."""

def _effects(self) -> bool:
    """Apply ImageMagick effects to current wallpaper.
    Port of wallpaper-effects.sh logic:
    1. Read from config.CURRENT_WALLPAPER_COPY (unmodified original)
    2. Show rofi menu with effect names (config-wallpaper-effect.rasi)
    3. "No Effects" → swww_set_wallpaper(CURRENT_WALLPAPER_COPY), run wallust on original
    4. Other effect → run `magick <input> <effect_args> <MODIFIED_WALLPAPER>`
       then swww_set_wallpaper(MODIFIED_WALLPAPER), run wallust on modified
    5. Call refresh
    
    Effects dict (same as wallpaper-effects.sh):
    {
        "Black & White": ["-colorspace", "gray", "-sigmoidal-contrast", "10,40%"],
        "Blurred": ["-blur", "0x10"],
        "Charcoal": ["-charcoal", "0x5"],
        "Edge Detect": ["-edge", "1"],
        "Emboss": ["-emboss", "0x5"],
        "Negate": ["-negate"],
        "Oil Paint": ["-paint", "4"],
        "Posterize": ["-posterize", "4"],
        "Polaroid": ["-polaroid", "0"],
        "Sepia Tone": ["-sepia-tone", "65%"],
        "Solarize": ["-solarize", "80%"],
        "Sharpen": ["-sharpen", "0x5"],
        "Vignette": ["-vignette", "0x5"],
        "Zoomed": ["-gravity", "Center", "-extent", "1:1"],
    }"""

def _autochange(self) -> bool:
    """Start wallpaper auto-change daemon.
    Port of wallpaper-autochange.sh:
    1. Find all images in config.WALLPAPER_DIR recursively
    2. Shuffle the list
    3. Loop: for each image, call _apply_wallpaper(), sleep 1800 seconds
    4. When list exhausted, reshuffle and repeat
    
    NOTE: This runs as a long-lived process. When called from keybind,
    it should fork/background. Consider using subprocess.Popen to spawn
    itself in background, or document that keybind should use `&`."""
```

---

#### 3e. `commands/refresh.py` — System Refresh Command

**Class:** `Refresh(BaseCommand)`  
**name:** `"refresh"`  
**help:** `"Refresh Hyprland components"`

**CLI arguments:**
```python
def add_arguments(self, parser):
    parser.add_argument("--no-waybar", action="store_true", help="Refresh without restarting waybar")
```

**Menu tree:**
```python
def get_menu_tree(self) -> MenuNode:
    return MenuNode(
        label="Refresh",
        emoji=Emoji.SYNC,
        children=[
            MenuNode(label="Full Refresh", emoji=Emoji.ROCKET, action=self._refresh, action_kwargs={"no_waybar": False}),
            MenuNode(label="Refresh (no Waybar)", emoji=Emoji.GEAR, action=self._refresh, action_kwargs={"no_waybar": True}),
        ],
    )
```

**Core logic (pseudocode):**

```
def _refresh(self, no_waybar: bool = False) -> bool:
    """Port of refresh.sh + refresh-no-waybar.sh:
    
    1. hypr.kill_processes("rofi")
    2. If NOT no_waybar:
       a. hypr.kill_processes("waybar", "swaync", "ags")
       b. Run: ags -q
       c. sleep(0.3)
       d. Start: waybar & (subprocess.Popen)
       e. sleep(0.5)
       f. Start: swaync & (subprocess.Popen, stdout/stderr to devnull)
       g. Start: ags & (subprocess.Popen)
    3. If no_waybar:
       a. Run: ags -q
    4. Relaunch rainbow borders:
       subprocess.Popen(["clingy", "borders", "--rainbow"])
       (or call the borders command directly if imported)
    5. Toggle hyprshade:
       If no_waybar: run `hyprshade toggle vibrance`
       If full: run `hyprshade toggle blue-light-vibrance-reading`
    """
```

**Verification for Step 3:**
1. `clingy wallpaper --random` — wallpaper changes, symlink at `~/.cache/hypr/current-wallpaper` points to it, wallust colors regenerated, waybar/swaync restart
2. `clingy wallpaper --select` — rofi opens with folder navigation, selecting an image applies it
3. `clingy wallpaper --effects` — rofi shows effects list, applying one creates `~/.cache/hypr/modified-wallpaper`
4. `clingy refresh` — waybar, swaync, ags restart
5. `clingy refresh --no-waybar` — only rofi killed, ags restarted, rainbow borders relaunched
6. `clingy` (interactive) — fzf menu shows "Wallpaper" and "Refresh" with submenus

**Bugs fixed:** B2, B3, B4, B6

---

### Step 4: Create Remaining Clingy Commands

**Objective:** Migrate all remaining shell scripts to Clingy commands.

**Files created:**
- `clingy/commands/blur.py`
- `clingy/commands/waybar.py`
- `clingy/commands/borders.py`
- `clingy/commands/screenshot.py`
- `clingy/commands/gamemode.py`
- `clingy/commands/wlogout.py`
- `clingy/commands/layout.py`
- `clingy/commands/clipboard.py`
- `clingy/commands/keyboard.py`
- `clingy/commands/lock.py`
- `clingy/commands/kill_window.py`
- `clingy/commands/airplane.py`
- `clingy/commands/music.py`

---

#### 4a. `commands/blur.py` — Blur Toggle

**Class:** `Blur(BaseCommand)` | **name:** `"blur"`

**CLI:**
```python
parser.add_argument("--toggle", action="store_true", help="Cycle blur passes (variant 1)")
parser.add_argument("--variant", type=int, choices=[1, 2, 3], default=1, help="Blur cycling variant")
```

**Menu:**
```
"Blur" > "Variant 1 (passes cycle)" / "Variant 2 (size cycle)" / "Variant 3 (passes, fixed size)"
```

**Logic:**
```
Merge change-blur.sh, change-blur-2.sh, change-blur-3.sh into one command.

Variant 1 (from change-blur.sh):
  Read current passes via hyprctl_get_option("decoration:blur:passes")
  Cycle: 0→2→3→4→5→6→0, always set size=1
  
Variant 2 (from change-blur-2.sh):
  Read current size via hyprctl_get_option("decoration:blur:size")
  Cycle: 0→2→4→6→8→10→0, passes always 2 (except size=0 → passes=1)

Variant 3 (from change-blur-3.sh):
  Read current passes via hyprctl_get_option("decoration:blur:passes")
  Cycle: 0→1→2→3→4→5→6→0, always set size=2

Each step: hyprctl_keyword("decoration:blur:size", val), hyprctl_keyword("decoration:blur:passes", val)
Notify with current state.
```

---

#### 4b. `commands/waybar.py` — Waybar Management

**Class:** `Waybar(BaseCommand)` | **name:** `"waybar"`

**CLI:**
```python
parser.add_argument("--layout", action="store_true", help="Switch waybar layout/config")
parser.add_argument("--style", action="store_true", help="Switch waybar visual style")
parser.add_argument("--cava", action="store_true", help="Start cava audio visualizer for waybar")
```

**Menu:**
```
"Waybar" > "Layout" / "Style" / "Cava Visualizer"
```

**Logic:**
```
_layout():
  1. List files in config.WAYBAR_CONFIGS (find -maxdepth 1 -type f)
  2. Show in rofi (config-waybar-layout.rasi)
  3. "no panel" → kill waybar
  4. Other → ln -sf selected to config.WAYBAR_CONFIG, call refresh

_style():
  1. List *.css files in config.WAYBAR_STYLES
  2. Show in rofi (config-waybar-style.rasi), strip .css extension for display
  3. ln -sf selected.css to config.WAYBAR_STYLE, call refresh

_cava():
  1. Write cava config to /tmp/bar_cava_config (same as waybar-cava.sh)
  2. Kill existing cava -p /tmp/bar_cava_config
  3. Start cava, pipe through sed substitution for bar characters
  (This is a streaming process — use subprocess.Popen, output to stdout)
```

---

#### 4c. `commands/borders.py` — Rainbow Borders

**Class:** `Borders(BaseCommand)` | **name:** `"borders"`

**CLI:**
```python
parser.add_argument("--rainbow", action="store_true", help="Apply wallust-colored rainbow borders")
```

**Menu:**
```
"Borders" > "Rainbow (wallust colors)"
```

**Logic:**
```
_rainbow():
  1. Source colors from config.WALLUST_COLORS_BASH
     Parse the file: read each line matching COLOR\d+=.*, extract hex values
  2. Convert each hex to 0xff{hex} format
  3. Run: hyprctl keyword general:col.active_border {C14} {C5} {C13} {C11} {C10} {C7} 90deg
     (Same color selection as current rainbow-borders.sh line 38)
```

---

#### 4d. `commands/screenshot.py` — Screenshot

**Class:** `Screenshot(BaseCommand)` | **name:** `"screenshot"`

**CLI:**
```python
group = parser.add_mutually_exclusive_group()
group.add_argument("--area", action="store_true", help="Screenshot selected area")
group.add_argument("--now", action="store_true", help="Screenshot entire screen")
group.add_argument("--window", action="store_true", help="Screenshot active window")
group.add_argument("--swappy", action="store_true", help="Screenshot area + edit with swappy")
group.add_argument("--in5", action="store_true", help="Screenshot in 5 seconds")
group.add_argument("--in10", action="store_true", help="Screenshot in 10 seconds")
```

**Menu:**
```
"Screenshot" > "Area" / "Full Screen" / "Active Window" / "Swappy (edit)" / "In 5s" / "In 10s"
```

**Logic:**
```
Port of screenshot.sh. Key differences:
- Use config.SCREENSHOT_DIR instead of hardcoded path
- Import sounds.play_sound("screenshot") instead of calling sounds.sh
- Use pathlib for file operations
- Filename: Screenshot_{timestamp}_{random}.png

_area(): grim -g "$(slurp)" → tee to file + wl-copy
_now(): grim → tee to file + wl-copy
_window(): hyprctl -j activewindow → parse geometry → grim -g
_swappy(): grim -g "$(slurp)" → tmpfile → swappy -f
_countdown(n): loop notify-send with timer, sleep 1
```

---

#### 4e. `commands/gamemode.py` — Gamemode Toggle

**Class:** `Gamemode(BaseCommand)` | **name:** `"gamemode"`

**CLI:**
```python
parser.add_argument("--toggle", action="store_true", default=True, help="Toggle gamemode")
```

**Menu:**
```
"Gamemode" > "Toggle" (single action, no submenu needed)
```

**Logic:**
```
_toggle():
  1. Check: hyprctl_get_option("animations:enabled") → current state
  2. If enabled (1):
     - hyprctl --batch: disable animations, drop_shadow, blur passes=0, gaps=0, border=1, rounding=0
     - swww kill
     - Notify "Gamemode ON"
  3. If disabled (0):
     - swww_ensure_daemon()
     - swww_set_wallpaper(config.CURRENT_WALLPAPER)  # restore from cache symlink
     - Call refresh
     - Notify "Gamemode OFF"
```

---

#### 4f. `commands/wlogout.py` — Wlogout

**Class:** `Wlogout(BaseCommand)` | **name:** `"wlogout"`

**CLI:** No arguments (just `clingy wlogout`).

**Menu:**
```
"Wlogout" (leaf node, direct action)
```

**Logic:**
```
Port of wlogout.sh:
1. If wlogout already running → pkill wlogout, return
2. Get resolution: hyprctl -j monitors → focused monitor → height/scale
3. Calculate T_val and B_val based on resolution thresholds (same breakpoints as wlogout.sh)
4. Run: wlogout --protocol layer-shell -b 6 -T {T_val} -B {B_val} &
```

---

#### 4g. `commands/layout.py` — Layout Switcher

**Class:** `Layout(BaseCommand)` | **name:** `"layout"`

**CLI:**
```python
parser.add_argument("--change", action="store_true", help="Cycle through hy3 → dwindle → master")
```

**Menu:**
```
"Layout" > "Cycle (hy3 → dwindle → master)"
```

**Logic:**
```
Port of change-layout.sh:
1. Get current: hyprctl_get_option("general:layout") → .str
2. Cycle: hy3 → dwindle → master → hy3
3. For each layout, set appropriate keybinds via hyprctl keyword bind/unbind
   (same bind changes as change-layout.sh)
4. Notify new layout name
```

---

#### 4h. `commands/clipboard.py` — Clipboard Manager

**Class:** `Clipboard(BaseCommand)` | **name:** `"clipboard"`

**CLI:** No arguments (just `clingy clipboard`).

**Menu:**
```
"Clipboard" (leaf node, direct action)
```

**Logic:**
```
Port of clip-manager.sh:
1. Kill existing rofi if running
2. Loop:
   a. Run: cliphist list | rofi -i -dmenu -config config-clipboard.rasi
      with -kb-custom-1 "Control-Delete" -kb-custom-2 "Alt-Delete"
   b. Exit code 0 + non-empty → cliphist decode | wl-copy, break
   c. Exit code 10 → cliphist delete entry, continue loop
   d. Exit code 11 → cliphist wipe, continue loop
   e. Exit code 1 → break (cancelled)

NOTE: This command heavily relies on rofi's custom keybind exit codes.
Implement using subprocess with check=False and inspect returncode.
```

---

#### 4i. `commands/keyboard.py` — Keyboard Layout Switcher

**Class:** `Keyboard(BaseCommand)` | **name:** `"keyboard"`

**CLI:**
```python
parser.add_argument("--switch", action="store_true", help="Cycle to next keyboard layout")
```

**Menu:**
```
"Keyboard" > "Switch Layout"
```

**Logic:**
```
Port of switch-keyboard-layout.sh:
1. Read current layout from ~/.cache/kb_layout (create with "us" default if missing)
2. Read available layouts from settings file (kb_layout line, comma-separated)
   NOTE: Original reads from UserConfigs/UserSettings.conf which doesn't exist.
   In the clingy version, read from hyprctl -j getoption input:kb_layout instead.
3. Find current index, advance to next (modulo)
4. For each keyboard device (hyprctl devices -j → .keyboards[].name):
   hyprctl switchxkblayout {name} {new_layout}
5. Save new layout to ~/.cache/kb_layout
6. Notify new layout
```

---

#### 4j. `commands/lock.py` — Lock Screen

**Class:** `Lock(BaseCommand)` | **name:** `"lock"`

**CLI:** No arguments.

**Menu:**
```
"Lock Screen" (leaf node)
```

**Logic:**
```
Simple: if not pidof hyprlock → run hyprlock -q
(Same as lock-screen.sh, one-liner)
```

---

#### 4k. `commands/kill_window.py` — Kill Active Window Process

**Class:** `KillWindow(BaseCommand)` | **name:** `"kill-window"`

**CLI:** No arguments.

**Menu:**
```
"Kill Active Window" (leaf node)
```

**Logic:**
```
1. hyprctl -j activewindow → parse .pid
2. os.kill(pid, signal.SIGTERM)
```

---

#### 4l. `commands/airplane.py` — Airplane Mode

**Class:** `Airplane(BaseCommand)` | **name:** `"airplane"`

**CLI:**
```python
parser.add_argument("--toggle", action="store_true", default=True, help="Toggle airplane mode")
```

**Menu:**
```
"Airplane Mode" > "Toggle"
```

**Logic:**
```
1. Check: rfkill list wifi | grep "Soft blocked: yes"
2. If blocked → rfkill unblock wifi, notify "OFF"
3. If not blocked → rfkill block wifi, notify "ON"
```

---

#### 4m. `commands/music.py` — Music Player

**Class:** `Music(BaseCommand)` | **name:** `"music"`

**CLI:**
```python
group = parser.add_mutually_exclusive_group()
group.add_argument("--local", action="store_true", help="Play from local music folder")
group.add_argument("--online", action="store_true", help="Play from online stations")
group.add_argument("--shuffle", action="store_true", help="Shuffle local music")
group.add_argument("--stop", action="store_true", help="Stop music")
```

**Menu:**
```
"Music" > "Online Stations" / "Local Music" / "Shuffle Local" / "Stop"
```

**Logic:**
```
Port of music.sh:
- Online stations dict defined as class constant (same URLs as music.sh)
- _online(): show stations in rofi (config-rofi-Beats.rasi), play with mpv --vid=no --ytdl-format=bestaudio
- _local(): find music files in config.MUSIC_DIR, show in rofi, play with mpv --playlist-start
- _shuffle(): mpv --shuffle --loop-playlist --vid=no config.MUSIC_DIR
- _stop(): pkill mpv, notify "Music stopped"
- Default (no args): if mpv running → stop, else show source selection rofi menu
```

---

**Verification for Step 4:**
1. `clingy blur --toggle` — blur cycles through passes
2. `clingy waybar --layout` — rofi shows waybar configs
3. `clingy screenshot --area` — slurp opens, screenshot saved
4. `clingy gamemode` — animations toggle off/on
5. `clingy` (interactive) — fzf menu shows ALL commands with proper hierarchy

---

### Step 5: Update Hyprland Configs to Consume from `~/.cache/hypr/`

**Objective:** Point all Hyprland-side config files to the new cache paths.

**Files modified:**
- `hypr/hyprlock.conf`
- `hypr/configs/settings.conf`

**Changes to `hyprlock.conf` (fixes B1):**
- Line 6: `source = $HOME/.config/hypr/wallust/wallust-hyprland.conf` → `source = $HOME/.cache/hypr/wallust/wallust-hyprland.conf`
- Line 16: `path = $HOME/.config/rofi/.current_wallpaper` → `path = $HOME/.cache/hypr/current-wallpaper`

**Changes to `settings.conf`:**
- Line 5: `source = $HOME/.cache/wallust/wallust-hyprland.conf` → `source = $HOME/.cache/hypr/wallust/wallust-hyprland.conf`

**Verification:**
1. `hyprctl reload` — no errors about missing source files
2. Lock screen — wallpaper background loads, colors applied
3. Border colors match wallust palette

**Bugs fixed:** B1

---

### Step 6: Update External Config Consumers (Rofi, Waybar, SwayNC)

**Objective:** Fix all broken wallust color import paths. Highest file-count step.

**Files modified:**

#### Waybar Styles (fixes B7)

**16 files** — change `@import '../../.config/waybar/wallust/colors-waybar.css'` to `@import '../../.cache/hypr/wallust/colors-waybar.css'`:

1. `waybar/style/[Wallust] Chroma Edge.css`
2. `waybar/style/[Extra] Modern-Combined.css`
3. `waybar/style/[WALLUST] ML4W-modern.css`
4. `waybar/style/[Dark] Wallust Obsidian Edge.css`
5. `waybar/style/[Wallust] Colored.css`
6. `waybar/style/[Dark] Latte-Wallust combined v2.css`
7. `waybar/style/[Wallust] Chroma Tally.css`
8. `waybar/style/[Wallust] Box type.css`
9. `waybar/style/[Wallust] Chroma Fusion.css`
10. `waybar/style/[Wallust] Simple.css`
11. `waybar/style/[Wallust Bordered] Chroma Fusion Edge.css`
12. `waybar/style/[Dark] Latte-Wallust combined.css`
13. `waybar/style/[Extra] Modern-Combined - Transparent.css`
14. `waybar/style/[Wallust] Chroma Tally V2.css`
15. `waybar/style/[Wallust Transparent] Crystal Clear.css`
16. `waybar/style/[Wallust Bordered] Chroma Simple.css`

**2 files** — change `@import '../../.cache/wallust/colors-waybar.css'` to `@import '../../.cache/hypr/wallust/colors-waybar.css'`:

17. `waybar/style.css` (line 4)
18. `waybar/style/[WALLUST] ML4W-modern-mixed.css` (line 4)

#### Rofi Themes (fixes B8)

**10 files** — change `@theme "~/.config/rofi/wallust/colors-rofi.rasi"` to `@theme "~/.cache/hypr/wallust/colors-rofi.rasi"`:

1. `rofi/themes/KooL_style-1.rasi`
2. `rofi/themes/KooL_style-3-FullScreen-v1.rasi`
3. `rofi/themes/KooL_style-3-Fullscreen-v2.rasi`
4. `rofi/themes/KooL_style-4.rasi`
5. `rofi/themes/KooL_style-5.rasi`
6. `rofi/themes/KooL_style-6.rasi`
7. `rofi/themes/KooL_style-7.rasi`
8. `rofi/themes/KooL_style-8.rasi`
9. `rofi/themes/KooL_style-9.rasi`
10. `rofi/themes/KooL_style-13-Vertical.rasi`

**1 file** — change `@import "~/.cache/wallust/colors-rofi.rasi"` to `@import "~/.cache/hypr/wallust/colors-rofi.rasi"`:

11. `rofi/themes/windows-11-black.rasi`

**Rofi wallpaper background paths** — change `url("~/.config/rofi/.current_wallpaper", width)` to `url("~/.cache/hypr/current-wallpaper", width)` in the 6 KooL_style files that reference it (check each file for the exact line).

**Rofi effects preview** — change `url("~/.config/hypr/wallpaper_effects/.wallpaper_modified", width)` to `url("~/.cache/hypr/modified-wallpaper", width)` in `rofi/config-wallpaper-effect.rasi`.

#### SwayNC (fixes B9)

**1 file** — `swaync/style.css` line 2:
- Change: `@import url("file:///home/ncasatti/.cache/wallust/colors-swaync.css")`
- To: `@import url("file:///home/ncasatti/.cache/hypr/wallust/colors-swaync.css")`
- Note: Username remains hardcoded — GTK CSS `@import url(file://)` does not support `$HOME`. Documented as known limitation.

**SwayNC old theme** — `swaync/old-theme/style.css` line 4:
- Change: `@import '../../.config/waybar/wallust/colors-waybar.css'`
- To: `@import '../../.cache/hypr/wallust/colors-waybar.css'`

**Verification:**
1. `wallust run <wallpaper> -s` to generate fresh colors
2. Launch rofi with a KooL_style theme — colors load, wallpaper background visible
3. Restart waybar — wallust colors applied (no white/unstyled fallback)
4. Restart swaync — themed colors in notification center

**Bugs fixed:** B7, B8, B9

---

### Step 7: Update Hyprland Keybinds to Call Clingy

**Objective:** Replace all script references in keybinds with `clingy` CLI calls.

**Files modified:**
- `hypr/configs/keybinds.conf`
- `hypr/configs/startup.conf`

**Changes to `keybinds.conf`:**

The `$scripts` variable stays but is now ONLY used for hardware scripts:
```
$scripts = $HOME/.config/hypr/scripts
```

| Line | Old | New |
|------|-----|-----|
| 19 | `$scripts/theme/wallpaper-random.sh` | `clingy wallpaper --random` |
| 20 | `$scripts/theme/change-blur.sh` | `clingy blur --toggle` |
| 24 | `$scripts/theme/wallpaper-select.sh` | `clingy wallpaper --select` |
| 25 | `$scripts/system/lock-screen.sh` | `clingy lock` |
| 26 | `$scripts/system/refresh.sh` | `clingy refresh` |
| 32 | `$scripts/utils/screenshot.sh --area` | `clingy screenshot --area` |
| 33 | `$scripts/utils/screenshot.sh --now` | `clingy screenshot --now` |
| 34 | `$scripts/utils/gamemode.sh` | `clingy gamemode` |
| 50 | `$scripts/utils/music.sh` | `clingy music` |
| 58 | `$scripts/system/kill-active-process.sh` | `clingy kill-window` |

**Changes to `startup.conf`:**

| Line | Old | New |
|------|-----|-----|
| 35 | `$scripts/theme/rainbow-borders.sh &` | `clingy borders --rainbow &` |
| 6 | `$SwwwRandom = $scripts/theme/wallpaper-autochange.sh` | `$SwwwRandom = clingy wallpaper --autochange` |

Note: `autostart.sh`, `polkit.sh` references stay as-is (boot scripts).

**Verification:**
1. `hyprctl reload`
2. Press `Alt+Shift+W` — random wallpaper changes
3. Press `Ctrl+Alt+W` — rofi wallpaper selector opens
4. Press `Ctrl+Alt+R` — system refreshes
5. Press `Super+Shift+Ctrl+P` — area screenshot works

---

### Step 8: Add `CLINGY_ROOT` to env.conf + Home Manager Cache Bootstrap

**Objective:** Ensure clingy works from keybinds (which have no shell context) and cache dirs exist on fresh boot.

**Files modified:**
- `hypr/configs/env.conf`
- `home.nix` (at `/home/ncasatti/.the-grid/the-tower/home.nix`)

**Changes to `env.conf`:**

Add at the end of the file:
```
# Clingy CLI framework
env = CLINGY_ROOT,/home/ncasatti/.the-grid/clingy
```

**Changes to `home.nix`:**

Add a new activation entry (after `copyRcloneConfig`, before `refreshSystem`):
```nix
home.activation.createHyprCache = config.lib.dag.entryAfter [ "writeBoundary" ] ''
  mkdir -p "$HOME/.cache/hypr/wallust"
'';
```

**Verification:**
1. `home-manager switch` — no errors, `~/.cache/hypr/wallust/` exists
2. Open new Hyprland session — `echo $CLINGY_ROOT` shows correct path
3. Keybinds work (clingy finds its project root via `CLINGY_ROOT`)

---

### Step 9: Clean Up Dead Artifacts and Migrated Scripts

**Objective:** Remove all dead code, stale snapshots, and migrated shell scripts from the repository.

**Items to delete:**

| Item | Reason |
|------|--------|
| `hypr/.configs/` (entire directory) | Dead JaKooLit symlink system |
| `hypr/wallust/` (entire directory) | Stale color snapshots |
| `hypr/wallpaper_effects/` (entire directory) | Runtime files, now in `~/.cache/hypr/` |
| `waybar/wallust/` (entire directory) | Stale snapshot |
| `hypr/scripts/theme/` (entire directory) | All scripts migrated to clingy |
| `hypr/scripts/system/refresh.sh` | Migrated to `clingy refresh` |
| `hypr/scripts/system/wlogout.sh` | Migrated to `clingy wlogout` |
| `hypr/scripts/system/lock-screen.sh` | Migrated to `clingy lock` |
| `hypr/scripts/system/kill-active-process.sh` | Migrated to `clingy kill-window` |
| `hypr/scripts/system/airplane-mode.sh` | Migrated to `clingy airplane` |
| `hypr/scripts/settings/change-layout.sh` | Migrated to `clingy layout` |
| `hypr/scripts/settings/clip-manager.sh` | Migrated to `clingy clipboard` |
| `hypr/scripts/settings/switch-keyboard-layout.sh` | Migrated to `clingy keyboard` |
| `hypr/scripts/settings/refresh-no-waybar.sh` | Absorbed into `clingy refresh --no-waybar` |
| `hypr/scripts/utils/screenshot.sh` | Migrated to `clingy screenshot` |
| `hypr/scripts/utils/gamemode.sh` | Migrated to `clingy gamemode` |
| `hypr/scripts/utils/music.sh` | Migrated to `clingy music` |
| `hypr/scripts/utils/sounds.sh` | Migrated to `commands/utils/sounds.py` |
| `hypr/scripts/utils/uptime-nixos.sh` | Only used by hyprlock label, keep or inline |

**Items to KEEP:**
- `hypr/scripts/hardware/` (all 5 files) — latency-critical
- `hypr/scripts/system/autostart.sh` — boot script
- `hypr/scripts/system/polkit.sh` — boot script
- `hypr/scripts/system/polkit-nixos.sh` — boot script
- `hypr/scripts/system/portal-hyprland.sh` — boot script
- `hypr/scripts/utils/uptime-nixos.sh` — used by hyprlock label (evaluate: keep or inline)

**Add to `.gitignore`** (at repo root, create if not exists):
```
# Runtime artifacts — never commit
hypr/wallpaper_effects/
rofi/.current_wallpaper
waybar/wallust/
```

**Verification:**
1. `git status` — shows deletions, no unexpected changes
2. `git grep '.configs/'` — no hits in any active file
3. `git grep 'hypr/wallust/'` — no hits
4. `git grep 'wallpaper_effects/'` — no hits in scripts
5. Full end-to-end test: change wallpaper, apply effects, toggle blur, take screenshot, toggle gamemode — all via clingy

---

### Step 10: Update Documentation

**Objective:** Update the Hyprland README and CLAUDE.md to reflect the new architecture.

**Files modified:**
- `hypr/README.md`
- `hypr/CLAUDE.md`

**Changes to `README.md`:**
- Document the new clingy-based workflow
- List all available commands with CLI and menu usage
- Document which scripts remain as shell (hardware/)
- Document the `~/.cache/hypr/` structure
- Remove references to deleted scripts/directories

**Changes to `CLAUDE.md`:**
- Update "Script Organization" section to reflect clingy commands
- Update "Essential Commands" with clingy equivalents
- Update "Wallpaper Workflow" to describe the unified `_apply_wallpaper()` pipeline
- Update "File Modification Workflow" to mention clingy
- Remove references to deleted directories
- Add section on clingy command development pattern

**Verification:**
- Read both files, verify no references to deleted paths or scripts

---

## 4. Dependency Graph

```
Step 1 (config.py)
  ↓
Step 2 (wallust.toml) ─────────────────────────────────┐
  ↓                                                      │
Step 3 (wallpaper + refresh + utils) ──→ Step 4 (all other commands)
  ↓                                          ↓           │
Step 5 (hyprland configs) ←──────────────────┘           │
  ↓                                                      │
Step 6 (rofi/waybar/swaync) ←────────────────────────────┘
  ↓
Step 7 (keybinds)
  ↓
Step 8 (env.conf + home.nix)
  ↓
Step 9 (cleanup)
  ↓
Step 10 (docs)
```

Steps 1-8 are additive — the system remains functional after each step because old scripts still exist until Step 9. Step 9 is purely subtractive and must come after keybinds are updated. Step 10 is documentation-only.

---

## 5. Risk Assessment

| Risk | Mitigation |
|------|-----------|
| Clingy startup latency for keybinds | Python cold start ~100-200ms. Acceptable for wallpaper/screenshot. Hardware keys stay as shell. |
| `CLINGY_ROOT` not set in Hyprland env | Step 8 adds it to `env.conf`. Requires Hyprland restart to take effect. |
| Wallust fails if cache dir missing | `ensure_cache_dirs()` called at start of every command that writes. Home Manager activation also creates it. |
| Rofi/Waybar unstyled on first boot | Same as current behavior — colors only exist after first wallpaper change. |
| swaync hardcoded username | GTK CSS limitation. Documented. |
| Old `~/.cache/wallust/` persists | Not harmful — wallust no longer writes there. Can be manually cleaned. |
| Autochange daemon management | Document that `clingy wallpaper --autochange` is a long-running process. Keybind should use `&`. |
| Commands import config.py from wrong location | `CLINGY_ROOT` ensures clingy resolves project root correctly. |

---

## 6. Files Changed Summary

| Step | Files Created | Files Modified | Files Deleted |
|------|--------------|---------------|---------------|
| 1 | 0 | 1 (config.py) | 0 |
| 2 | 0 | 1 (wallust.toml) | 0 |
| 3 | 5 (utils/__init__.py, utils/hypr.py, utils/sounds.py, wallpaper.py, refresh.py) | 0 | 0 |
| 4 | 13 (blur, waybar, borders, screenshot, gamemode, wlogout, layout, clipboard, keyboard, lock, kill_window, airplane, music) | 0 | 0 |
| 5 | 0 | 2 (hyprlock.conf, settings.conf) | 0 |
| 6 | 0 | ~32 (18 waybar + 12 rofi + 2 swaync) | 0 |
| 7 | 0 | 2 (keybinds.conf, startup.conf) | 0 |
| 8 | 0 | 2 (env.conf, home.nix) | 0 |
| 9 | 0 | 1 (.gitignore) | 4 dirs + ~18 scripts |
| 10 | 0 | 2 (README.md, CLAUDE.md) | 0 |
| **Total** | **18 files** | **~43 files** | **4 dirs + ~18 scripts** |
