-- nvim/lua/plugins/writing/markdown-wrap.lua
-- Soft-wrap long markdown lines without touching the buffer.
--
-- Applies wrap + linebreak + breakindent + showbreak on FileType markdown.
-- `formatoptions += "l"` keeps the wrap visual-only: it does NOT auto-insert
-- <CR> at the typed column. Source stays canonical and mdformat-compatible.
--
-- Toggle per-buffer with `<leader>wj`. Useful when a fenced code block
-- contains long lines and the `↪ ` continuation marker inside the block
-- becomes noisy.
--
-- Local-only spec — uses the same `dir + name` marker pattern as
-- tasknotes.lua. Without a `dir` (or a positional source, or a `url`),
-- lazy.nvim rejects the spec as "Invalid plugin spec" because none of its
-- three identification branches in `lazy/core/plugin.lua:normalize` match.

local function apply_wrap()
	vim.opt_local.wrap = true
	vim.opt_local.linebreak = true
	vim.opt_local.breakindent = true
	vim.opt_local.showbreak = "↪ "
	-- Disable auto-wrap at the typed column ("l") while still allowing the
	-- operator-driven gq formatter ("q") to reflow on demand. Adjust to taste.
	vim.opt_local.formatoptions:append("l")
end

return {
	dir = vim.fn.stdpath("config") .. "/lua/plugins/writing",
	name = "markdown-wrap",
	event = { "FileType markdown", "FileType markdown.md" },
	config = function()
		apply_wrap()
	end,
	keys = {
		{
			"<leader>wj",
			function()
				local next_state = not vim.opt_local.wrap:get()
				vim.opt_local.wrap = next_state
				vim.opt_local.linebreak = next_state
				vim.opt_local.showbreak = next_state and "↪ " or ""
				vim.notify("markdown wrap: " .. (next_state and "on" or "off"), vim.log.levels.INFO)
			end,
			buffer = true,
			desc = "Toggle markdown wrap",
		},
	},
}
