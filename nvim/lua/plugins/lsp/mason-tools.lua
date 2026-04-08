-- Mason Tool Installer
-- Auto-installs debuggers, formatters, linters beyond LSP servers
return {
	"WhoIsSethDaniel/mason-tool-installer.nvim",
	dependencies = {
		"williamboman/mason.nvim",
	},
	config = function()
		require("mason-tool-installer").setup({
			-- List of tools to auto-install
			ensure_installed = {
				-- Python tools
				"debugpy", -- Python debugger
				"black", -- Python formatter
				"isort", -- Python import sorter
				"ruff", -- Python linter (faster than pylint)
				"mypy", -- Python type checker

				-- Other formatters
				"prettier", -- JS/TS/JSON/YAML/Markdown formatter
				"stylua", -- Lua formatter
				"shfmt", -- Shell formatter
				"alejandra", -- Nix formatter
			},

			-- Auto-update tools
			auto_update = false,

			-- Run on start
			run_on_start = true,

			-- Show notification when install completes
			start_delay = 3000, -- 3 seconds delay
		})
	end,
}
