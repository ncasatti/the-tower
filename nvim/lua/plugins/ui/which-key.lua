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

		-- Define groups with icons
		wk.add({
			{ "<leader>a", group = "Android", icon = " " },
			{ "<leader>b", group = "Buffers", icon = "󰓩 " },
			{ "<leader>c", group = "Code/Config", icon = "󰅱 " },
			{ "<leader>d", group = "Debug", icon = "󰃤 " },
			{ "<leader>g", group = "Git/Go/Gradle", icon = "󰊢 " },
			{ "<leader>l", group = "LSP", icon = "󰒋 " },
			{ "<leader>m", group = "Markdown", icon = "󰍔 " },
			{ "<leader>o", group = "Obsidian", icon = "󱓧 " },
			{ "<leader>oz", group = "Task Management", icon = "󰄬 " },
			{ "<leader>ow", group = "Zettelkasten", icon = "󰍉 " },
			{ "<leader>s", group = "Search", icon = "󰍉 " },
			{ "<leader>t", group = "Telescope/Test", icon = "󰭎 " },
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
