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
			sign = false,
			style = "normal",
			position = "left",
			language_pad = 0,
			border = "none",
			left_pad = 0,
			right_pad = 0,
			width = "full",
			min_width = 0,
			language_name = false,
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

		-- Custom callout definitions with unique colors
		callout = {
			note = { raw = "[!note]", rendered = "󰏫 Note", highlight = "RenderMarkdownInfo" },
			info = { raw = "[!info]", rendered = "󰋽 Info", highlight = "RenderMarkdownCalloutInfo" },
			tip = { raw = "[!tip]", rendered = "󰌶 Tip", highlight = "RenderMarkdownHint" },
			important = { raw = "[!important]", rendered = "󰀪 Important", highlight = "RenderMarkdownCalloutImportant" },
			abstract = { raw = "[!abstract]", rendered = "󰨝 Abstract", highlight = "RenderMarkdownCalloutAbstract" },
			summary = { raw = "[!summary]", rendered = "󰨝 Summary", highlight = "RenderMarkdownCalloutAbstract" },
			tldr = { raw = "[!tldr]", rendered = "󰨝 TL;DR", highlight = "RenderMarkdownCalloutAbstract" },
			todo = { raw = "[!todo]", rendered = " Todo", highlight = "RenderMarkdownCalloutTodo" },
			success = { raw = "[!success]", rendered = "󰄬 Success", highlight = "RenderMarkdownSuccess" },
			check = { raw = "[!check]", rendered = "󰄬 Check", highlight = "RenderMarkdownSuccess" },
			done = { raw = "[!done]", rendered = "󰄬 Done", highlight = "RenderMarkdownSuccess" },
			warning = { raw = "[!warning]", rendered = "󰀦 Warning", highlight = "RenderMarkdownWarn" },
			caution = { raw = "[!caution]", rendered = "󰀦 Caution", highlight = "RenderMarkdownWarn" },
			attention = { raw = "[!attention]", rendered = "󰀦 Attention", highlight = "RenderMarkdownWarn" },
			faq = { raw = "[!faq]", rendered = "󰘥 FAQ", highlight = "RenderMarkdownCalloutFaq" },
			question = { raw = "[!question]", rendered = "󰘥 Question", highlight = "RenderMarkdownCalloutFaq" },
			help = { raw = "[!help]", rendered = "󰘥 Help", highlight = "RenderMarkdownCalloutFaq" },
			error = { raw = "[!error]", rendered = "󰅚 Error", highlight = "RenderMarkdownError" },
			danger = { raw = "[!danger]", rendered = "󱐌 Danger", highlight = "RenderMarkdownError" },
			bug = { raw = "[!bug]", rendered = "󰨰 Bug", highlight = "RenderMarkdownCalloutBug" },
			fail = { raw = "[!fail]", rendered = "󰅖 Fail", highlight = "RenderMarkdownCalloutFail" },
			failure = { raw = "[!failure]", rendered = "󰅖 Failure", highlight = "RenderMarkdownCalloutFail" },
			missing = { raw = "[!missing]", rendered = "󰅖 Missing", highlight = "RenderMarkdownCalloutFail" },
			example = { raw = "[!example]", rendered = "󰉹 Example", highlight = "RenderMarkdownCalloutExample" },
			quote = { raw = "[!quote]", rendered = "󱀡 Quote", highlight = "RenderMarkdownQuote" },
			cite = { raw = "[!cite]", rendered = "󱀡 Cite", highlight = "RenderMarkdownQuote" },
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

		-- Keybindings (leader+m = Markdown)
		local md_opts = { silent = true }

		-- Render control
		vim.keymap.set("n", "<leader>mr", ":RenderMarkdown toggle<CR>",
			vim.tbl_extend("force", md_opts, { desc = "Markdown: Toggle rendering" }))

		-- Heading fold/unfold
		vim.keymap.set("n", "<leader>me", ":RenderMarkdown expand<CR>",
			vim.tbl_extend("force", md_opts, { desc = "Markdown: Expand all headings" }))
		vim.keymap.set("n", "<leader>mc", function()
			-- Collapse all headings by setting foldlevel to 0
			vim.opt_local.foldmethod = "expr"
			vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
			vim.opt_local.foldenable = true
			vim.opt_local.foldlevel = 0
			vim.notify("Headings collapsed", vim.log.levels.INFO)
		end, vim.tbl_extend("force", md_opts, { desc = "Markdown: Collapse all headings" }))

		-- Heading level cycle
		vim.keymap.set("n", "<leader>mh", function()
			local line = vim.api.nvim_get_current_line()
			if line:match("^######") then
				vim.api.nvim_set_current_line(line:gsub("^######%s*", "# "))
			elseif line:match("^#") then
				vim.api.nvim_set_current_line("#" .. line)
			else
				vim.api.nvim_set_current_line("# " .. line)
			end
		end, vim.tbl_extend("force", md_opts, { desc = "Markdown: Cycle heading level" }))

		-- Toggle checkbox
		vim.keymap.set("n", "<leader>mt", function()
			local line = vim.api.nvim_get_current_line()
			if line:match("%- %[x%]") then
				vim.api.nvim_set_current_line((line:gsub("%- %[x%]", "- [ ]")))
			elseif line:match("%- %[ %]") then
				vim.api.nvim_set_current_line((line:gsub("%- %[ %]", "- [x]")))
			else
				-- Add unchecked checkbox at start of list item or line
				if line:match("^%s*%-") then
					vim.api.nvim_set_current_line((line:gsub("^(%s*%-)%s*", "%1 [ ] ")))
				else
					local indent = line:match("^(%s*)")
					vim.api.nvim_set_current_line(indent .. "- [ ] " .. line:gsub("^%s*", ""))
				end
			end
		end, vim.tbl_extend("force", md_opts, { desc = "Markdown: Toggle checkbox" }))

		-- Bold wrap (visual mode)
		vim.keymap.set("v", "<leader>mb", function()
			-- Get visual selection, wrap with **
			vim.cmd('normal! "zc**' .. vim.fn.getreg("z") .. "**")
		end, vim.tbl_extend("force", md_opts, { desc = "Markdown: Bold selection" }))

		-- Italic wrap (visual mode)
		vim.keymap.set("v", "<leader>mi", function()
			vim.cmd('normal! "zc*' .. vim.fn.getreg("z") .. "*")
		end, vim.tbl_extend("force", md_opts, { desc = "Markdown: Italic selection" }))

		-- Insert link (visual = wrap selection as link text, normal = template)
		vim.keymap.set("n", "<leader>ml", function()
			vim.api.nvim_put({ "[](url)" }, "c", true, true)
			-- Place cursor inside []
			vim.cmd("normal! F[la")
		end, vim.tbl_extend("force", md_opts, { desc = "Markdown: Insert link" }))
		vim.keymap.set("v", "<leader>ml", function()
			vim.cmd('normal! "zc[' .. vim.fn.getreg("z") .. "](url)")
			vim.cmd("normal! F)i")
		end, vim.tbl_extend("force", md_opts, { desc = "Markdown: Link selection" }))

		-- Insert code block
		vim.keymap.set("n", "<leader>mk", function()
			local row = vim.api.nvim_win_get_cursor(0)[1]
			vim.api.nvim_buf_set_lines(0, row, row, false, { "```", "", "```" })
			vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
			vim.cmd("startinsert")
		end, vim.tbl_extend("force", md_opts, { desc = "Markdown: Insert code block" }))

		-- Preview in browser (uses glow or markdown-preview if available)
		vim.keymap.set("n", "<leader>mp", function()
			local file = vim.fn.expand("%:p")
			vim.fn.jobstart({ "xdg-open", file }, { detach = true })
		end, vim.tbl_extend("force", md_opts, { desc = "Markdown: Preview in browser" }))
	end,
}
