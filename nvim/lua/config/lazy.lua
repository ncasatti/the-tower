-- Install lazylazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
	spec = {
		{ import = "plugins.ai" },
		-- Android and Gradle utilities auto-load from plugin/ directory
		-- { import = "plugins.android" },
		{ import = "plugins.debug" },
		{ import = "plugins.editor" },
		{ import = "plugins.git" },
		{ import = "plugins.lsp" },
		{ import = "plugins.navigation" },
		{ import = "plugins.python" }, -- Iron.nvim (REPL) and Pyworks (Jupyter/Molten)
		require("plugins.snacks.init"), -- snacks has its own structure with init.lua
		{ import = "plugins.testing" }, -- Neotest and test runners
		{ import = "plugins.themes" },
		{ import = "plugins.ui" },
		{ import = "plugins.writing" },
		{ import = "plugins.database" },
	},
	-- colorscheme that will be used when installing plugins.
	install = {
		-- colorscheme = { "habamax" }
		colorcheme = { "onedark" },
	},
	-- automatically check for plugin updates
	checker = { enabled = true },
})
