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
		-- Math/LaTeX rendered as real images via the kitty graphics protocol.
		-- Guard on kitty detection (util/term.lua) instead of TERM, which tmux
		-- rewrites to xterm-256color — the old TERM check left this off inside tmux.
		image = {
			enabled = require("util.term").has_image(),
			-- Render math at body-text size; the default "Large" looked oversized
			-- vs the surrounding text. LaTeX size command sans backslash.
			math = { latex = { font_size = "normalsize" } },
		},
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
