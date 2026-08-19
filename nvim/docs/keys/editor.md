# Editor & Colemak Core

## Colemak navigation (replaces hjkl)

- `u` — Up (was `k`)
- `e` — Down (was `j`)
- `i` — Right (was `l`)
- `n` — Left (was `h`)
- `N` — Word backward (was `b`)
- `I` — Word forward (was `e`)
- `U` — Page up + center (was `<C-u>`)
- `E` — Page down + center (was `<C-d>`)
- `o` — Inner text object (was `i`, in visual/operator mode)
- `]]` / `[[` — Next/prev header + center
- `k` / `K` — Next/prev search result (was `n`/`N`)

## Viewport scroll (Colemak directions, cursor stays)

Scrolls the viewport without moving the cursor — useful for long wrapped
lines, wide tables, and lines extending past the right edge (e.g. unwrapped
URLs). Snacks smooth-animates the underlying vanilla motions.

- `<C-u>` — Scroll viewport up (was default `<C-u>`: half-page jump with cursor)
- `<C-e>` — Scroll viewport down (vanilla `<C-e>`)
- `<C-n>` — Scroll viewport left (Colemak-left)
- `<C-i>` — Scroll viewport right (Colemak-right; note: `<C-i>` shares a key with `<Tab>`, normal-mode only)

## Editing

- `l` — Enter insert mode (was `i`)
- `L` — Insert at line start (was `I`)
- `z` — Undo (was `u`)
- `Y` — Yank line
- `P` — Paste from register `0`
- `R` — Center screen (was `zz`)
- `nn` — Exit insert / terminal mode + center
- `<leader>-` — Jump to matching bracket
- `<leader>,` — Insert at line start
- `<leader>k` — Yank entire buffer
- `<leader>W` — Toggle wrap + linebreak (cuts at word boundaries; long links no longer break mid-URL)

## Buffers

- `<leader>bb` — Buffer picker (Snacks)
- `<leader>bd` — Delete current buffer
- `<leader>bD` — Delete all buffers except current
- `<leader>bw` — Wipe hidden buffers
- `<leader>to` — Previous buffer (`b#`)
- `<leader>cR` — Rename file (Snacks)

## Windows

- `<leader>u` / `<leader>e` / `<leader>i` / `<leader>n` — Focus window above/below/right/left
- `<leader>h` — Vertical split
- `<leader>v` — Horizontal split
- `<leader>wu` / `<leader>we` — Resize height +/− 10
- `<leader>wi` / `<leader>wn` — Resize width +/− 10

## Search (Snacks pickers, `<leader>s*`)

- `<leader>/` — Live grep
- `<leader>:` — Command history
- `<leader>sb` — Lines in current buffer
- `<leader>sB` — Grep across open buffers
- `<leader>sg` — Live grep
- `<leader>sw` — Word under cursor or visual selection
- `<leader>s"` — Registers
- `<leader>s/` — Search history
- `<leader>sa` — Autocmds
- `<leader>sc` / `<leader>sC` — Command history / Commands
- `<leader>sd` / `<leader>sD` — Diagnostics (all / buffer)
- `<leader>sh` / `<leader>sH` — Help pages / Highlights
- `<leader>si` — Icons
- `<leader>sj` — Jumps
- `<leader>sk` — Keymaps
- `<leader>sl` — Location list
- `<leader>sm` / `<leader>sM` — Marks / Man pages
- `<leader>sp` — Plugin specs (lazy)
- `<leader>sq` — Quickfix list
- `<leader>sR` — Resume last picker
- `<leader>su` — Undo history

## Misc

- `<leader>?` — Show which-key popup
- `<leader>z` / `<leader>Z` — Toggle Zen mode (regular / dim)
- `<leader>.` — Toggle scratch buffer
- `<leader>S` — Select scratch buffer
- `<c-/>` — Toggle terminal
- `<leader>ct` — Toggle treesitter-context
- `[c` — Jump to context (treesitter-context)
- `]]` / `[[` — Snacks word references next/prev (in non-markdown buffers)
