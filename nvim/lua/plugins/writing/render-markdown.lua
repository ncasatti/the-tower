return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	ft = { "markdown", "md" },
	opts = {
		-- Render on file open
		start_enabled = true,

		-- Show raw markdown when cursor is on the line (anti-conceal)
		anti_conceal = {
			enabled = true,
		},

		-- Heading configuration
		heading = {
			enabled = true,
			sign = true,
			-- icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
			-- icons = { "󰎤 ", "󰎧 ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " },
			-- icons = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
			-- icons = { "󰲠 ", "󰲢 ", "󰲤 ", "󰲦 ", "󰲨 ", "󰲪 " },
			-- icons = { "󰎥 ", "󰎨 ", "󰎫 ", "󰎲 ", "󰎯 ", "󰎴 " },
			icons = { "󱙝 ", "󱙝 ", "󱙝 ", "󱙝 ", "󱙝 ", "󱙝 " },
			-- icons = { "󰨝 ", "󰨝 ", "󰨝 ", "󰨝 ", "󰨝 ", "󰨝 " },
			-- icons = { "󰕮 ", "󰕮 ", "󰕮 ", "󰕮 ", "󰕮 ", "󰕮 " },
			-- icons = { "I ", "II ", "III ", "IV ", "V ", "VI ", "VII " },
			-- Use single line borders to match your theme
			backgrounds = {
				"RenderMarkdownH1",
				"RenderMarkdownH2",
				"RenderMarkdownH3",
				"RenderMarkdownH4",
				"RenderMarkdownH5",
				"RenderMarkdownH6",
			},
		},

		-- Code block styling
		code = {
			enabled = true,
			sign = false, -- Disable sign column (removes white line)
			style = "normal", -- Changed from "full" to "normal" (less visual elements)
			position = "left",
			language_pad = 0,
			border = "none", -- No border
			left_pad = 0,
			right_pad = 0,
			width = "full",
			min_width = 0,
			language_name = false, -- Disable language name display
		},

		-- Checkbox rendering for task lists
		checkbox = {
			enabled = true,
			unchecked = { icon = "󰄱 " },
			checked = { icon = "󰄵 " },
		},

		-- Bullet points
		bullet = {
			enabled = true,
			-- icons = { "●", "○", "◆", "◇" },
			icons = { "󰌕", "󰌖", "◆", "◇" },
		},

		-- Links
		link = {
			enabled = true,
			-- Wikilink support for Obsidian
			wiki = {
				icon = " ",
				highlight = "RenderMarkdownLink",
			},
		},

		-- Tables
		table = {
			enabled = true,
			style = "full",
			border = "single", -- Single line borders
		},

		-- Horizontal rules
		dash = {
			enabled = true,
			icon = "─",
			width = "full",
		},

		-- Quote blocks
		quote = {
			enabled = true,
			icon = "▎",
		},
	},

	config = function(_, opts)
		require("render-markdown").setup(opts)

		-- Override callout/quote body text color to match Normal text
		local normal_fg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).fg
		if normal_fg then
			vim.api.nvim_set_hl(0, "RenderMarkdownQuote", { fg = normal_fg })
			vim.api.nvim_set_hl(0, "@markup.quote", { fg = normal_fg })
		end

		-- Keybindings
		vim.keymap.set("n", "<leader>mr", ":RenderMarkdown toggle<CR>", {
			desc = "Toggle Markdown Rendering",
			silent = true,
		})

		vim.keymap.set("n", "<leader>me", ":RenderMarkdown expand<CR>", {
			desc = "Expand Markdown Heading",
			silent = true,
		})
	end,
}
