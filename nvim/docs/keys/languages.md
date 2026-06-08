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

Iron.nvim wraps an iPython process. Labels in which-key are normalized — the
`+REPL` group icon already carries the namespace, so descriptions are bare verbs.

### Lifecycle
- `<leader>rs` — Start / toggle REPL (iPython)
- `<leader>rr` — Restart REPL
- `<leader>rf` — Focus REPL window
- `<leader>rh` — Hide REPL
- `<leader>rq` — Exit REPL
- `<leader>rx` — Clear REPL

### Send code
- `<leader>rl` — Send current line
- `<leader>rc{motion}` — Send motion (e.g. `<leader>rcip` = paragraph)
- `<leader>rc` (visual) — Send selection
- `<leader>ru` — Send until cursor
- `<leader>rF` — Send file
- `<leader>rp` — Send paragraph (shortcut for `rcip`)
- `<leader>rb` — Send block (shortcut for `rcab`)

### Marks
- `<leader>rm` — Send marked region
- `<leader>rmc{motion}` — Mark motion (also visual)
- `<leader>rmd` — Remove mark

### Control
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
