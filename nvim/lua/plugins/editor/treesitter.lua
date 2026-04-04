return {
	"nvim-treesitter/nvim-treesitter",
	branch = "master",
	build = ":TSUpdate",
	lazy = false,
	config = function()
		-- Detect if running in Nix environment
		local is_nix = string.find(vim.v.progpath, "/nix/store") ~= nil

		-- Define ensure_installed based on environment
		local ensure_installed
		if is_nix then
			-- In Nix, treesitter parsers are provided via nvim-treesitter.withPlugins
			ensure_installed = {}
		else
			-- In Arch (non-Nix), auto-install parsers
			ensure_installed = {
				"vim",
				"lua",
				"vimdoc",
				"javascript",
				"typescript",
				"html",
				"css",
				"go",
				"bash",
				"nix",
				"python",
				"java",
				"kotlin",
				"json",
				"yaml",
				"toml",
				"markdown",
				"markdown_inline",
				"latex",
				"sql",
			}
		end

		require("nvim-treesitter.configs").setup({
			ensure_installed = ensure_installed,
			sync_install = false,
			auto_install = not is_nix,
			highlight = { enable = true },
			indent = { enable = true },
		})
	end,
}
