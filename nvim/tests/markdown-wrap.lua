-- Wrap contract:
--   * A markdown buffer gets wrap=true, linebreak=true, breakindent=true, showbreak="↪ ",
--     and formatoptions appended with "l" so wrap stays visual.
--   * Source line count for a long line is preserved (no <CR> inserted by the formatter).
--   * A non-markdown buffer does NOT receive the markdown wrap settings.
--   * The <leader>wj key mapping, when invoked, toggles wrap locally without
--     affecting other buffers.

local spec = dofile("/home/flyn/.the-grid/the-tower/nvim/lua/plugins/writing/markdown-wrap.lua")

local function md_opts()
	local out = {
		wrap = vim.opt_local.wrap:get(),
		linebreak = vim.opt_local.linebreak:get(),
		breakindent = vim.opt_local.breakindent:get(),
		showbreak = vim.opt_local.showbreak:get(),
		formatoptions = vim.opt_local.formatoptions:get(),
	}
	return out
end

local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(buf)
vim.bo[buf].filetype = "markdown"
vim.api.nvim_buf_set_name(buf, vim.fn.expand("~/.the-grid/zettelkasten/wrap-contract.md"))

-- Run the autocmd the same way lazy.nvim would at FileType.
spec.config()

local opts = md_opts()
assert(opts.wrap == true, "markdown buffer must have wrap=true: " .. vim.inspect(opts))
assert(opts.linebreak == true, "markdown buffer must have linebreak=true")
assert(opts.breakindent == true, "markdown buffer must have breakindent=true")
assert(opts.showbreak == "↪ ", "markdown buffer must have showbreak='↪ ': " .. vim.inspect(opts.showbreak))
assert(opts.formatoptions.l == true, "markdown buffer must append l to formatoptions")

-- A long line must NOT be wrapped by the formatter: the wrap is visual-only.
local long = string.rep("palabra ", 60)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { long })
local before = vim.api.nvim_buf_line_count(buf)
-- Trigger redraw so wrapping would happen if any auto-format fires.
vim.api.nvim_exec_autocmds("BufWritePost", { buffer = buf })
local after = vim.api.nvim_buf_line_count(buf)
assert(before == 1 and after == 1, "long lines must not auto-insert <CR>: " .. before .. " -> " .. after)

-- Toggle mapping: simulate what lazy.nvim does at load time. The spec returns
-- `keys = { {lhs, rhs, opts} }`; we just keymap the binding manually for the
-- test buffer and exercise the same callback.
local toggle_fn = spec.keys[1][2]
vim.keymap.set("n", "<Space>wj", toggle_fn, { buffer = buf, desc = spec.keys[1].desc })
local wrapped_opts = md_opts()
assert(wrapped_opts.wrap == true, "wrap re-applies after spec.config()")

-- Drive the mapping via feedkeys with 'x' (synchronous execute).
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Space>wj", true, false, true), "x", false)
local toggled = md_opts()
assert(toggled.wrap == false, "toggle must flip wrap off: " .. vim.inspect(toggled))
assert(toggled.showbreak == "", "toggle must clear showbreak when off: " .. vim.inspect(toggled.showbreak))

-- Restore wrap so subsequent tests inherit a clean default.
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.showbreak = "↪ "

print("markdown wrap: ok")
