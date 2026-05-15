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
			{ "<leader>ow", group = "Zettelkasten",      icon = "󰍉 " },
			{ "<leader>oz", group = "Task Management",   icon = "󰄬 " },
			{ "<leader>r",  group = "REPL",              icon = "󰜎 " },
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
