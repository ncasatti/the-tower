[← nvim docs index](../README.md)

# Architecture

How this Neovim configuration is wired. This is the **Explanation** doc — for the
*how it behaves* of a specific feature, see the per-feature docs linked from the
[README](../README.md).

## Table of contents

- [Bootstrap](#bootstrap)
- [Directory layout](#directory-layout)
- [Plugin modules](#plugin-modules)
- [LSP architecture](#lsp-architecture)
- [Keymap system](#keymap-system)
- [Editor settings](#editor-settings)

## Bootstrap

`init.lua` runs three steps in order, then an optional local DB hook:

1. Prepends the Mason bin dir to `PATH` and the site dir to `runtimepath`.
2. `require("config.keys")` — the keymap layer.
3. `require("config.config")` — editor settings.
4. `require("config.lazy")` — bootstraps **lazy.nvim** and imports plugin specs.
5. `pcall(require, "local.databases")` — if present, sets `vim.g.dbs` (gitignored
   local DB connections).

`lazy.lua` imports plugin categories by directory: `ai`, `debug`, `editor`, `git`,
`lsp`, `navigation`, `python`, `snacks`, `testing`, `themes`, `ui`, `writing`,
`database`. Plugin updates are checked automatically (`checker.enabled = true`).

> **`android/` is not wired into the lazy spec** — its import is commented out in
> `lazy.lua`. The directory exists but is not auto-loaded.

## Directory layout

```
nvim/
├── init.lua              # bootstrap
├── lua/
│   ├── config/           # keys.lua (+ keys/core,leader), config.lua, lazy.lua, autocmds.lua
│   ├── plugins/<category>/   # one dir per category (see below)
│   ├── tasknotes/        # TaskNotes plugin — modular impl (config/api/cache/ui/pickers/query/task_ops/pomodoro/init)
│   ├── lsp/utils.lua     # shared capabilities + on_attach
│   └── util/md-preview.lua
├── after/                # ftdetect (jupyter, log) + ftplugin (markdown)
├── plugin/dap-signs-fix.lua
├── scripts/jupyter-pair.sh
└── docs/                 # this documentation set
```

## Plugin modules

| Category | Contents |
|---|---|
| `ai/` | Codeium completion, OpenCode |
| `android/` | adb, build, logcat, gradle (**not wired into lazy spec**) |
| `database/` | vim-dadbod (DB UI) |
| `debug/` | nvim-dap + dap-python |
| `editor/` | treesitter (+context), nvim-cmp, autopairs, conform (format), todo-comments, obsession (sessions), log-highlight |
| `git/` | Neogit |
| `lsp/` | Mason + native LSP, per-server configs, go.nvim, mason-tools |
| `navigation/` | Oil, Harpoon, goto-preview |
| `python/` | Iron (REPL), Pyworks (Jupyter/Molten) |
| `snacks/` | Snacks.nvim — dashboard, picker, scroll, dim, zen, styles, keys |
| `testing/` | Neotest |
| `themes/` | Ayu |
| `ui/` | Lualine, Noice, which-key, twilight, colorizer, toggleterm |
| `writing/` | Obsidian, TaskNotes (spec only — impl in `lua/tasknotes/`, see [TASKNOTES.md](TASKNOTES.md)), render-markdown, markdown-nav, nabla (LaTeX), vimtex |

## LSP architecture

Uses the **native `vim.lsp.config` / `vim.lsp.enable` API** (not `lspconfig.setup`).

- **Mason** (`lsp/lsp.lua`) auto-installs servers via `mason-lspconfig`:
  `clangd`, `rust_analyzer`, `pyright`, `ts_ls`, `gopls`, `lua_ls`, `jdtls`,
  `kotlin_language_server`, `jsonls`, `yamlls`, `bashls`, `nil_ls`.
- **Per-server configs** live in `lsp/servers/*.lua` (one module per language:
  clang, rust, python, typescript, go, lua, java, kotlin, json, yaml, markdown,
  bash, nix). Each exports `config(capabilities, on_attach)`; `lsp.lua` loops over
  them, then calls `vim.lsp.enable(...)` per server (markdown enables `marksman`).
- **Shared setup** in `lsp/utils.lua` (`get_capabilities`, `on_attach`).
- **Mason tools** (`lsp/mason-tools.lua`) installs non-LSP tooling: `debugpy`,
  `black`, `isort`, `ruff`, `mypy`, `js-debug-adapter`, `prettier`, `stylua`,
  `shfmt`, `nixfmt`.

Diagnostics: `[d` / `]d` navigate, `<leader>le` float, `<leader>lq` loclist.

> **Adding a language server:** add it to the `servers` list in `lsp/lsp.lua`,
> create `lsp/servers/<name>.lua` exporting `config(capabilities, on_attach)`, add
> the matching `vim.lsp.enable('<server>')`, restart (Mason auto-installs).

## Keymap system

**This config remaps core navigation to a Colemak layout.** Standard `hjkl` do not
behave as in vanilla Vim — see [keys/editor.md](keys/editor.md) for the full table.

- `config/keys.lua` loads `keys/core.lua` (Colemak remaps across normal/visual/
  operator-pending) and `keys/leader.lua` (global leader maps: windows, splits,
  resize, misc).
- Core remap: **u/e/i/n → up/down/right/left** (`k/j/l/h`); `N/I` word back/forward;
  `l/L` enter insert; `o` inner text object; `z` undo; `k/K` next/prev search.
- Plugin-specific maps live in each plugin spec under `keys = {}`.

Leader namespace allocation:

| Prefix | Domain | Prefix | Domain |
|---|---|---|---|
| `<leader>a` | AI (OpenCode) | `<leader>m` | Markdown |
| `<leader>b` | Buffers | `<leader>o` | Obsidian / TaskNotes |
| `<leader>B` | Database | `<leader>r` | REPL / Jupyter |
| `<leader>d` | Debug (DAP) | `<leader>s` | Search (Snacks) |
| `<leader>g` | Git | `<leader>t` | Find files + Harpoon |
| `<leader>l` | LSP | `<leader>T` | Test (Neotest) |
| `<leader>L` | Language tools | `<leader>w` | Window |
| | | `<leader>x` | Android |

## Editor settings

Highlights from `config/config.lua`:

- 2-space `expandtab`; `autoindent` + `smartindent`.
- `relativenumber` + `number`; `signcolumn=yes`.
- `ignorecase` + `smartcase`; persistent `undofile`.
- `termguicolors`; `clipboard=unnamedplus`.
- **`conceallevel=2`** (required by Obsidian markdown features; level 3 breaks them).
- `wrap` + `linebreak` + `breakindent`; visible `listchars` (trailing space, tab,
  nbsp).
