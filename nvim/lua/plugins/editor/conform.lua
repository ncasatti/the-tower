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

		-- mdformat-front-matters decides the quote style for every YAML
		-- frontmatter value. When a value contains `[[` or `]]` (an Obsidian
		-- wikilink), its internal heuristics flag the value as a potential
		-- flow-sequence start and wrap it in single quotes instead of
		-- preserving the original double quotes — which is technically valid
		-- YAML but breaks the way the rest of the Obsidian stack (obsidian-ls,
		-- dataview, the frontmatter UI) interprets the value.
		--
		-- Workaround: when the frontmatter contains wikilink markers, run
		-- mdformat with only the wikilink extension enabled (no front_matters
		-- normalization). This preserves the user's chosen quote style and
		-- keeps mdformat-wikilink active to protect the `[[...]]` token
		-- from backslash-escaping.
		--
		-- Detection is cheap: read just the first N lines up to the closing
		-- `---` of the frontmatter and regex for `[[`/`]]`. We don't
		-- actually parse the YAML — we're not asking "is this a list of
		-- wikilinks?", we're asking "is there any wikilink token anywhere
		-- in the frontmatter?".
		local function frontmatter_has_wikilinks(bufnr)
			bufnr = bufnr or vim.api.nvim_get_current_buf()
			-- Read up to 200 lines — frontmatter is virtually always
			-- < 100 lines, this gives a generous ceiling.
			local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 200, false)
			if not lines or #lines == 0 or lines[1] ~= "---" then
				return false
			end
			-- Find the closing `---` (line containing only "---"). Skip
			-- the opening one at index 1.
			for i = 2, #lines do
				if lines[i] == "---" then
					return false -- reached end of frontmatter without seeing wikilinks
				end
				if lines[i]:find("%[%[") or lines[i]:find("%]%]") then
					return true
				end
			end
			return false
		end

		-- conform's `prepend_args` accepts a function (self, ctx) -> string[].
		-- We return either the normal chain (`--sort-front-matter`) or the
		-- wikilink-safe chain (`--extensions=wikilink`) per buffer. Both
		-- extensions are auto-discovered by mdformat because they're
		-- installed; passing --extensions overrides the auto-set and is the
		-- documented way to drop a specific extension for one invocation.
		local function mdformat_prepend_args(_, ctx)
			if frontmatter_has_wikilinks(ctx.buf) then
				return { "--extensions=wikilink" }
			end
			return { "--sort-front-matter" }
		end

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
				nix = { "nixfmt" },
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
					prepend_args = mdformat_prepend_args,
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
			pattern = { "*.py", "*.lua", "*.rs", "*.go" },
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
