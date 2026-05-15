-- Global leader keys
-- Plugin-specific leader keys live in their plugin spec under `keys = {}`.

-- Misc
vim.keymap.set("n", "<leader>,", "<S-i>", { noremap = true, desc = "Insert at line start" })
vim.keymap.set("n", "<leader>k", "ggVGy", { noremap = true, desc = "Yank entire buffer" })
vim.keymap.set("n", "<leader>W", ":set wrap!<CR>", { noremap = true, desc = "Toggle line wrap" })
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
vim.keymap.set("n", "<leader>wi", ":vertical resize +10<CR>", { noremap = true, silent = true, desc = "Resize width +10" })
vim.keymap.set("n", "<leader>wn", ":vertical resize -10<CR>", { noremap = true, silent = true, desc = "Resize width -10" })
