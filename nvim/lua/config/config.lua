vim.cmd([[
  set expandtab
  set tabstop=2
  set softtabstop=2
  set shiftwidth=2
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

-- Obsidian plugin requires conceallevel 2 for markdown features
-- Level 2: conceal with substitution chars. Level 3: hide all (breaks Obsidian UI)
vim.o.conceallevel = 1

-- Themes
-- vim.cmd.colorscheme "catppuccin"
-- vim.opt.guifont = { "Cascadia Code", "h12" }
vim.opt.clipboard = "unnamedplus"

vim.opt.linebreak = true
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.showbreak = " " --

-- Show trailing whitespace and other invisible characters
vim.opt.list = true
vim.opt.listchars = {
	trail = "·", -- Show trailing spaces as middle dots
	tab = "→ ", -- Show tabs as arrows
	nbsp = "␣", -- Show non-breaking spaces
	extends = "»", -- Show when line extends beyond screen
	precedes = "«", -- Show when line precedes beyond screen
}
