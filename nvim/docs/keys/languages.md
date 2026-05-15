# Languages

Filetype-specific tooling: Go (go.nvim + gopher.nvim), Python (Iron REPL + Jupyter).

## Go (`<leader>L*`, buffer-local in `.go`)

### Struct tags / scaffolding
- `<leader>Lsj` — Add json tags
- `<leader>Lsy` — Add yaml tags
- `<leader>Lst` — Add struct tags (interactive)
- `<leader>Lsr` — Remove struct tags
- `<leader>Lsf` — Fill struct
- `<leader>Lsi` — Add `if err` block (go.nvim)
- `<leader>Lie` — Add `if err` block (gopher.nvim)
- `<leader>Lim` — Implement interface (`:GoImpl`)
- `<leader>Lsm` — `go mod tidy`

### Tests & coverage
- `<leader>Ltt` — Run tests
- `<leader>Lts` — Run tests with summary
- `<leader>Ltf` — Run test for current function
- `<leader>LtF` — Run test for current file
- `<leader>Lch` — Test coverage

### Debug / nav
- `<leader>Ldb` — Start debugging
- `<leader>Ldt` — Stop debugging
- `<leader>Lta` — Open alternate file (test ↔ source)

## Python REPL (`<leader>r*`, buffer-local in `.py`)

### REPL lifecycle
- `<leader>rs` — Start / toggle REPL (iPython)
- `<leader>rr` — Restart REPL
- `<leader>rf` — Focus REPL window
- `<leader>rh` — Hide REPL
- `<leader>rq` — Exit REPL
- `<leader>rx` — Clear REPL

### Send code (Iron)
- `<leader>rF` — Send file
- `<leader>rL` — Send line
- `<leader>rS` — Send visual selection
- `<leader>rp` — Send paragraph
- `<leader>rb` — Send block
- `<leader>rc{motion}` — Send motion (e.g. `<leader>rcip`)
- `<leader>rl` — Send current line (iron's keymap config)
- `<leader>ru` — Send until cursor
- `<leader>rm{motion}` — Send mark / mark motion
- `<leader>rmd` — Remove mark
- `<leader>r<cr>` — Send carriage return
- `<leader>r<space>` — Interrupt REPL

## Python Jupyter / Molten (`<leader>rj*`, buffer-local in `.py`/`.ipynb`)

### Kernel
- `<leader>rji` — Initialize kernel
- `<leader>rjD` — Deinitialize kernel
- `<leader>rjk` — Show output
- `<leader>rjh` — Hide output
- `<leader>rjx` — Interrupt execution

### Execute
- `<leader>rje` — Evaluate (operator in normal, selection in visual)
- `<leader>rjl` — Evaluate line
- `<leader>rjc` — Re-evaluate cell
- `<leader>rjd` — Delete cell output

### Cell navigation
- `[m` — Previous cell
- `]m` — Next cell
