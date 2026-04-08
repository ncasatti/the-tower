return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		-- Simple inline configs
		bigfile = {
			enabled = true,
			size = 1024 * 1024 * 1.5, -- 1.5MB file size
			lines = 20000, -- Max lines threshold (default: 10000)
			-- Disable notification for bigfile detection
			notify = false,
		},
		explorer = { enabled = false },
		indent = {
			enabled = true,
			animate = {
				easing = "outExpo",
			},
		},
		input = { enabled = true },
		notifier = { enabled = true },
		image = { enabled = true },
		quickfile = { enabled = true },
		scope = { enabled = true },
		statuscolumn = { enabled = false },
		words = { enabled = true },
		lazygit = { enabled = true },
		toggle = { enabled = true },

		-- Scroll with animation settings
		-- Modular configs (loaded from separate files)
		dashboard = require("plugins.snacks.dashboard"),
		picker = require("plugins.snacks.picker"),
		styles = require("plugins.snacks.styles"),
		scroll = require("plugins.snacks.scroll"),
		zen = require("plugins.snacks.zen"),
		dim = require("plugins.snacks.dim"),
	},

	-- Keybindings (loaded from separate file)
	keys = require("plugins.snacks.keys"),
}
