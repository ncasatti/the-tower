# Tmux Plugins Documentation

Complete guide to all installed plugins, their purpose, and how to use them.

## Plugin Manager

### TPM (Tmux Plugin Manager)
- **Purpose:** Manages tmux plugin installation and updates
- **Installation:** 
  ```bash
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  ```
- **Usage:**
  - `Prefix + I` - Install plugins
  - `Prefix + U` - Update plugins
  - `Prefix + alt + u` - Uninstall plugins not in config

---

## Core Plugins

### tmux-sensible
- **Purpose:** Sensible default settings for tmux
- **What it does:**
  - Increases scrollback to 50000 lines
  - Enables focus events
  - Sets aggressive resize
- **No keybindings required**

### tmux-yank
- **Purpose:** Copy to system clipboard (Wayland compatible)
- **Keybindings:**
  - `y` (in copy mode) - Copy selection to clipboard
  - `Y` (in copy mode) - Copy selection and paste to command line
- **Mouse:** Select text with mouse, release to copy
- **Configuration:** Uses `wl-copy` for Wayland

---

## Session Management

### tmux-resurrect
- **Purpose:** Save and restore tmux sessions
- **Keybindings:**
  - `Prefix + Ctrl-s` - Save current session
  - `Prefix + Ctrl-r` - Restore saved session
- **What it saves:** Windows, panes, layout, working directories, running programs
- **Storage:** `~/.tmux/resurrect/`

### tmux-continuum
- **Purpose:** Automatic session save/restore
- **Features:**
  - Auto-saves every 15 minutes
  - Auto-restores last session on tmux start (if enabled)
- **Status:** Currently ENABLED (`@continuum-restore 'on'`)
- **No manual keybindings** - works automatically

---

## Navigation & Search

### tmux-fzf
- **Purpose:** Fuzzy find tmux resources (windows, panes, sessions, etc.)
- **Keybindings:**
  - `Prefix + t` - Open main FZF menu
  - `Prefix + w` - Quick window switcher
- **Menu options:**
  - Select session
  - Select window
  - Select pane
  - Search commands
  - Kill sessions/windows

### tmux-fzf-url
**DISABLED: Conflicts with Colemak keybindings**

- **Purpose:** Extract and open URLs from terminal output
- **Keybindings:**
  - `Prefix + u` - Open URL picker (DISABLED)
- **Configuration:**
  - Shows last 2000 lines
  - Opens URLs in default browser
- **Status:** Plugin commented out due to keybinding conflicts with Colemak layout

### tmux-sessionx
- **Purpose:** Advanced session manager with Zoxide integration
- **Keybindings:**
  - `Prefix + o` - Open session picker
  - `Ctrl-y` (in picker) - Create new window in selected session
- **Features:**
  - Integrates with Zoxide (jump to frequent directories)
  - Create sessions from any directory
  - Preview session contents
- **Configuration:**
  - Custom paths: `/home/ncasatti/projects`
  - Zoxide mode: ON
  - Window size: 75%x85%

---

## Productivity Tools

### tmux-thumbs
- **Purpose:** Copy text hints (like vimium for tmux)
- **Keybindings:**
  - `Prefix + Space` (default) - Activate hints mode
- **Usage:**
  1. Press keybinding
  2. Letter hints appear on copyable text
  3. Press letter to copy (uses `wl-copy` for Wayland)
- **Great for:** Copying hashes, IDs, paths, URLs
- **Configuration:**
  - `@thumbs-command` - Uses `wl-copy` for Wayland clipboard integration
  - `@thumbs-upcase-command` - Same for uppercase hints

#### Custom Patterns
Configured to detect:
- URLs (http/https)
- IPv4 addresses
- Git commit SHAs (short and long)
- UUIDs
- Email addresses
- Environment variables (UPPER_CASE)

**Appearance settings:**
- `@thumbs-reverse enabled` - Shorter hints near cursor
- `@thumbs-unique enabled` - Same hint for repeated text
- `@thumbs-contrast 1` - Higher visibility

### tmux-floax
- **Purpose:** Floating terminal window in tmux
- **Keybindings:**
  - `Prefix + P` - Toggle floating window
- **Configuration:**
  - Size: 80%x80%
  - Border color: magenta
  - Changes directory based on current pane
- **Use cases:**
  - Quick calculations
  - Temporary commands
  - Notes

---

## Theme

### tmux-oasis
- **Purpose:** Status bar theme
- **Flavor:** lagoon (options: lagoon, starlight, night)
- **Features:** Minimal, clean status bar
- **No keybindings**

---

## Quick Reference

| Plugin | Main Keybinding | Purpose |
|--------|----------------|---------|
| tmux-resurrect | `Prefix + Ctrl-s/r` | Save/restore sessions |
| tmux-fzf | `Prefix + t` | Fuzzy finder menu |
| tmux-fzf-url | ~~`Prefix + u`~~ | Extract URLs (DISABLED) |
| tmux-sessionx | `Prefix + o` | Session manager |
| tmux-floax | `Prefix + P` | Floating window |
| tmux-thumbs | `Prefix + Space` | Text hints |
| tmux-yank | `y` in copy mode | Copy to clipboard |

---

## Plugin Management

### Installing new plugins:
1. Add `set -g @plugin 'author/plugin-name'` to tmux.conf
2. Press `Prefix + I` to install

### Updating all plugins:
1. Press `Prefix + U`

### Removing plugins:
1. Remove line from tmux.conf
2. Press `Prefix + alt + u`
