# Database

`vim-dadbod` + `vim-dadbod-ui` + `vim-dadbod-completion`.
Connections loaded from `lua/local/databases.lua` (not tracked in git).

## Global (`<leader>B*`, lazy-loaded)

- `<leader>Bb` — Toggle DBUI
- `<leader>Bf` — Find database buffer
- `<leader>Br` — Rename database buffer
- `<leader>Bq` — Last query info

## SQL files (`sql`, `mysql`, `plsql`, buffer-local)

### Custom (defined in `dadbod.lua`)
- `<leader><CR>` (n/v) — Execute query (fast)
- `<leader>BS` (n/v) — Execute query
- `<leader>BW` — Save query

### Plugin defaults (active via `db_ui_disable_mappings = 0`)
- `<leader>S` — Execute query (`DBUI_ExecuteQuery`)
- `<leader>W` — Save query (`DBUI_SaveQuery`)
- `<leader>E` — Edit bind parameters (`DBUI_EditBindParameters`)

> ⚠️ Plugin defaults `<leader>S` shadows the Snacks `<leader>S` (Select Scratch Buffer) when inside SQL buffers. `<leader>E` and `<leader>W` are otherwise unused globally.

## DBUI buffer (`FileType=dbui`)

- `u` / `e` — Move up / down (Colemak)
- `<CR>` — Select line (open query / expand node)
- `o` — Open in vsplit
- `S` — Open in split
- `R` — Redraw UI
- `d` — Delete (buffer / connection / saved query)
- `A` — Add connection
- `H` — Toggle result layout

## Commands

- `:DBUI` / `:DBUIToggle` — Open / toggle UI
- `:DBUIAddConnection` — Add a new connection
- `:DBUIFindBuffer` — Jump to existing DB buffer
- `:DB [conn] [query]` — Execute query against connection

## Settings

- Window position: `left`, width `40`
- Save location: `~/.local/share/nvim/db_ui`
- Auto-execute on save: **OFF**
- nvim-cmp source `vim-dadbod-completion` registered in SQL filetypes
