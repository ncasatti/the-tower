# Python Development - Keybindings Reference

Quick reference for all Python-related keybindings in Neovim.

---

## 🐛 Debugging (DAP) - Global

### Breakpoints
- `F9` - Toggle breakpoint
- `<leader>db` - Toggle breakpoint
- `<leader>dB` - Conditional breakpoint

### Execution
- `F5` - Continue/Start debug
- `F6` - Pause
- `F10` - Step over
- `F11` - Step into
- `F12` - Step out
- `<leader>dc` - Continue
- `<leader>dC` - Run to cursor
- `<leader>dt` - Terminate

### Inspection
- `<leader>de` - Evaluate expression (normal/visual)
- `<leader>dh` - Hover variables
- `<leader>dp` - Preview

### UI
- `<leader>du` - Toggle DAP UI
- `<leader>dr` - Toggle REPL

---

## 🧪 Testing (Neotest) - Python files only

### Run Tests
- `<leader>Tr` - Run nearest test (cursor on test function)
- `<leader>Tf` - Run file (all tests in current file)
- `<leader>Ta` - Run all (all tests in project)
- `<leader>Tl` - Run last test
- `<leader>Ts` - Stop running tests

### Debug Tests
- `<leader>Td` - Debug nearest test (opens DAP)

### UI
- `<leader>To` - Show output (test under cursor)
- `<leader>TO` - Toggle output panel (all tests)
- `<leader>TS` - Toggle summary (test tree)

### Navigation
- `[T` - Jump to previous failed test
- `]T` - Jump to next failed test

### Watch Mode
- `<leader>Tw` - Toggle watch (auto-run on save)

---

## 🐍 REPL (Iron.nvim) - Python files only

### REPL Management
- `<leader>rs` - Start/Toggle REPL
- `<leader>rr` - Restart REPL
- `<leader>rf` - Focus REPL window
- `<leader>rh` - Hide REPL window
- `<leader>rq` - Exit REPL
- `<leader>rx` - Clear REPL

### Send Code
- `<leader>rl` - Send current line
- `<leader>rL` - Send line (alternative)
- `<leader>rF` - Send entire file
- `<leader>rS` - Send selection (visual mode)
- `<leader>rc` - Send motion (e.g., `<leader>rc` + `ip` for paragraph)
- `<leader>rp` - Send paragraph
- `<leader>rb` - Send block
- `<leader>ru` - Send from start to cursor

### REPL Control
- `<leader>r<space>` - Interrupt REPL
- `<leader>r<cr>` - Send carriage return

---

## 📓 Molten/Jupyter (Pyworks) - Python/Jupyter files

### Kernel Management
- `<leader>mi` - Initialize Molten kernel
- `<leader>mD` - Deinitialize kernel

### Execute Code
- `<leader>ml` - Evaluate current line
- `<leader>me` - Evaluate selection (visual mode)
- `<leader>mc` - Re-evaluate cell
- `<leader>mx` - Interrupt execution

### Output
- `<leader>mk` - Show output
- `<leader>mh` - Hide output
- `<leader>md` - Delete cell output

### Navigation
- `[m` - Previous cell
- `]m` - Next cell

---

## 🎯 Workflow Examples

### Quick Script Debugging
1. Open Python file
2. Set breakpoint: `F9`
3. Start debug: `F5`
4. Navigate: `F10`/`F11`/`F12`

### Test-Driven Development
1. Write test function
2. Cursor on test → `<leader>Tr`
3. If fails → `<leader>To` (see error)
4. Fix code
5. `<leader>Tr` again

### Interactive Data Exploration (REPL)
1. Open Python script with imports/data loading
2. `<leader>rs` (start REPL)
3. `<leader>rF` (send entire file to load context)
4. Select lines of interest (visual mode)
5. `<leader>rS` (send selection)
6. Iterate: modify code → send again

### Jupyter-style Notebook Work (Molten)
1. Open Python file or `.ipynb` (Jupytext converts)
2. `<leader>mi` (initialize kernel)
3. Select code block (visual mode)
4. `<leader>me` (execute)
5. `<leader>mk` (show output inline)
6. Navigate cells: `]m`/`[m`

---

## 📦 Prerequisites

### For REPL (Iron.nvim):
```bash
sudo pacman -S ipython  # Better REPL with autocomplete
# or fallback to python3 (already configured)
```

### For Molten (Jupyter):
```bash
pip install jupyter pynvim jupyter-client cairosvg plotly kaleido pnglatex pyperclip
# Or use your virtualenv
```

### For Image Display (optional):
- Kitty terminal (already configured)
- Or install ueberzug for other terminals

---

## 🔧 Customization

All keybindings are buffer-local (only active in Python files).

**Files to edit:**
- Debugging: `lua/plugins/debug/dap-python.lua`
- Testing: `lua/plugins/testing/neotest.lua`
- REPL: `lua/plugins/python/iron.lua`
- Molten: `lua/plugins/python/pyworks.lua`
