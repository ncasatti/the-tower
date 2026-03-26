# AGENTS.md - Neovim Configuration Development Guide

This guide is for AI coding agents working in this Neovim configuration repository.

## Repository Overview

This is a personal Neovim configuration using **Lazy.nvim** as the plugin manager with a **Colemak-inspired keybinding layout**. The configuration features modular plugin architecture, comprehensive LSP integration via Mason, and specialized support for multiple languages (Python, Go, Java/Android, Rust, TypeScript, etc.).

## Build/Test/Lint Commands

### Plugin Management
```vim
:Lazy                    " Open plugin manager dashboard
:Lazy sync              " Install/update to locked versions
:Lazy update            " Update plugins and regenerate lock file
:Lazy clean             " Remove unused plugins
:Lazy profile           " Profile startup time
```

### Testing (Neotest)
```vim
" Run tests (keybindings configured in lua/plugins/testing/neotest.lua)
:lua require("neotest").run.run()                    " Run nearest test
:lua require("neotest").run.run(vim.fn.expand("%"))  " Run all tests in file
:lua require("neotest").run.run({suite = true})      " Run entire test suite
:lua require("neotest").summary.toggle()             " Toggle test summary window
:lua require("neotest").output.open()                " Open test output
```

**Test keybindings** (from neotest.lua):
- `<leader>tr` - Run nearest test
- `<leader>tf` - Run all tests in current file
- `<leader>ts` - Run entire test suite
- `<leader>to` - Show test output
- `<leader>tS` - Toggle test summary

### Formatting (Conform.nvim)
```vim
:Format                  " Format buffer or selection (range command)
:ConformInfo            " Show available formatters and their status
<leader>ll              " Keybinding: Format buffer/selection (normal/visual)
<leader>lf              " Toggle format-on-save (default: enabled)
```

**Auto-format on save**: Enabled by default for `.py`, `.lua`, `.rs`, `.go` files.

### LSP Management
```vim
:Mason                  " Open Mason installer
:MasonUpdate           " Update Mason registry
:MasonInstall <name>   " Install LSP server or formatter
:LspInfo               " Show attached LSP servers
:LspRestart            " Restart LSP servers
```

### Treesitter
```vim
:TSUpdate              " Update all parsers
:TSInstall <lang>      " Install specific parser
:TSInstallInfo         " Show installed parsers
```

### Verification Script
```bash
./test-android-lsp.sh  # Verify Android/Java LSP setup (JDTLS, Kotlin)
```

## Code Style Guidelines

### File Structure & Organization

**Plugin structure** (each plugin in `lua/plugins/{category}/{name}.lua`):
```lua
return {
    "author/plugin-name",
    dependencies = { "dep1", "dep2" },
    event = "VeryLazy",  -- Lazy loading trigger
    cmd = { "Command" },  -- Load on command
    keys = { ... },       -- Load on keypress
    config = function()
        -- Plugin setup code
    end,
}
```

**LSP server structure** (in `lua/plugins/lsp/servers/{lang}.lua`):
```lua
-- Language Name Language Server Configuration
return {
    name = 'server_name',
    config = function(capabilities, on_attach)
        vim.lsp.config('server_name', {
            cmd = { 'server-binary', '--stdio' },
            filetypes = { 'filetype' },
            root_markers = { 'project.file', '.git' },
            capabilities = capabilities,
            on_attach = on_attach,
        })
    end
}
```

### Indentation & Formatting
- **4 spaces** for indentation (NOT tabs)
- `expandtab = true`
- Consistent indentation in nested tables/functions
- Line length: No hard limit, but prefer readability (~100 chars)

### Imports & Dependencies
```lua
-- External dependencies at top of plugin spec
dependencies = {
    "required/plugin",
    "another/dependency",
},

-- Require statements inside config functions
config = function()
    local plugin = require("plugin-name")
    local utils = require("utils")
end,

-- Safe requires with error handling for optional dependencies
local ok, module = pcall(require, 'optional.module')
if ok then
    -- Use module
end
```

### Naming Conventions
- **Files**: Lowercase with hyphens (`lsp-config.lua`, `goto-preview.lua`)
- **Variables**: snake_case (`local my_var`, `on_attach`)
- **Functions**: snake_case (`local function setup_keybindings()`)
- **Constants**: UPPER_SNAKE_CASE (`local MAX_RETRIES = 3`)
- **Module tables**: Capital `M` (`local M = {}`, `return M`)

### Comments
- Use descriptive comments for non-obvious code
- Header comments for files/sections: `-- Section Name - Description`
- Inline comments: Explain WHY, not WHAT
- Mixed Spanish/English is acceptable (this is a personal config)
```lua
-- LSP settings: This function gets run when an LSP connects to a particular buffer
M.on_attach = function(client, bufnr)
    -- See `:help K` for why this keymap
    nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
end
```

### Error Handling
```lua
-- Use pcall for potentially failing operations
local ok, result = pcall(require, 'module')
if not ok then
    vim.notify("Failed to load module", vim.log.levels.WARN)
    return
end

-- Validate inputs before use
if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
end

-- Use vim.notify for user-facing messages
vim.notify("Operation completed", vim.log.levels.INFO)
```

### Keybindings
```lua
-- Always include descriptive 'desc' field
vim.keymap.set('n', '<leader>ff', function()
    require('telescope.builtin').find_files()
end, { desc = 'Find: Files' })

-- Use local keymaps for buffer-specific bindings
local nmap = function(keys, func, desc)
    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
end
```

### Types & Documentation
- No formal type annotations (Lua doesn't have them)
- Use descriptive variable names that imply type
- Document function parameters in comments:
```lua
-- Setup language server configuration
-- @param capabilities table LSP capabilities from cmp_nvim_lsp
-- @param on_attach function Callback when LSP attaches to buffer
M.config = function(capabilities, on_attach)
    -- ...
end
```

## Critical Implementation Rules

### Colemak Keybinding System
**CRITICAL**: This config uses Colemak navigation (`u/e/i/n` instead of `k/j/l/h`). When adding keybindings:
- Never hardcode `hjkl` navigation
- Check `lua/config/keys.lua` for existing remaps
- Test in all modes (normal, visual, operator-pending)

### LSP Configuration
- **Always use native API**: `vim.lsp.config()` + `vim.lsp.enable()` (NOT `lspconfig.setup()`)
- Add new servers to both `servers` table (line 20) and enable list (line 78+)
- Create separate config files in `lua/plugins/lsp/servers/{lang}.lua`
- Use shared `capabilities` and `on_attach` from `lsp.utils`

### Plugin Loading Strategy
- Use lazy loading (`event`, `cmd`, `keys`) for non-critical plugins
- Core plugins (LSP, treesitter): `lazy = false`
- UI plugins: `event = "VeryLazy"`
- Editor plugins: `event = "BufReadPre"` or `event = "InsertEnter"`

### File Modifications
- **Always check CLAUDE.md** before making keybinding changes
- **Preserve existing patterns**: Match indentation, comment style, structure
- **Test LSP changes**: Restart Neovim and check `:LspInfo` after server config changes
- **Update lazy-lock.json**: Run `:Lazy sync` after adding new plugins

## Common Workflows

### Adding a New Plugin
1. Create `lua/plugins/{category}/{plugin-name}.lua`
2. Follow plugin structure pattern (see Code Style)
3. Add appropriate lazy-loading triggers
4. Document keybindings with `desc` field
5. Test: `:Lazy sync` then restart Neovim

### Adding a Language Server
1. Create `lua/plugins/lsp/servers/{lang}.lua` using template
2. Add server to `servers` table in `lua/plugins/lsp/lsp.lua:20`
3. Add to `server_configs` table (line 49)
4. Add `vim.lsp.enable('server_name')` at line 78+
5. Test: `:Mason` to verify installation, `:LspInfo` to check attachment

### Adding a Formatter
1. Add to `formatters_by_ft` in `lua/plugins/editor/conform.lua:11`
2. (Optional) Configure in `formatters` table (line 38)
3. Install via Mason: `:MasonInstall <formatter-name>`
4. Test: `:ConformInfo` then `:Format`

### Debugging Issues
- **Plugin not loading**: Check `:Lazy` for errors
- **LSP not attaching**: Check `:LspInfo`, verify root markers
- **Formatter not working**: Check `:ConformInfo`, verify Mason install
- **Keybinding conflict**: Use `:verbose map <key>` to find conflicts

## Documentation Files
- **CLAUDE.md**: Primary documentation, architecture overview
- **KEYBINDINGS.md**: Complete keybinding reference (Colemak layout)
- **docs/android-setup.md**: Android/Java development setup
- **TASKNOTES.md**: TaskNotes plugin guide (if enabled)
