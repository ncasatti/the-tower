# Neovim Keybindings Reference

Complete reference for all keybindings in this Neovim configuration.

**Leader Key:** `Space`

**Last Updated:** 2025-11-26

---

## Table of Contents

- [Critical Information](#critical-information)
- [Core Navigation (Colemak)](#core-navigation-colemak)
- [Window Management](#window-management)
- [LSP (Language Server Protocol)](#lsp-language-server-protocol)
- [Debugging (DAP)](#debugging-dap)
- [Android Development](#android-development)
- [Gradle Build System](#gradle-build-system)
- [Go Development](#go-development)
- [Git Integration](#git-integration)
- [File Navigation & Exploration](#file-navigation--exploration)
- [Search & Grep](#search--grep)
- [Obsidian & Writing](#obsidian--writing)
- [Markdown Rendering](#markdown-rendering)
- [UI & Utilities](#ui--utilities)
- [Goto Preview](#goto-preview)
- [Completion (nvim-cmp)](#completion-nvim-cmp)
- [AI Completion (Codeium)](#ai-completion-codeium)
- [Dashboard (Snacks)](#dashboard-snacks)
- [Available Keys](#available-keys-for-new-mappings)

---

## Critical Information

### Colemak Navigation Remapping

**THIS CONFIGURATION COMPLETELY REMAPS STANDARD VIM NAVIGATION KEYS.**

Standard Vim navigation (`hjkl`) will NOT work. All custom keybindings and Vim commands must use the Colemak remapped keys:

- `u` → Move up (replaces `k`)
- `e` → Move down (replaces `j`)
- `i` → Move right (replaces `l`)
- `n` → Move left (replaces `h`)

When using any motion command with operators (`d`, `c`, `y`, `v`), use the Colemak keys:
- `dune` → Delete up
- `denk` → Delete down and next line
- `yi3w` → Yank inner 3 words
- `vcnk` → Change (select) left to line below

### Operator-Pending Mode Critical Remaps

File: `lua/config/keys.lua` (lines 57-69)

The operator-pending mode has essential remaps that enable motions to work with `d`, `c`, `y`, `v` operators:
- `u/e/n` → Movement (up/down/left)
- `N/I` → Word backward/forward
- `E/U` → Page down/up
- `o` → Inner text object (remapped from `i`)

---

## Core Navigation (Colemak)

**File:** `lua/config/keys.lua`

### Basic Movement (replaces HJKL)

| Key | Mode | Description | Standard Vim |
|-----|------|-------------|--------------|
| `u` | n/v/o | Move up | `k` |
| `e` | n/v/o | Move down | `j` |
| `i` | n/v/o | Move right | `l` |
| `n` | n/v/o | Move left | `h` |
| `N` | n/v/o | Word backward | `b` |
| `I` | n/v/o | Word forward | `e` |

### Paragraph/Page Navigation

| Key | Mode | Description | Standard Vim |
|-----|------|-------------|--------------|
| `E` | n/v | Page down (paragraph) | `}` |
| `U` | n/v | Page up (paragraph) | `{` |
| `E` | o | Page down (scroll) | `Ctrl-d` |
| `U` | o | Page up (scroll) | `Ctrl-u` |

### Mode Entry

| Key | Mode | Description | Standard Vim |
|-----|------|-------------|--------------|
| `l` | n | Enter insert mode at cursor | `i` |
| `L` | n | Insert at line start (after whitespace) | `I` |
| `<leader>,` | n | Insert at line start (before whitespace) | `Shift-i` |
| `nn` | i | Exit insert mode | `Esc` |

### Text Objects

| Key | Mode | Description | Standard Vim |
|-----|------|-------------|--------------|
| `o` | v/o | Inner text object | `i` (in operator-pending) |

### Editing Operations

| Key | Mode | Description | Standard Vim |
|-----|------|-------------|--------------|
| `z` | n/v | Undo | `u` |
| `Y` | n/v | Yank entire line | `yy` |
| `P` | n/v | Paste from yank register 0 | `"0p` |
| `<leader>k` | n | Yank entire buffer | `ggVGy` |
| `<leader>o` | n | Insert blank line below | `o<Esc>` |

### Search & Navigation

| Key | Mode | Description | Standard Vim |
|-----|------|-------------|--------------|
| `k` | n/v/o | Next search result | `n` |
| `K` | n/v/o | Previous search result | `N` |
| `<leader>-` | n/v/o | Jump to matching bracket | `%` |
| `R` | n | Center screen on cursor | `zz` |

### Line Wrapping

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>W` | n | Toggle line wrap |

### Buffer Navigation

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>j` | n | Switch to previous buffer |

---

## Window Management

**File:** `lua/config/keys.lua` (lines 71-75)

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>u` | n | Move to window above |
| `<leader>e` | n | Move to window below |
| `<leader>i` | n | Move to window right |
| `<leader>n` | n | Move to window left |
| `<leader>h` | n | Vertical split |
| `<leader>v` | n | Horizontal split |

---

## LSP (Language Server Protocol)

**File:** `lua/lsp/utils.lua` (on_attach function)

### Navigation

| Key | Mode | Description |
|-----|------|-------------|
| `gd` | n | Go to definition (via Snacks.picker) |
| `gD` | n | Go to declaration (via Snacks.picker) |
| `gI` | n | Go to implementation (via Snacks.picker) |
| `gr` | n | Go to references (via Snacks.picker) |
| `gy` | n | Go to type definition (via Snacks.picker) |
| `<leader>D` | n | Type definition |

### Documentation

| Key | Mode | Description |
|-----|------|-------------|
| `K` | n | Hover documentation |
| `<C-k>` | n | Signature help |

### Code Actions

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>rn` | n | Rename symbol |
| `<leader>ca` | n | Code actions |
| `<leader>ll` | n | Format buffer |
| `:Format` | n | Format buffer (command) |

### Symbols

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>ds` | n | Document symbols (via Snacks.picker) |
| `<leader>ws` | n | Workspace symbols (via Snacks.picker) |

### Workspace Management

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>wa` | n | Add workspace folder |
| `<leader>wr` | n | Remove workspace folder |
| `<leader>wl` | n | List workspace folders |

### Diagnostics

| Key | Mode | Description |
|-----|------|-------------|
| `[d` | n | Previous diagnostic |
| `]d` | n | Next diagnostic |
| `<leader>le` | n | Open diagnostic float |
| `<leader>lq` | n | Set location list with diagnostics |

---

## Debugging (DAP)

**File:** `lua/plugins/debug/dap.lua`

Debug Adapter Protocol integration for Java/Kotlin debugging.

### F-Key Debug Controls (Traditional Debugger Keys)

| Key | Mode | Description |
|-----|------|-------------|
| `F5` | n | Continue/Start debugging |
| `F6` | n | Pause execution |
| `F9` | n | Toggle breakpoint |
| `F10` | n | Step over |
| `F11` | n | Step into |
| `F12` | n | Step out |

### Leader Debug Controls

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>db` | n | Toggle breakpoint |
| `<leader>dB` | n | Set conditional breakpoint |
| `<leader>dc` | n | Continue execution |
| `<leader>dC` | n | Run to cursor |
| `<leader>di` | n | Step into |
| `<leader>do` | n | Step over |
| `<leader>dO` | n | Step out |
| `<leader>dr` | n | Toggle REPL |
| `<leader>dl` | n | Run last debug configuration |
| `<leader>dt` | n | Terminate debug session |
| `<leader>du` | n | Toggle debug UI |
| `<leader>de` | n/v | Evaluate expression |
| `<leader>dh` | n | Hover variables (debug mode) |
| `<leader>dp` | n | Preview (debug widgets) |

### Debug UI Navigation

The debug UI uses Colemak-friendly navigation:
- `<CR>` or double-click: Expand/collapse
- `o`: Open item
- `d`: Remove item
- `l`: Edit item (enters insert mode)
- `r`: Toggle REPL
- `t`: Toggle element
- `q` or `<Esc>`: Close floating windows

---

## Android Development

**Files:** `lua/plugins/android/*.lua`

Comprehensive Android development utilities for device management, logcat viewing, and build operations.

### Logcat Viewer

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>al` | n | View all logcat output |
| `<leader>ae` | n | View errors only |
| `<leader>aw` | n | View warnings and above |
| `<leader>ap` | n | View logs for current package |
| `<leader>af` | n | Custom logcat filter (prompt) |
| `<leader>ac` | n | Clear logcat buffer |

**Note:** Logcat opens in floating terminal. Press `q` or `Esc` to close.

### ADB Helpers

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>ad` | n | List connected devices |
| `<leader>ai` | n | Install APK (prompts for path) |
| `<leader>au` | n | Uninstall current app |
| `<leader>aD` | n | Clear app data |
| `<leader>as` | n | Start current app |
| `<leader>aS` | n | Stop current app |
| `<leader>ar` | n | Restart current app |
| `<leader>adb` | n | Enable debug mode (port 5005) |

### Build Helpers

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>ab` | n | Build debug APK |
| `<leader>aB` | n | Build release APK |
| `<leader>aI` | n | Build and install debug |
| `<leader>aR` | n | Build, install, and run debug |
| `<leader>aDb` | n | Build, install, and enable debugging |
| `<leader>aq` | n | Quick rebuild (clean + build) |
| `<leader>ax` | n | Install existing debug APK |
| `<leader>aX` | n | Run existing app (no rebuild) |

### Quick Workflows

**Development Workflow:**
1. `<leader>aR` - Build, install, and run
2. `<leader>al` or `<leader>ap` - View logs
3. Make changes
4. Repeat

**Debugging Workflow:**
1. Set breakpoints with `F9`
2. `<leader>aDb` - Build, install, and start in debug mode
3. `F5` - Attach debugger
4. Use `F10/F11/F12` to step through code
5. `<leader>de` - Evaluate expressions
6. `<leader>dt` - Terminate when done

---

## Gradle Build System

**File:** `lua/plugins/android/gradle.lua`

Gradle integration for Android and Java projects.

### Gradle Keybindings

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>gb` | n | Gradle build |
| `<leader>gc` | n | Gradle clean |
| `<leader>gr` | n | Install & run debug (installDebug) |
| `<leader>gt` | n | Gradle test |
| `<leader>gd` | n | Assemble debug APK |
| `<leader>gR` | n | Assemble release APK |
| `<leader>gi` | n | Install debug on device |
| `<leader>gI` | n | Install release on device |
| `<leader>gu` | n | Uninstall debug from device |
| `<leader>gU` | n | Uninstall release from device |
| `<leader>gs` | n | Show all Gradle tasks |
| `<leader>gx` | n | Execute custom Gradle task (prompt) |

### Gradle Ex Commands

You can also use Ex commands:
- `:GradleExec <task>` - Execute any Gradle task
- `:GradleTasks` - List all available tasks
- `:GradleWhich` - Show which gradlew file will be used
- `:GradleFixPermissions` - Make gradlew executable

---

## Go Development

**File:** `lua/plugins/lsp/go.lua`

### Code Generation

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>gsj` | n | Add JSON struct tags |
| `<leader>gsy` | n | Add YAML struct tags |
| `<leader>gst` | n | Add struct tags (prompt) |
| `<leader>gsr` | n | Remove struct tags |
| `<leader>gsf` | n | Fill struct |
| `<leader>gsi` | n | Add if err |
| `<leader>gsm` | n | Go mod tidy |
| `<leader>gie` | n | Go if err (gopher) |

### Testing & Debugging

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>gch` | n | Test coverage |
| `<leader>gtt` | n | Run tests |
| `<leader>gts` | n | Run tests with summary |
| `<leader>gtf` | n | Run test for current function |
| `<leader>gtF` | n | Run test for current file |
| `<leader>gta` | n | Open alternate file (test/implementation) |
| `<leader>gdb` | n | Start debugging |
| `<leader>gdt` | n | Stop debugging |

---

## Git Integration

**File:** `lua/plugins/snacks/keys.lua`

### Basic Git Operations

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>gg` | n | Open Lazygit |
| `<leader>gB` | n/v | Git browse (open in browser) |
| `<leader>gs` | n | Git status picker |
| `<leader>gb` | n | Git branches picker |
| `<leader>gl` | n | Git log picker |
| `<leader>gL` | n | Git log line picker |
| `<leader>gS` | n | Git stash picker |
| `<leader>gf` | n | Git log file picker |

**Note:** Git diff picker uses `<leader>gd`, but this conflicts with Gradle `<leader>gd` (assemble debug). The Gradle binding takes precedence due to load order. Use `:GradleExec gitDiffCommand` as alternative if needed.

---

## File Navigation & Exploration

**Files:** `lua/plugins/snacks/keys.lua`, `lua/plugins/navigation/oil.lua`

### File Pickers

| Key | Mode | Description |
|-----|------|-------------|
| `<leader><space>` | n | Smart find files |
| `<leader><leader>` | n | Find files |
| `<leader>ts` | n | Smart find files |
| `<leader>tt` | n | Buffers picker |
| `<leader>tg` | n | Find git files |
| `<leader>tc` | n | Find config files |
| `<leader>tr` | n | Recent files (cwd) |
| `<leader>tR` | n | Recent files (global) |
| `<leader>tp` | n | Projects |
| `<leader>bb` | n | Buffers picker |

### Oil.nvim (File Browser)

| Key | Mode | Description |
|-----|------|-------------|
| `-` | n | Open Oil (floating window) |
| `<leader>E` | n | Open Oil (parent directory) |
| `<leader>-` | n | Open Oil in current file's directory |

#### Within Oil Buffer

| Key | Description |
|-----|-------------|
| `g?` | Show help |
| `<CR>` | Select file/directory |
| `<C-s>` | Open in vertical split |
| `<C-v>` | Open in horizontal split |
| `<C-t>` | Open in new tab |
| `<C-p>` | Preview file |
| `<C-c>` | Close Oil |
| `<C-r>` | Refresh |
| `-` | Go to parent directory |
| `_` | Open current working directory |
| `` ` `` | Change directory |
| `~` | Change tab directory |
| `gs` | Change sort |
| `gx` | Open with external application |
| `g.` | Toggle hidden files |
| `g\` | Toggle trash |
| `q` | Close Oil |

---

## Search & Grep

**File:** `lua/plugins/snacks/keys.lua`

### Content Search

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>/` | n | Grep in project |
| `<leader>sg` | n | Grep in project |
| `<leader>sw` | n/x | Grep word under cursor / visual selection |
| `<leader>sb` | n | Search buffer lines |
| `<leader>sB` | n | Grep open buffers |

### Search Tools

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>s"` | n | Registers |
| `<leader>s/` | n | Search history |
| `<leader>sa` | n | Autocmds |
| `<leader>sc` | n | Command history |
| `<leader>sC` | n | Commands |
| `<leader>sd` | n | Diagnostics |
| `<leader>sD` | n | Buffer diagnostics |
| `<leader>sh` | n | Help pages |
| `<leader>sH` | n | Highlights |
| `<leader>si` | n | Icons |
| `<leader>sj` | n | Jumps |
| `<leader>sk` | n | Keymaps |
| `<leader>sl` | n | Location list |
| `<leader>sm` | n | Marks |
| `<leader>sM` | n | Man pages |
| `<leader>sp` | n | Plugin specs |
| `<leader>sq` | n | Quickfix list |
| `<leader>sR` | n | Resume last search |
| `<leader>su` | n | Undo history |
| `<leader>ss` | n | LSP symbols |
| `<leader>sS` | n | LSP workspace symbols |

---

## Obsidian & Writing

**File:** `lua/plugins/writing/obsidian.lua`

### Obsidian Commands

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>os` | n | Search notes |
| `<leader>og` | n | Grep notes |
| `<leader>on` | n | New note |
| `<leader>od` | n | Today's note |
| `<leader>ot` | n | Insert template |
| `<leader>ob` | n | Show backlinks |
| `<leader>oo` | n | Quick switch notes |
| `<leader>of` | n | Follow link under cursor |
| `<leader>ox` | n | Toggle checkbox |

---

## Markdown Rendering

**File:** `lua/plugins/writing/render-markdown.lua`

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>mr` | n | Toggle markdown rendering |
| `<leader>me` | n | Expand markdown heading |

---

## UI & Utilities

**Files:** `lua/plugins/ui/which-key.lua`, `lua/plugins/snacks/keys.lua`

### Zen Mode & Focus

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>z` | n | Toggle Zen Mode |
| `<leader>Z` | n | Toggle Zen Mode (Dim) |

### Utility Functions

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>?` | n | Show which-key popup |
| `<leader>.` | n | Toggle scratch buffer |
| `<leader>S` | n | Select scratch buffer |
| `<leader>bd` | n | Delete buffer |
| `<leader>cR` | n | Rename file |
| `<leader>:` | n | Command history |
| `<C-/>` | n | Toggle terminal |
| `<C-_>` | n | Toggle terminal (alternate) |

### Word Navigation (Snacks.words)

| Key | Mode | Description |
|-----|------|-------------|
| `]]` | n/t | Next reference |
| `[[` | n/t | Previous reference |

---

## Goto Preview

**File:** `lua/plugins/navigation/goto-preview.lua`

Default mappings enabled.

| Key | Mode | Description |
|-----|------|-------------|
| `gpd` | n | Preview definition |
| `gpt` | n | Preview type definition |
| `gpi` | n | Preview implementation |
| `gpr` | n | Preview references |
| `gP` | n | Close all preview windows |

---

## Completion (nvim-cmp)

**File:** `lua/plugins/editor/cmp.lua`

### Insert Mode Completion

| Key | Mode | Description |
|-----|------|-------------|
| `<C-b>` | i | Scroll docs backward |
| `<C-f>` | i | Scroll docs forward |
| `<C-Space>` | i | Trigger completion |
| `<C-e>` | i | Abort completion |
| `<CR>` | i | Confirm selection |
| `<Tab>` | i/s | Next completion item / expand snippet |
| `<S-Tab>` | i/s | Previous completion item / jump back in snippet |

---

## AI Completion (Codeium)

**File:** `lua/plugins/ai/codeium.lua`

### Insert Mode AI Suggestions

| Key | Mode | Description |
|-----|------|-------------|
| `<C-y>` | i | Accept Codeium suggestion |
| `<C-/>` | i | Trigger Codeium suggestions |
| `<C-i>` | i | Next Codeium completion |
| `<C-n>` | i | Previous Codeium completion |
| `<C-x>` | i | Clear Codeium suggestions |

---

## Dashboard (Snacks)

**File:** `lua/plugins/snacks/dashboard.lua`

### Dashboard Quick Actions

| Key | Description |
|-----|-------------|
| `t` | Find file |
| `n` | New file |
| `g` | Find text |
| `r` | Recent files |
| `e` | Explore files (Oil) |
| `c` | Config |
| `s` | Restore session |
| `L` | Lazy plugin manager |
| `q` | Quit |

---

## Available Keys for New Mappings

### Completely Unused Leader Keys

These keys have no current mappings and are safe to use:

- `<leader>a` / `<leader>A`
- `<leader>f` / `<leader>F`
- `<leader>j` (only `<leader>j` is used for previous buffer, `<leader>J` is unused)
- `<leader>p` / `<leader>P` / `<leader>q` / `<leader>Q`
- `<leader>x` / `<leader>X`
- `<leader>y`

### Partially Used Prefixes

These prefixes have some mappings but room for additional related commands:
- `<leader>d*` - Diagnostics/Debug (many d-prefixed keys are available)
- `<leader>t*` - Find/Test (many t-prefixed keys are available)
- `<leader>l*` - LSP/Location (le, lq, ll are used; others available)
- `<leader>g*` - Git/Go/Gradle (heavily used; conflicts exist - see notes below)
- `<leader>c*` - Code/Config (ca, cR used; others available)

### Known Conflicts

1. **`<leader>gd` conflict**: Maps to Gradle "assemble debug" in Android projects. Git diff is at `<leader>gd` in snacks but Gradle binding takes precedence.
2. **`<leader>gs` conflict**: Git status picker (snacks) vs Go struct tags (go.nvim). Snacks binding loads first, so Git status is active.

---

## Mode Legend

- `n` - Normal mode
- `i` - Insert mode
- `v` - Visual mode
- `o` - Operator-pending mode
- `x` - Visual and Select mode
- `t` - Terminal mode
- `s` - Select mode
- `c` - Command-line mode

---

## Notes

### Colemak Layout
All navigation commands in this configuration use Colemak layout:
- Standard Vim `hjkl` navigation is completely remapped
- When writing custom keybindings, remember to use `u/e/i/n` for movement
- Operator-pending mode has special remaps that must be considered

### Plugin Priority
Keybindings are loaded in this order:
1. Core config (keys.lua)
2. LSP on_attach (each LSP connection)
3. Plugin-specific keybindings (lazy-loaded in order)

Later keybindings may override earlier ones. Check the source files listed above if a binding isn't working as expected.

### Which-key Integration
The which-key plugin provides a popup menu for leader key combinations. Press `<leader>?` to see available keybindings grouped by prefix.

### Custom Keybindings
To add new keybindings:
1. Edit the appropriate file:
   - Global core: `lua/config/keys.lua`
   - LSP-specific: `lua/lsp/utils.lua` (on_attach function)
   - Plugin-specific: respective plugin file in `lua/plugins/`
2. Always use `vim.keymap.set()` with mode, key, action, and options table
3. Include a `desc` field for which-key integration
4. Remember Colemak remapping when using movement keys
5. Restart Neovim for changes to take effect

---

## Last Updated

This documentation was generated on 2025-11-26 by auditing all Lua configuration files.

For the most current and detailed keybinding information, refer to the source files:
- `/home/ncasatti/.config/konfig/nvim/lua/config/keys.lua`
- `/home/ncasatti/.config/konfig/nvim/lua/lsp/utils.lua`
- `/home/ncasatti/.config/konfig/nvim/lua/plugins/**/*.lua`
