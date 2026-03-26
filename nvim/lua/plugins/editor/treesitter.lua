return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
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
				"sql",
			},
			sync_install = false,
			highlight = { enable = true },
			indent = { enable = true },
		})
	end,
}
