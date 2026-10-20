-- Global leader keys
-- Plugin-specific leader keys live in their plugin spec under `keys = {}`.

-- Misc
vim.keymap.set("n", "<leader>,", "<S-i>", { noremap = true, desc = "Insert at line start" })
vim.keymap.set("n", "<leader>k", "ggVG", { noremap = true, desc = "Yank entire buffer" })
-- Toggle wrap + linebreak + showbreak together. With `linebreak` off, Vim cuts
-- at any column (mid-link, mid-word); toggling both keeps wrap behavior sane
-- for long links and prose.
vim.keymap.set("n", "<leader>W", function()
	-- Per-window toggle. nvim 0.12.2 leaks vim.wo.X=v to the global for global-local
	-- options (wrap, linebreak, showbreak). Use the explicit API which keeps the
	-- global untouched (verified via nvim_get_option_value({scope='global'})).
	local scope = { scope = "local", win = 0 }
	local cur = vim.api.nvim_get_option_value("wrap", scope)
	local next_state = not cur
	-- nabla.nvim (autogen) snapshots wo.wrap on enable_virt() and restores it on
	-- every InsertLeave/TextChanged, reverting this toggle. Cycle it around the
	-- change so its snapshot captures the new state.
	local nabla = package.loaded["nabla"]
	local nabla_on = nabla ~= nil and nabla.is_virt_enabled()
	if nabla_on then
		nabla.disable_virt()
	end
	vim.api.nvim_set_option_value("wrap", next_state, scope)
	vim.api.nvim_set_option_value("linebreak", next_state, scope)
	vim.api.nvim_set_option_value("showbreak", next_state and "" or "", scope)
	if nabla_on then
		nabla.enable_virt({ autogen = true })
	end
	-- vim.notify("wrap: " .. (next_state and "on" or "off"), vim.log.levels.INFO)
end, { desc = "Toggle wrap + linebreak (per-window)" })
vim.keymap.set("n", "<leader>to", "<cmd>b#<CR>", { noremap = true, desc = "Previous buffer" })

-- Window splits
vim.keymap.set("n", "<leader>h", ":vsplit<CR><C-w>w", { noremap = true, desc = "Vertical split" })
vim.keymap.set("n", "<leader>v", ":split<CR><C-w>w", { noremap = true, desc = "Horizontal split" })

-- Window navigation (Colemak directions)
vim.keymap.set("n", "<leader>u", "<C-w>k", { noremap = true, desc = "Move to window above" })
vim.keymap.set("n", "<leader>e", "<C-w>j", { noremap = true, desc = "Move to window below" })
vim.keymap.set("n", "<leader>i", "<C-w>l", { noremap = true, desc = "Move to window right" })
vim.keymap.set("n", "<leader>n", "<C-w>h", { noremap = true, desc = "Move to window left" })

-- Window resize (Colemak-direction suffixes)
vim.keymap.set("n", "<leader>wu", ":resize +10<CR>", { noremap = true, silent = true, desc = "Resize height +10" })
vim.keymap.set("n", "<leader>we", ":resize -10<CR>", { noremap = true, silent = true, desc = "Resize height -10" })
vim.keymap.set(
	"n",
	"<leader>wi",
	":vertical resize +10<CR>",
	{ noremap = true, silent = true, desc = "Resize width +10" }
)
vim.keymap.set(
	"n",
	"<leader>wn",
	":vertical resize -10<CR>",
	{ noremap = true, silent = true, desc = "Resize width -10" }
)
