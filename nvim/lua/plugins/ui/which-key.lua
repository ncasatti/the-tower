-- This file contains the configuration for the which-key.nvim plugin in Neovim.

return {
	-- Plugin: which-key.nvim
	-- URL: https://github.com/folke/which-key.nvim
	-- Description: A Neovim plugin that displays a popup with possible keybindings of the command you started typing.
	"folke/which-key.nvim",

	event = "VeryLazy", -- Load this plugin on the 'VeryLazy' event

	config = function()
		local wk = require("which-key")
		wk.setup({
			preset = "modern", -- helix|modern|classic
			-- Hydra mode: keep which-key open for window commands
			show = {
				keys = "<c-w>",
				loop = true,
			},
		})

		-- Group labels (icons + semantic prefix → domain)
		wk.add({
			{ "<leader>a",  group = "AI",                icon = "󰚩 " },
			{ "<leader>b",  group = "Buffers",           icon = "󰓩 " },
			{ "<leader>B",  group = "Database",          icon = "󰆼 " },
			{ "<leader>c",  group = "Code/Config",       icon = "󰅱 " },
			{ "<leader>d",  group = "Debug",             icon = "󰃤 " },
			{ "<leader>g",  group = "Git",               icon = "󰊢 " },
			{ "<leader>l",  group = "LSP",               icon = "󰒋 " },
			{ "<leader>lw", group = "Workspace folders", icon = "󰉋 " },
			{ "<leader>L",  group = "Language tools",    icon = "󰘧 " },
			{ "<leader>m",  group = "Markdown",          icon = "󰍔 " },
			{ "<leader>o",  group = "Obsidian",          icon = "󱓧 " },
			{ "<leader>r",  group = "REPL",              icon = "󰜎 " },
			{ "<leader>rj", group = "Jupyter",           icon = "󰧮 " },
			-- Override iron.nvim auto-generated descs (strip `iron_repl_` prefix)
			{ "<leader>rl", desc = "Send line" },
			{ "<leader>ru", desc = "Send until cursor" },
			{ "<leader>rc", desc = "Send motion",        mode = "n" },
			{ "<leader>rc", desc = "Send selection",     mode = "x" },
			{ "<leader>rm", desc = "Send mark" },
			{ "<leader>rmc", desc = "Mark motion",       mode = "n" },
			{ "<leader>rmc", desc = "Mark selection",    mode = "x" },
			{ "<leader>rmd", desc = "Remove mark" },
			{ "<leader>rq", desc = "Exit" },
			{ "<leader>rx", desc = "Clear" },
			{ "<leader>r<cr>", desc = "Send <CR>" },
			{ "<leader>r<space>", desc = "Interrupt" },
			{ "<leader>s",  group = "Search",            icon = "󰍉 " },
			{ "<leader>t",  group = "Find/Harpoon",      icon = "󰭎 " },
			{ "<leader>T",  group = "Test",              icon = "󰙨 " },
			{ "<leader>w",  group = "Window",            icon = "󰖯 " },
			{ "<leader>x",  group = "Android",           icon = " " },
			{ "<leader>xg", group = "Gradle",            icon = "󰫼 " },
		})
	end,

	init = function()
		-- Set the timeout for key sequences
		vim.o.timeout = true
		vim.o.timeoutlen = 500 -- Reduced for faster Colemak navigation response
	end,

	keys = {
		{
			-- Keybinding to show which-key popup
			"<leader>?",
			function()
				require("which-key").show({ global = false }) -- Show the which-key popup for local keybindings
			end,
			desc = "Show Which-Key",
		},
	},
}
