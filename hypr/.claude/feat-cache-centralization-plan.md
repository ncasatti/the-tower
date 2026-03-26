# SDD: Hyprland Cache Centralization

> **Status:** PENDING APPROVAL  
> **Author:** CLU (Technical Planner)  
> **Date:** 2026-03-26  
> **Scope:** Centralize all runtime/mutable files under `~/.cache/hypr/`, fix 8 verified bugs, remove dead artifacts.

---

## 1. Objective

Separate immutable configuration (managed by Nix Home Manager, stored in the git repo) from mutable runtime state (wallpaper symlinks, processed images, wallust color outputs). All dynamic files will be consolidated under `~/.cache/hypr/` to eliminate path fragmentation, fix stale references, and prevent binary/runtime artifacts from polluting the git repository.

### Target Cache Structure

```
~/.cache/hypr/
├── current-wallpaper          # symlink → active wallpaper image
├── modified-wallpaper         # ImageMagick-processed wallpaper
└── wallust/                   # wallust color output (relocated from ~/.cache/wallust/)
    ├── wallust-hyprland.conf
    ├── colors-rofi.rasi
    ├── colors-waybar.css
    ├── colors-kitty.conf
    ├── colors-bash.sh
    ├── colors-swaync.css
    └── colors-cava (cava config)
```

---

## 2. Architecture / Approach

### Principles

1. **Single Source of Truth for Paths:** Every script and config file references `~/.cache/hypr/` for runtime data. No exceptions.
2. **Idempotent Cache Bootstrap:** Scripts ensure `~/.cache/hypr/` and `~/.cache/hypr/wallust/` exist via `mkdir -p` before any write operation. Home Manager activation also creates these directories on `home-manager switch`.
3. **No Intermediate Breakage:** Steps are ordered so the system remains functional after each step. The wallust.toml target paths are updated first (Step 1), then consumers are updated to read from the new paths (Steps 2-5), then dead code is removed last (Step 7).
4. **Wallpaper Pipeline Consolidation:** The wallpaper change flow is unified: `wallpaper-colors.sh` is the single authority for creating the `current-wallpaper` symlink, running wallust, and copying the wallpaper for effects. All entry points (`wallpaper-select.sh`, `wallpaper-random.sh`, `wallpaper-autochange.sh`) must call it.

### Verified Bug Inventory

| # | Bug | Location | Root Cause |
|---|-----|----------|------------|
| B1 | hyprlock sources stale repo snapshot for colors | `hyprlock.conf:6` | Sources `$HOME/.config/hypr/wallust/wallust-hyprland.conf` (repo copy) instead of `~/.cache/wallust/wallust-hyprland.conf` (wallust output) |
| B2 | wallpaper-random.sh runs wallust TWICE | `wallpaper-random.sh:29,31` | Line 29 runs `wallust run` directly, then line 31 calls `wallpaper-colors.sh` which runs wallust again — race condition |
| B3 | wallpaper-effects.sh references `Refresh.sh` (capital R) | `wallpaper-effects.sh:51,87` | Actual file is `refresh.sh` (lowercase) at `scripts/system/refresh.sh` — broken on case-sensitive Linux |
| B4 | wallpaper-autochange.sh never updates symlink/colors | `wallpaper-autochange.sh:34-35` | Only calls `swww img` + `refresh-no-waybar.sh`, never calls `wallpaper-colors.sh` so `current-wallpaper` and wallust colors never update |
| B5 | wallpaper-autochange.sh — `RefreshNoWaybar.sh` path | `wallpaper-autochange.sh:10` | **VERIFIED FIXED.** Currently references `$HOME/.config/hypr/scripts/settings/refresh-no-waybar.sh` which exists. No action needed. |
| B6 | Inconsistent wallpaper directories | `wallpaper-select.sh:7` vs `wallpaper-random.sh:7` | `wallpaper-select.sh` uses `$HOME/.config/konfig/themes/wallpapers`, `wallpaper-random.sh` uses `$HOME/Pictures/wallpapers` |
| B7 | 16 waybar styles reference non-existent path | 16 files in `waybar/style/` | Import `../../.config/waybar/wallust/colors-waybar.css` — this path does NOT exist as a wallust output target. Should be `../../.cache/hypr/wallust/colors-waybar.css` |
| B8 | 10 rofi KooL_style themes reference non-existent path | 10 files in `rofi/themes/` | Import `~/.config/rofi/wallust/colors-rofi.rasi` — this path does NOT exist as a wallust output target. Should be `~/.cache/hypr/wallust/colors-rofi.rasi` |
| B9 | swaync/style.css has hardcoded absolute path | `swaync/style.css:2` | Uses `file:///home/ncasatti/.cache/wallust/colors-swaync.css` — hardcoded username, should use relative or `$HOME` equivalent |

### Dead Artifacts Inventory

| Artifact | Location | Reason for Removal |
|----------|----------|-------------------|
| `hypr/.configs/` | Entire directory | Dead JaKooLit symlink mechanism. `create_links.sh` has all calls commented out. Contains duplicate rofi themes, gtk configs, kitty, Kvantum, keyd, hyprshade — all now managed by Nix Home Manager |
| `hypr/wallust/` | `wallust-hyprland.conf`, `colors-bash.sh` | Stale rendered color snapshots. NOT wallust output targets — wallust writes to `~/.cache/wallust/`. These are never-updated repo copies that cause confusion (B1) |
| `hypr/wallpaper_effects/` | `.wallpaper_current`, `.wallpaper_modified`, `.conflict1`, `.conflict2` | Runtime-only directory. Should only exist in `~/.cache/hypr/`. Conflict files are orphan sync artifacts |
| `waybar/wallust/colors-waybar.css` | Stale snapshot | Same pattern as `hypr/wallust/` — a repo copy of wallust output that is never updated at runtime |

---

## 3. Execution Steps

### Step 1: Update wallust.toml Output Targets

**Objective:** Redirect all wallust output from `~/.cache/wallust/` to `~/.cache/hypr/wallust/`.

**Files modified:**
- `wallust/wallust.toml`

**Changes:**
- Change ALL 7 active `target` values from `~/.cache/wallust/` prefix to `~/.cache/hypr/wallust/` prefix:
  - `hypr.target`: `'~/.cache/wallust/wallust-hyprland.conf'` → `'~/.cache/hypr/wallust/wallust-hyprland.conf'`
  - `rofi.target`: `'~/.cache/wallust/colors-rofi.rasi'` → `'~/.cache/hypr/wallust/colors-rofi.rasi'`
  - `waybar.target`: `'~/.cache/wallust/colors-waybar.css'` → `'~/.cache/hypr/wallust/colors-waybar.css'`
  - `kitty.target`: `'~/.cache/wallust/colors-kitty.conf'` → `'~/.cache/hypr/wallust/colors-kitty.conf'`
  - `bash.target`: `'~/.cache/wallust/colors-bash.sh'` → `'~/.cache/hypr/wallust/colors-bash.sh'`
  - `swaync.target`: `'~/.cache/wallust/colors-swaync.css'` → `'~/.cache/hypr/wallust/colors-swaync.css'`
  - `cava.target`: Leave as `'~/.config/cava/config'` (cava requires its config at this exact path — this is a special case, not a wallust color file)

**Verification:**
1. Run `mkdir -p ~/.cache/hypr/wallust/`
2. Run `wallust run <any-wallpaper> -s`
3. Verify files appear in `~/.cache/hypr/wallust/` (not `~/.cache/wallust/`)
4. Verify `ls ~/.cache/hypr/wallust/` shows all 6 expected files

---

### Step 2: Update Core Wallpaper Pipeline Scripts

**Objective:** Centralize wallpaper symlink and copy paths to `~/.cache/hypr/`, fix the duplicate wallust call in `wallpaper-random.sh`, fix the missing `wallpaper-colors.sh` call in `wallpaper-autochange.sh`, and unify the wallpaper source directory.

**Files modified:**
- `hypr/scripts/theme/wallpaper-colors.sh`
- `hypr/scripts/theme/wallpaper-random.sh`
- `hypr/scripts/theme/wallpaper-autochange.sh`

**Changes to `wallpaper-colors.sh`:**
- Add `mkdir -p "$HOME/.cache/hypr"` near the top of the script (after the `cache_dir` variable declaration)
- Line 27: Change symlink target from `"$HOME/.config/rofi/.current_wallpaper"` to `"$HOME/.cache/hypr/current-wallpaper"`
- Line 31: Change copy destination from `"$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"` to `"$HOME/.cache/hypr/current-wallpaper-copy"` (this is the unmodified copy used by wallpaper-effects.sh as its input source)

**Changes to `wallpaper-random.sh` (fixes B2 + B6):**
- Line 7: Change `wallpaper_dir` from `"$HOME/Pictures/wallpapers"` to `"$HOME/.config/konfig/themes/wallpapers"` (unify with `wallpaper-select.sh`)
- **Delete line 29** (`wallust run $RANDOMPIC -s &`) — this is the duplicate wallust call. `wallpaper-colors.sh` on line 31 already runs wallust.

**Changes to `wallpaper-autochange.sh` (fixes B4):**
- After line 34 (`swww img -o $focused_monitor "$img"`), add a call to `$HOME/.config/hypr/scripts/theme/wallpaper-colors.sh` BEFORE the existing `$wallust_refresh` call. This ensures the symlink, wallpaper copy, and wallust colors are all updated for each rotation.

**Verification:**
1. Run `wallpaper-random.sh` — verify `~/.cache/hypr/current-wallpaper` is a symlink pointing to the selected wallpaper
2. Verify `~/.cache/hypr/current-wallpaper-copy` is a regular file (copy of the wallpaper)
3. Verify wallust only runs ONCE (check with `journalctl --user -g wallust` or observe timing)
4. Run `wallpaper-autochange.sh <wallpaper-dir>` — verify symlink updates on each rotation

---

### Step 3: Update Wallpaper Effects Script

**Objective:** Point wallpaper-effects.sh to the new cache paths and fix the broken `Refresh.sh` reference.

**Files modified:**
- `hypr/scripts/theme/wallpaper-effects.sh`

**Changes:**
- Line 7: Change `current_wallpaper` from `"$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"` to `"$HOME/.cache/hypr/current-wallpaper-copy"`
- Line 8: Change `wallpaper_output` from `"$HOME/.config/hypr/wallpaper_effects/.wallpaper_modified"` to `"$HOME/.cache/hypr/modified-wallpaper"`
- Line 51 (inside `no-effects` function): Change `"${SCRIPTSDIR}/Refresh.sh"` to `"${SCRIPTSDIR}/system/refresh.sh"` (fixes B3 — lowercase + correct subdirectory)
- Line 87 (inside `main` function, after applying effects): Change `"${SCRIPTSDIR}/Refresh.sh"` to `"${SCRIPTSDIR}/system/refresh.sh"` (same fix, second occurrence)
- Note: `SCRIPTSDIR` on line 9 is `"$HOME/.config/hypr/scripts"` — the refresh script is at `scripts/system/refresh.sh`, so the correct call is `"${SCRIPTSDIR}/system/refresh.sh"`

**Verification:**
1. Run `wallpaper-effects.sh`, select "Blurred" effect
2. Verify `~/.cache/hypr/modified-wallpaper` exists and is a processed image
3. Verify the refresh completes without "command not found" errors (B3 fix)

---

### Step 4: Update Hyprland Config Consumers (hyprlock, settings.conf, gamemode, rainbow-borders)

**Objective:** Point all Hyprland-side config files and utility scripts to the new `~/.cache/hypr/` paths.

**Files modified:**
- `hypr/hyprlock.conf`
- `hypr/configs/settings.conf`
- `hypr/scripts/utils/gamemode.sh`
- `hypr/scripts/theme/rainbow-borders.sh`

**Changes to `hyprlock.conf` (fixes B1):**
- Line 6: Change `source = $HOME/.config/hypr/wallust/wallust-hyprland.conf` to `source = $HOME/.cache/hypr/wallust/wallust-hyprland.conf`
- Line 16: Change `path = $HOME/.config/rofi/.current_wallpaper` to `path = $HOME/.cache/hypr/current-wallpaper`

**Changes to `settings.conf`:**
- Line 5: Change `source = $HOME/.cache/wallust/wallust-hyprland.conf` to `source = $HOME/.cache/hypr/wallust/wallust-hyprland.conf`

**Changes to `gamemode.sh`:**
- Line 23: Change `swww img "$HOME/.config/rofi/.current_wallpaper"` to `swww img "$HOME/.cache/hypr/current-wallpaper"`

**Changes to `rainbow-borders.sh`:**
- Line 2: Change `source "$HOME/.cache/wallust/colors-bash.sh"` to `source "$HOME/.cache/hypr/wallust/colors-bash.sh"`

**Verification:**
1. Run `hyprctl reload` — verify no errors about missing source files
2. Lock screen (`hyprlock`) — verify wallpaper background loads and colors are applied
3. Toggle gamemode on then off — verify wallpaper restores correctly
4. Verify rainbow borders still cycle through wallust colors

---

### Step 5: Update External Config Consumers (Rofi, Waybar, SwayNC)

**Objective:** Fix all broken wallust color import paths in rofi themes, waybar styles, and swaync. This is the highest-file-count step.

**Files modified:**

**Rofi themes — wallust colors path (fixes B8):**
Update `@theme` import from `"~/.config/rofi/wallust/colors-rofi.rasi"` to `"~/.cache/hypr/wallust/colors-rofi.rasi"` in these 10 files:
1. `rofi/themes/KooL_style-1.rasi` (line 21)
2. `rofi/themes/KooL_style-3-FullScreen-v1.rasi` (line 21)
3. `rofi/themes/KooL_style-3-Fullscreen-v2.rasi` (line 22)
4. `rofi/themes/KooL_style-4.rasi` (line 21)
5. `rofi/themes/KooL_style-5.rasi` (line 21)
6. `rofi/themes/KooL_style-6.rasi` (line 21)
7. `rofi/themes/KooL_style-7.rasi` (line 21)
8. `rofi/themes/KooL_style-8.rasi` (line 21)
9. `rofi/themes/KooL_style-9.rasi` (line 21)
10. `rofi/themes/KooL_style-13-Vertical.rasi` (line 21)

**Rofi themes — already correct (no change needed):**
- `rofi/themes/windows-11-black.rasi` (line 5) — currently `@import "~/.cache/wallust/colors-rofi.rasi"` → update to `@import "~/.cache/hypr/wallust/colors-rofi.rasi"`
  (This one IS reading from cache, but the old cache path. Still needs updating.)

So **11 rofi theme files** total for the wallust path.

**Rofi themes — wallpaper background image path:**
Update `url("~/.config/rofi/.current_wallpaper", width)` to `url("~/.cache/hypr/current-wallpaper", width)` in these 6 files:
1. `rofi/themes/KooL_style-1.rasi` (line 76)
2. `rofi/themes/KooL_style-3-FullScreen-v1.rasi` (line 90)
3. `rofi/themes/KooL_style-5.rasi` (line 66)
4. `rofi/themes/KooL_style-6.rasi` (line 77)
5. `rofi/themes/KooL_style-8.rasi` (line 67)
6. `rofi/themes/KooL_style-13-Vertical.rasi` (line 103)

**Rofi config — wallpaper effects preview:**
- `rofi/config-wallpaper-effect.rasi` (line 37): Change `url("~/.config/hypr/wallpaper_effects/.wallpaper_modified", width)` to `url("~/.cache/hypr/modified-wallpaper", width)`

**Waybar styles — broken path (fixes B7):**
Update `@import '../../.config/waybar/wallust/colors-waybar.css'` to `@import '../../.cache/hypr/wallust/colors-waybar.css'` in these 16 files:
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

**Waybar styles — old cache path (still needs updating):**
Update `@import '../../.cache/wallust/colors-waybar.css'` to `@import '../../.cache/hypr/wallust/colors-waybar.css'` in these 2 files:
1. `waybar/style.css` (line 4)
2. `waybar/style/[WALLUST] ML4W-modern-mixed.css` (line 4)

**SwayNC (fixes B9):**
- `swaync/style.css` (line 2): Change `@import url("file:///home/ncasatti/.cache/wallust/colors-swaync.css")` to `@import url("file:///home/ncasatti/.cache/hypr/wallust/colors-swaync.css")`
  - Note: GTK CSS `@import url()` with `file://` protocol requires an absolute path. `$HOME` expansion is not supported in CSS. The hardcoded username is unavoidable here unless swaync supports a different import mechanism. Document this as a known limitation.

**Verification:**
1. Run `wallust run <wallpaper> -s` to generate fresh colors
2. Launch rofi (`rofi -show drun -theme KooL_style-1`) — verify colors load and wallpaper background appears
3. Restart waybar — verify wallust colors are applied (no white/unstyled fallback)
4. Restart swaync — verify themed colors appear in notification center

---

### Step 6: Add Home Manager Cache Bootstrap

**Objective:** Ensure `~/.cache/hypr/wallust/` exists after every `home-manager switch`, so wallust and scripts never fail on a fresh boot or new profile generation.

**Files modified:**
- `home.nix`

**Changes:**
- Add a new `home.activation` entry (after the existing `copyLazyLock` entry, before `refreshSystem`) that runs:
  ```
  mkdir -p "$HOME/.cache/hypr/wallust"
  ```
- This must be a `config.lib.dag.entryAfter [ "writeBoundary" ]` entry, consistent with the existing activation pattern.
- Name it `home.activation.createCacheDirs`.

**Verification:**
1. Run `home-manager switch`
2. Verify `~/.cache/hypr/wallust/` directory exists
3. Verify no errors in the activation output

---

### Step 7: Remove Dead Artifacts from Repository

**Objective:** Clean the repository of all dead code, stale snapshots, and runtime artifacts that should never be in version control.

**Items to delete:**

1. **`hypr/.configs/`** — Entire directory. Dead JaKooLit symlink mechanism. `create_links.sh` main() is entirely commented out. Contains duplicate configs for gtk-2.0, gtk-3.0, gtk-4.0, kitty, Kvantum, rofi, keyd, hyprshade — all now managed by Nix Home Manager.

2. **`hypr/wallust/`** — Entire directory. Contains `wallust-hyprland.conf` and `colors-bash.sh` which are stale rendered snapshots, NOT wallust output targets. After Step 4, nothing references these files anymore.

3. **`hypr/wallpaper_effects/`** — Entire directory. Contains `.wallpaper_current`, `.wallpaper_modified`, `.wallpaper_current.conflict1`, `.wallpaper_current.conflict2`. All are runtime files now relocated to `~/.cache/hypr/`. The conflict files are orphan sync artifacts.

4. **`waybar/wallust/colors-waybar.css`** — Stale rendered snapshot in the repo. Same pattern as `hypr/wallust/`. After Step 5, all waybar styles import from `~/.cache/hypr/wallust/`. Check if the `waybar/wallust/` directory contains anything else; if only this file, delete the entire `waybar/wallust/` directory.

5. **Add to `.gitignore`** (create if not exists at repo root):
   ```
   # Runtime artifacts — never commit
   hypr/wallpaper_effects/
   rofi/.current_wallpaper
   waybar/wallust/
   ```

**Verification:**
1. `git status` shows the deleted files as staged deletions
2. `git grep '.configs/'` returns no hits in any script or config
3. `git grep 'hypr/wallust/'` returns no hits (all references updated in Step 4)
4. `git grep 'wallpaper_effects/'` returns no hits in scripts (all references updated in Steps 2-3)
5. Full system test: change wallpaper via `wallpaper-select.sh`, verify entire pipeline works end-to-end

---

## 4. Dependency Graph

```
Step 1 (wallust.toml)
  ↓
Step 2 (pipeline scripts) ──→ Step 3 (effects script)
  ↓                              ↓
Step 4 (hyprland configs) ←──────┘
  ↓
Step 5 (rofi/waybar/swaync)
  ↓
Step 6 (home.nix bootstrap)
  ↓
Step 7 (cleanup dead artifacts)
```

Steps 1-6 can be executed sequentially with the system remaining functional after each step. Step 7 is purely subtractive and must come last.

---

## 5. Risk Assessment

| Risk | Mitigation |
|------|-----------|
| Wallust fails if `~/.cache/hypr/wallust/` doesn't exist | Step 2 adds `mkdir -p` to `wallpaper-colors.sh`; Step 6 adds Home Manager activation |
| Rofi/Waybar show unstyled on first boot before wallust runs | Acceptable — same behavior as current system. Colors only exist after first wallpaper change. |
| swaync hardcoded path breaks if username changes | Documented as known limitation in Step 5. GTK CSS does not support `$HOME` expansion. |
| Removing `hypr/.configs/` breaks something unknown | Verified: `create_links.sh` main() is 100% commented out. No script references `.configs/`. |
| Old `~/.cache/wallust/` directory persists after migration | Not harmful — wallust no longer writes there. Can be manually cleaned. |

---

## 6. Files Changed Summary

| Step | Files Modified | Files Deleted |
|------|---------------|---------------|
| 1 | 1 (wallust.toml) | 0 |
| 2 | 3 (wallpaper-colors.sh, wallpaper-random.sh, wallpaper-autochange.sh) | 0 |
| 3 | 1 (wallpaper-effects.sh) | 0 |
| 4 | 4 (hyprlock.conf, settings.conf, gamemode.sh, rainbow-borders.sh) | 0 |
| 5 | 30 (11 rofi themes + 1 rofi config + 16+2 waybar styles + 1 swaync) | 0 |
| 6 | 1 (home.nix) | 0 |
| 7 | 1 (.gitignore) | 4 directories (hypr/.configs/, hypr/wallust/, hypr/wallpaper_effects/, waybar/wallust/) |
| **Total** | **41 files** | **4 directories** |
