-- Global leader keys
-- Plugin-specific leader keys live in their plugin spec under `keys = {}`.

-- Misc
vim.keymap.set("n", "<leader>,", "<S-i>", { noremap = true, desc = "Insert at line start" })
vim.keymap.set("n", "<leader>k", "ggVGy", { noremap = true, desc = "Yank entire buffer" })
-- Toggle wrap + linebreak + showbreak together. With `linebreak` off, Vim cuts
-- at any column (mid-link, mid-word); toggling both keeps wrap behavior sane
-- for long links and prose.
vim.keymap.set("n", "<leader>W", function()
	local next_state = not vim.opt.wrap:get()
	vim.opt.wrap = next_state
	vim.opt.linebreak = next_state
	vim.opt.showbreak = next_state and " " or ""
	-- vim.notify("wrap: " .. (next_state and "on" or "off"), vim.log.levels.INFO)
end, { desc = "Toggle wrap + linebreak" })
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
