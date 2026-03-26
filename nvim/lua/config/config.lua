vim.cmd([[
  set expandtab
  set tabstop=4
  set softtabstop=4
  set shiftwidth=4
  set autoindent
  set smartindent
  set relativenumber
  set number
  set signcolumn=yes
]])

-- Case insensitive searching
vim.o.ignorecase = true
vim.o.smartcase = true

-- Save undo history
vim.o.undofile = true

-- Fixes Notify opacity issues
vim.o.termguicolors = true

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

-- Obsidian plugin requires conceallevel for markdown features
-- vim.o.conceallevel = 2
vim.o.conceallevel = 3

-- Themes
-- vim.cmd.colorscheme "catppuccin"
-- vim.opt.guifont = { "Cascadia Code", "h12" }
vim.opt.clipboard = "unnamedplus"

vim.opt.linebreak = true
vim.opt.wrap = true

-- Show trailing whitespace and other invisible characters
vim.opt.list = true
vim.opt.listchars = {
	trail = "·", -- Show trailing spaces as middle dots
	tab = "→ ", -- Show tabs as arrows
	nbsp = "␣", -- Show non-breaking spaces
	extends = "»", -- Show when line extends beyond screen
	precedes = "«", -- Show when line precedes beyond screen
}
