-- Conform.nvim - Modern formatting with Mason integration
return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" }, -- Load before saving
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>ll",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = { "n", "v" },
			desc = "Format: Buffer or selection",
		},
		{
			"<leader>lf",
			function()
				vim.g.format_on_save = not vim.g.format_on_save
				local status = vim.g.format_on_save and "enabled" or "disabled"
				vim.notify("Format on save: " .. status, vim.log.levels.INFO)
			end,
			mode = "n",
			desc = "Format: Toggle format on save",
		},
	},
	config = function()
		local conform = require("conform")

		conform.setup({
			-- Formatters by filetype
			formatters_by_ft = {
				python = { "black", "isort" }, -- black for formatting, isort for imports
				lua = { "stylua" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				markdown = { "mdformat" },
				html = { "prettier" },
				css = { "prettier" },
				sh = { "shfmt" },
				rust = { "rustfmt" },
				go = { "gofmt" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				nix = { "alejandra" },
			},

			-- Format options
			format_on_save = false, -- Disable auto-format on save (manual with <leader>ll)
			-- format_on_save = {
			--   timeout_ms = 500,
			--   lsp_fallback = true,
			-- },

			-- Formatter configurations
			formatters = {
				black = {
					prepend_args = { "--line-length", "88" }, -- Black default
				},
				isort = {
					prepend_args = { "--profile", "black" }, -- Compatible with black
				},
				mdformat = {
					prepend_args = { "--sort-front-matter" },
				},
			},
		})

		-- Manual format command (replaces LSP format)
		vim.api.nvim_create_user_command("Format", function(args)
			local range = nil
			if args.count ~= -1 then
				local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
				range = {
					start = { args.line1, 0 },
					["end"] = { args.line2, end_line:len() },
				}
			end
			conform.format({ async = true, lsp_fallback = true, range = range })
		end, { range = true })

		-- Format on save for specific filetypes (optional)
		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = { "*.py", "*.lua", "*.rs", "*.go", "*.nix" },
			callback = function(args)
				-- Only format if user wants it (toggle with <leader>lf)
				if vim.g.format_on_save then
					conform.format({ bufnr = args.buf, lsp_fallback = true })
				end
			end,
		})

		-- Default: enabled
		if vim.g.format_on_save == nil then
			vim.g.format_on_save = true
		end
	end,
}
