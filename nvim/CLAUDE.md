# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal Neovim configuration using **Lazy.nvim** as the plugin manager. The configuration features a **Colemak-inspired keybinding layout** with complete navigation remapping, comprehensive LSP integration via Mason, and a modular plugin architecture organized by functionality.

**Critical**: This configuration completely remaps standard Vim navigation keys to Colemak layout. All editing must account for these remaps.

## Documentation

- **[KEYBINDINGS.md](docs/KEYBINDINGS.md)**: Complete reference for ALL keybindings in this configuration
  - Core navigation (Colemak remaps)
  - LSP keybindings
  - Plugin-specific bindings (Git, Obsidian, Go, etc.)
  - Available keys for new mappings
- **android-setup.md**: Android/Java development setup guide
- **TASKNOTES.md**: TaskNotes plugin documentation (if enabled)

## Architecture

### Entry Point & Bootstrap
- `init.lua`: Loads configuration modules in order: keys → config → lazy
- `lua/config/lazy.lua`: Bootstraps Lazy.nvim plugin manager, auto-imports plugin specs
- `lazy-lock.json`: Version lock file for reproducible plugin installations

### Modular Plugin Structure
Plugins are organized by category in `lua/plugins/`:
```
plugins/
├── ai/           # Codeium AI completion
├── build/        # Gradle build system integration
├── editor/       # Core editing (treesitter, cmp, autopairs, todo-comments)
├── git/          # Neogit (magit-like interface)
├── lsp/          # Mason + LSP configuration for 8+ languages
├── navigation/   # Telescope, Oil.nvim, goto-preview
├── snacks/       # Snacks.nvim plugin (dashboard, picker, scroll, styles)
├── themes/       # Ayu color scheme
├── ui/           # Lualine, noice, which-key, zen-mode, twilight
└── writing/      # Obsidian, render-markdown
```

**Snacks Plugin**: Uses modular structure with `init.lua` + separate config files for dashboard, picker, scroll, and styles.

### Core Configuration Files
- `lua/config/keys.lua`: **Colemak navigation remaps** (normal, visual, operator-pending modes)
- `lua/config/config.lua`: Vim settings (tabs, search, undo, conceallevel)

## Colemak Keybinding System

**CRITICAL**: This configuration completely remaps navigation. Standard Vim commands will NOT work as expected.

**See [KEYBINDINGS.md](docs/KEYBINDINGS.md) for the complete keybinding reference.**

### Quick Reference - Core Navigation (replaces hjkl)
- **u/e/i/n** → Up/Down/Right/Left (maps to k/j/l/h)
- **N/I** → Word backward/forward (maps to b/e)
- **E/U** → Page down/up (maps to Ctrl-d/Ctrl-u)
- **l/L** → Enter insert mode at cursor/line start (maps to i/I)
- **o** → Inner text object (maps to i in operator-pending mode)
- **k/K** → Next/previous search result (maps to n/N)
- **z** → Undo (maps to u)
- **;** → Yank (maps to y)
- **P** → Paste from yank register (maps to "0p)

### Window Management
- **`<leader>u/e/i/n`** → Navigate to window up/down/right/left
- **`<leader>h`** → Vertical split
- **`<leader>v`** → Horizontal split

**Operator-pending mode remaps** (lines 51-63 in keys.lua): Essential for motions to work with d, c, y, v operators.

## Language Server Configuration

### LSP Setup (lua/plugins/lsp/lsp.lua)
Uses **native Neovim LSP config API** (vim.lsp.config/enable, not lspconfig.setup):

**Auto-installed servers via Mason** (line 73):
- **clangd**: C/C++ (clang-format support)
- **rust_analyzer**: Rust (Cargo.toml detection)
- **pyright**: Python (pyproject.toml detection)
- **ts_ls**: TypeScript/JavaScript (tsconfig detection)
- **gopls**: Go (go.mod detection) + go.nvim integration
- **lua_ls**: Lua (with vim globals configured)
- **jdtls**: Java (complex config with debug adapter, lines 158-190)
- **kotlin_language_server**: Kotlin (Gradle support)
- **bashls**: Bash (sh files)

**Configuration pattern** (lines 93-220):
```lua
vim.lsp.config('server_name', {
  cmd = { 'server-binary' },
  filetypes = { ... },
  root_markers = { ... },  # Used for root detection
  capabilities = capabilities,
  on_attach = on_attach,
})
vim.lsp.enable('server_name')
```

### LSP Keybindings (on_attach function, lines 18-61)

**See [KEYBINDINGS.md](docs/KEYBINDINGS.md#lsp-language-server-protocol) for complete LSP keybindings.**

Quick reference:
- **gd/gD/gI** → Go to definition/declaration/implementation
- **gr** → References via Snacks.picker (not Telescope)
- **K/Ctrl-k** → Hover documentation/signature help
- **`<leader>rn/ca/D`** → Rename/code actions/type definition
- **`<leader>ds/ws`** → Document/workspace symbols via Snacks.picker
- **`<leader>ll`** / **`:Format`** → Buffer formatting
- **`[d` / `]d`** → Diagnostic navigation

## Plugin Integration

### Completion (lua/plugins/editor/cmp.lua)
- **nvim-cmp** with sources: LSP → LuaSnip → Path → Buffer
- **Tab/Shift-Tab**: Navigate completion items + snippet placeholders
- **Cmdline completion**: Enabled for `/`, `?`, and `:` commands

### Navigation
- **Telescope** (deprecated for LSP): `<leader>tt/tg/tb/th` (files/grep/buffers/help)
- **Snacks.picker**: Primary picker for LSP references/symbols (replaces Telescope)
- **Oil.nvim**: Edit directories as buffers

### Git Integration
- **Neogit** (lua/plugins/git/neogit.lua): Magit-like Git interface
- **Diffview.nvim**: Enhanced diff viewing

### Go Development (lua/plugins/lsp/go.lua)
- **Auto-formatting**: golines (120 char) + goimports on save
- **Inlay hints**: Type info + parameter names
- **Testing**: Run tests at function/file level
- **Code generation**: Struct tags, if-err, struct fill

### Java/Android Development
- **JDTLS**: Full Java LSP with debugging support (java-debug-adapter)
- **Gradle** (lua/plugins/build/gradle.lua): Build system integration
- Workspace config: `~/.local/share/nvim/jdtls-workspace/{project-name}`

### Writing & Note-Taking
- **Obsidian** (lua/plugins/writing/obsidian.lua): Zettelkasten integration at `~/Documents/Zettelkasten`
- **TaskNotes**: Task management integrated with Obsidian (see TASKNOTES.md for full guide)
  - Keybindings: `<leader>t*` prefix
  - Task creation, status/priority cycling, context tagging, date scheduling
  - Query system: `<leader>tq` (interactive), `<leader>tqh/tqt/tqo` (presets)

### UI Enhancements
- **Snacks.nvim** (lua/plugins/snacks/init.lua): Dashboard, picker, scroll, indent animation
- **Noice.nvim** (lua/plugins/ui/noice.lua): Centered command line, notifications
- **Which-key**: Keybinding helper popup
- **Zen Mode + Twilight**: Distraction-free writing

## Common Workflows

### Plugin Management
```vim
:Lazy                  " Dashboard (install/update/clean)
:Lazy sync            " Update to locked versions
:Lazy update          " Update + regenerate lock file
:TSUpdate             " Update Treesitter parsers
```

### Adding Language Servers
1. Edit `lua/plugins/lsp/lsp.lua:73` → Add to `servers` table
2. Add config block using `vim.lsp.config()` pattern (lines 93-215)
3. Add `vim.lsp.enable('server_name')` at line 217-220
4. Restart Neovim → Mason auto-installs

### Adding Plugins
1. Create `lua/plugins/{category}/{plugin-name}.lua`:
```lua
return {
  "author/plugin-name",
  dependencies = { "deps" },
  config = function()
    require("plugin-name").setup()
  end
}
```
2. Restart Neovim → Auto-installed and loaded

### Keybinding Customization
- **Global remaps**: Edit `lua/config/keys.lua`
- **Plugin-specific**: Edit keymaps in respective plugin files
- **Remember**: Account for Colemak remaps when creating bindings (e.g., use `u/e/i/n` instead of `k/j/l/h`)

## Android/Java Development

### Setup
**See `android-setup.md` for complete Android development guide.**

### JDTLS Configuration (lines 158-196)
- **JVM args**: Requires Java 17+ with `--add-modules=ALL-SYSTEM` flags
- **Config directory**: Auto-detects Linux (`config_linux`) - change for Mac/Windows
- **Workspace**: Isolated per project in `~/.local/share/nvim/jdtls-workspace/`
- **Root markers**: Android projects detected via `settings.gradle`, `settings.gradle.kts`, `gradlew`, `build.gradle`

### Kotlin LSP Configuration (lines 198-216)
- **Root markers**: Same as JDTLS (Android/Gradle project detection)
- **Coexistence**: Works alongside JDTLS for hybrid Java/Kotlin Android projects

### Quick Start
```bash
cd ~/Documents/Dev/Xionico/gev/ArcorGev5AndroidAppAS-develop/sources/workspace/ArcorGev5AndroidStudio
nvim .
```
Open from **Gradle project root** for proper LSP detection.

## Settings & Appearance

- **Font**: Cascadia Code (size 12, GUI only)
- **Theme**: Ayu Dark (lua/plugins/themes/ayu.lua)
- **Indentation**: 2 spaces, expandtab enabled
- **Line numbers**: Relative numbering
- **Clipboard**: System clipboard integration (`unnamedplus`)
- **Search**: Smart case (case-insensitive unless uppercase present)
- **Conceallevel**: 1 (for Obsidian markdown features)

## TaskNotes Integration

Full task management system integrated with Obsidian - see **TASKNOTES.md** for complete documentation.

**Quick reference**:
- Create task: `<leader>tn`
- Cycle status: `<leader>ts` (none → open → in-progress → on-hold → done → archive)
- Set priority: `<leader>tp` (none → low → normal → high)
- Add context: `<leader>tcw/f/s` (work/freelance/study)
- Find tasks: `<leader>tvf/i/t/w/d` (all/inbox/todo/work/done)
- Query tasks: `<leader>tq` (interactive), `<leader>tqh/t/o` (high-priority/today/overdue)
