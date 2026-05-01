return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	lazy = false,
	config = function()
		-- Detect if running in Nix environment
		-- local is_nix = string.find(vim.v.progpath, "/nix/store") ~= nil

		-- Define ensure_installed based on environment
		is_nix = false
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

		-- New API for nvim-treesitter (main branch)
		if not is_nix and #ensure_installed > 0 then
			pcall(function()
				require("nvim-treesitter").install(ensure_installed)
			end)
		end

		-- Enable highlighting natively
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "*",
			callback = function()
				pcall(vim.treesitter.start)
			end,
		})

		-- Enable indentation natively
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "*",
			callback = function()
				vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end,
		})
	end,
}
