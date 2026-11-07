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
	-- Home Manager installs the Nix-provided treesitter grammars as a pack
	-- plugin (~/.local/share/nvim/site/pack/*/start/nvim-treesitter-grammars),
	-- holding parser/<lang>.so for every grammar listed in
	-- nix/packages/nvim.nix — including tree-sitter-hcl.
	--
	-- lazy.nvim resets the runtimepath to stdpath("config") + a few entries,
	-- which DROPS the packpath plugins: Neovim's packloadall adds them at
	-- startup, the reset then removes them again. Only the parsers
	-- nvim-treesitter compiles at runtime into stdpath("data")/site/parser
	-- survive, because "site" is one of the entries the reset keeps.
	--
	-- Re-adding the grammars plugin after the reset makes the Nix-provided
	-- parsers reachable. Without this, tree-sitter-hcl is invisible to
	-- Neovim and the HCL outline reports "no hcl parser available".
	--
	-- The queries come from the OTHER end: nvim-treesitter keeps them in
	-- its own runtime/queries/<lang>/, which is not on the runtimepath (the
	-- plugin root is). The pack's queries/hcl is an empty directory — a
	-- nixpkgs quirk — so the highlights query for HCL has to come from
	-- lazy's copy. Without it vim.treesitter.start() still succeeds but
	-- produces no highlighting, and it disables the legacy syntax file, so
	-- HCL would lose its colors entirely.
	performance = {
		rtp = {
			paths = (function()
				-- vim.fn.glob() takes one pattern and returns a list; a list of
				-- patterns is an error ("Using a List as a String").
				local out = {}
				for _, pattern in ipairs({
					vim.fn.stdpath("data") .. "/site/pack/*/start/nvim-treesitter-grammars",
					vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/runtime",
				}) do
					vim.list_extend(out, vim.fn.glob(pattern, false, true))
				end
				return out
			end)(),
		},
	},
	spec = {
		-- { import = "plugins.ai" },
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
