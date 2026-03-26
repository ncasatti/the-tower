# Tmux Keybindings Reference

Complete keybinding guide for Colemak layout configuration.

## Note on Layout
This configuration is optimized for **Colemak keyboard layout**.
Navigation uses `n-e-u-i` instead of the traditional Vim `hjkl`.

---

## Prefix Key
**Main prefix:** `Ctrl-a` (instead of default `Ctrl-b`)

All commands below are prefixed with `Ctrl-a` unless stated otherwise.

---

## System & Configuration

| Key | Action |
|-----|--------|
| `Prefix + r` | Reload tmux configuration |
| `Prefix + I` | Install new plugins (TPM) |
| `Prefix + U` | Update all plugins (TPM) |
| `Prefix + ?` | List all keybindings |

---

## Window Management

### Creating & Splitting
| Key | Action |
|-----|--------|
| `Prefix + c` | Create new window |
| `Prefix + v` | Split window vertically (panes side by side) |
| `Prefix + h` | Split window horizontally (panes stacked) |

### Navigation
| Key | Action |
|-----|--------|
| `Prefix + Ctrl-n` | Previous window |
| `Prefix + Ctrl-i` | Next window |
| `Prefix + Tab` | Last active window |
| `Prefix + 0-9` | Jump to window by number |
| `Prefix + w` | Quick window picker (FZF) |

### Management
| Key | Action |
|-----|--------|
| `Prefix + ,` | Rename current window |
| `Prefix + &` | Kill current window |
| `Prefix + x` | Kill current pane |

---

## Pane Navigation (Colemak)

### Movement
| Key | Action |
|-----|--------|
| `Prefix + n` | Move to left pane |
| `Prefix + e` | Move to bottom pane |
| `Prefix + u` | Move to top pane |
| `Prefix + i` | Move to right pane |

### Swapping
| Key | Action |
|-----|--------|
| `Prefix + >` | Swap with next pane |
| `Prefix + <` | Swap with previous pane |

### Resizing
| Key | Action |
|-----|--------|
| `Prefix + Ctrl-n` | Resize pane left |
| `Prefix + Ctrl-e` | Resize pane down |
| `Prefix + Ctrl-u` | Resize pane up |
| `Prefix + Ctrl-i` | Resize pane right |

### Layouts
| Key | Action |
|-----|--------|
| `Prefix + Space` | Cycle through layouts |
| `Prefix + z` | Toggle pane zoom (fullscreen) |

---

## Copy Mode (Vi + Colemak)

### Entering Copy Mode
| Key | Action |
|-----|--------|
| `Prefix + [` | Enter copy mode |
| `q` | Exit copy mode |

### Navigation in Copy Mode
| Key | Action |
|-----|--------|
| `n` | Move cursor left |
| `e` | Move cursor down |
| `u` | Move cursor up |
| `i` | Move cursor right |
| `N` | Previous word |
| `I` | Next word end |
| `E` | Page down |
| `U` | Page up |
| `g` | Go to top |
| `G` | Go to bottom |

### Selection & Copy
| Key | Action |
|-----|--------|
| `v` | Begin selection |
| `V` | Line selection |
| `Ctrl-v` | Block selection |
| `y` | Copy selection to clipboard |
| `Y` | Copy selection and paste to command line |

---

## Paste Buffers

| Key | Action |
|-----|--------|
| `Prefix + p` | Paste from top buffer |
| `Prefix + P` | Choose buffer to paste |
| `Prefix + b` | List all paste buffers |

---

## Session Management

| Key | Action |
|-----|--------|
| `Prefix + d` | Detach from session |
| `Prefix + $` | Rename session |
| `Prefix + s` | Session picker |
| `Prefix + o` | Advanced session picker (SessionX + Zoxide) |
| `Prefix + Ctrl-s` | Save session (tmux-resurrect) |
| `Prefix + Ctrl-r` | Restore session (tmux-resurrect) |

---

## Plugin-Specific Keybindings

### FZF Navigation
| Key | Action |
|-----|--------|
| `Prefix + t` | Open FZF menu (sessions, windows, panes) |
| `Prefix + w` | Quick window switcher |

### URL Management
| Key | Action |
|-----|--------|
| `Prefix + u` | Extract and open URLs |

### Floating Window
| Key | Action |
|-----|--------|
| `Prefix + P` | Toggle floating terminal |

### Text Hints (Thumbs)
| Key | Action |
|-----|--------|
| `Prefix + Space` | Activate text hints for copying |

---

## Mouse Support

Mouse mode is **ENABLED**. You can:
- Click to select panes
- Drag borders to resize panes
- Scroll with mouse wheel
- Select text (automatically copies with tmux-yank)

---

## Cheat Sheet Summary

### Most Used Commands
```
Ctrl-a r          Reload config
Ctrl-a v/h        Split panes
Ctrl-a n/e/u/i    Navigate panes (Colemak)
Ctrl-a Tab        Last window
Ctrl-a [          Copy mode
Ctrl-a o          Session picker (with Zoxide)
Ctrl-a t          FZF menu
Ctrl-a u          Open URLs
Ctrl-a P          Floating window
Ctrl-a Ctrl-s     Save session
```

---

## Tips

1. **Quick project switching:** Use `Prefix + o` and type project name (uses Zoxide)
2. **Copy anything fast:** Use `Prefix + Space` for text hints
3. **Browse URLs:** Use `Prefix + u` to extract all URLs from scrollback
4. **Sessions persist:** Automatically saved every 15 minutes
5. **Floating terminal:** Great for quick commands while keeping context
