-- Configurar leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Insert Mode
vim.keymap.set("i", "nn", "<Esc>", { noremap = true, desc = "Exit insert mode" })

-- Terminal Mode
vim.keymap.set("t", "nn", "<C-\\><C-n>", { noremap = true, desc = "Exit terminal mode" })

-- Visual Mode
vim.keymap.set("v", "u", "k", { noremap = true, desc = "Colemak: Up" })
vim.keymap.set("v", "e", "j", { noremap = true, desc = "Colemak: Down" })
vim.keymap.set("v", "i", "l", { noremap = true, desc = "Colemak: Right" })
vim.keymap.set("v", "n", "h", { noremap = true, desc = "Colemak: Left" })
vim.keymap.set("v", "N", "b", { noremap = true, desc = "Colemak: Word back" })
vim.keymap.set("v", "I", "e", { noremap = true, desc = "Colemak: Word forward" })
vim.keymap.set("v", "o", "i", { noremap = true, desc = "Colemak: Inner" })
-- vim.keymap.set('v', 'E', '}', { noremap = true, desc = "Colemak: Page down" })
-- vim.keymap.set('v', 'U', '{', { noremap = true, desc = "Colemak: Page up" })
vim.keymap.set("v", "E", "<C-d>", { noremap = true, desc = "Colemak: Page down" })
vim.keymap.set("v", "U", "<C-u>", { noremap = true, desc = "Colemak: Page up" })
vim.keymap.set("v", "<leader>-", "%", { noremap = true, desc = "Jump to matching bracket" })
vim.keymap.set("v", "z", "u", { noremap = true, desc = "Undo" })
-- vim.keymap.set('v', ';', 'y', { noremap = true, desc = "Yank" })
vim.keymap.set("v", "Y", "yy", { noremap = true, desc = "Yank line" })
vim.keymap.set("v", "P", '"0p', { noremap = true, desc = "Paste from register 0" })
vim.keymap.set("v", "k", "n", { noremap = true, desc = "Next search result" })
vim.keymap.set("v", "K", "N", { noremap = true, desc = "Previous search result" })

-- Normal Mode
vim.keymap.set("n", "u", "k", { noremap = true, desc = "Colemak: Up" })
vim.keymap.set("n", "e", "j", { noremap = true, desc = "Colemak: Down" })
vim.keymap.set("n", "i", "l", { noremap = true, desc = "Colemak: Right" })
vim.keymap.set("n", "n", "h", { noremap = true, desc = "Colemak: Left" })
vim.keymap.set("n", "N", "b", { noremap = true, desc = "Colemak: Word back" })
vim.keymap.set("n", "I", "e", { noremap = true, desc = "Colemak: Word forward" })
-- vim.keymap.set('n', 'E', '}', { noremap = true, desc = "Colemak: Page down" })
-- vim.keymap.set('n', 'U', '{', { noremap = true, desc = "Colemak: Page up" })
vim.keymap.set("n", "E", "}zz", { noremap = true, desc = "Colemak: Page down" })
vim.keymap.set("n", "U", "{zz", { noremap = true, desc = "Colemak: Page up" })
vim.keymap.set("n", "<leader>-", "%", { noremap = true, desc = "Jump to matching bracket" })
vim.keymap.set("n", "z", "u", { noremap = true, desc = "Undo" })
-- vim.keymap.set('n', ';', 'y', { noremap = true, desc = "Yank" })
vim.keymap.set("n", "Y", "yy", { noremap = true, desc = "Yank line" })
vim.keymap.set("n", "P", '"0p', { noremap = true, desc = "Paste from register 0" })
vim.keymap.set("n", "k", "n", { noremap = true, desc = "Next search result" })
vim.keymap.set("n", "K", "N", { noremap = true, desc = "Previous search result" })
vim.keymap.set("n", "l", "i", { noremap = true, desc = "Enter insert mode" })
vim.keymap.set("n", "L", "I", { noremap = true, desc = "Insert at line start" })
vim.keymap.set("n", "<leader>,", "<S-i>", { noremap = true, desc = "Insert at line start" })
vim.keymap.set("n", "<leader>k", "ggVGy", { noremap = true, desc = "Yank entire buffer" })
vim.keymap.set("n", "<leader>h", ":vsplit<CR><C-w>w", { noremap = true, desc = "Vertical split" })
vim.keymap.set("n", "<leader>v", ":split<CR><C-w>w", { noremap = true, desc = "Horizontal split" })
vim.keymap.set("n", "<leader>o", "o<Esc>", { noremap = true, desc = "Insert blank line below" })
vim.keymap.set("n", "R", "zz", { noremap = true, desc = "Center screen" })
vim.keymap.set("n", "<leader>W", ":set wrap!<CR>", { noremap = true, desc = "Toggle line wrap" })
vim.keymap.set("n", "<leader>to", "<cmd>b#<CR>", { noremap = true, desc = "Previous buffer" })

-- Operator-Pending Mode (CRITICAL: enables motions after d, c, y, v, etc.)
vim.keymap.set("o", "u", "k", { noremap = true, desc = "Colemak: Up" })
vim.keymap.set("o", "e", "j", { noremap = true, desc = "Colemak: Down" })
-- vim.keymap.set('o', 'i', 'l', { noremap = true, desc = "Colemak: Right" })
vim.keymap.set("o", "n", "h", { noremap = true, desc = "Colemak: Left" })
vim.keymap.set("o", "N", "b", { noremap = true, desc = "Colemak: Word back" })
vim.keymap.set("o", "I", "e", { noremap = true, desc = "Colemak: Word forward" })
vim.keymap.set("o", "o", "i", { noremap = true, desc = "Colemak: Inner text object" })
vim.keymap.set("o", "E", "<C-d>", { noremap = true, desc = "Colemak: Page down" })
vim.keymap.set("o", "U", "<C-u>", { noremap = true, desc = "Colemak: Page up" })
vim.keymap.set("o", "<leader>-", "%", { noremap = true, desc = "Jump to matching bracket" })
vim.keymap.set("o", "k", "n", { noremap = true, desc = "Next search result" })
vim.keymap.set("o", "K", "N", { noremap = true, desc = "Previous search result" })

-- Windows Navigation
vim.keymap.set("n", "<leader>u", "<C-w>k", { noremap = true, desc = "Move to window above" })
vim.keymap.set("n", "<leader>e", "<C-w>j", { noremap = true, desc = "Move to window below" })
vim.keymap.set("n", "<leader>i", "<C-w>l", { noremap = true, desc = "Move to window right" })
vim.keymap.set("n", "<leader>n", "<C-w>h", { noremap = true, desc = "Move to window left" })

-- Window Resize (Colemak-friendly)
vim.keymap.set("n", "<leader>ru", ":resize +10<CR>", { noremap = true, silent = true, desc = "Resize height +10" })
vim.keymap.set("n", "<leader>re", ":resize -10<CR>", { noremap = true, silent = true, desc = "Resize height -10" })
vim.keymap.set(
	"n",
	"<leader>ri",
	":vertical resize +10<CR>",
	{ noremap = true, silent = true, desc = "Resize width +10" }
)
vim.keymap.set(
	"n",
	"<leader>rn",
	":vertical resize -10<CR>",
	{ noremap = true, silent = true, desc = "Resize width -10" }
)
