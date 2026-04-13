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
			-- icons = { "󰲠 ", "󰲢 ", "󰲤 ", "󰲦 ", "󰲪 " },
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
			style = "language",
			position = "left",
			language_pad = 0,
			border = "none",
			-- left_pad = 0.2,
			-- left_margin = 1.5,
			-- right_pad = 0.2,
			width = "full",
			min_width = 0,
			language_name = false,
			language_icon = true,
			above = "",
			below = "",
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
			-- icons: ● ○ 󰸶 󱤙 ◇ 󰌕 󰌖 󰫥 󱤙 󰤲
			icons = { "󰤲", "󱤙", "󰸶", "󰫥" },
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

		-- LaTeX support (integrated with nabla.nvim)
		latex = {
			enabled = true,
			render_modes = false,
			converter = { "pandoc" }, -- Usando pandoc para mayor robustez
			highlight = "RenderMarkdownMath",
			position = "center",
			top_pad = 0,
			bottom_pad = 0,
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
			important = {
				raw = "[!important]",
				rendered = "󰀪 Important",
				highlight = "RenderMarkdownCalloutImportant",
			},
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

		-- Enable treesitter folds for markdown (foldenable=false so it starts expanded)
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "markdown" },
			callback = function()
				vim.opt_local.foldmethod = "expr"
				vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
				vim.opt_local.foldenable = false
				vim.opt_local.foldlevel = 99
			end,
		})

		-- Keybindings (leader+m = Markdown)
		local md_opts = { silent = true }

		-- Render control
		vim.keymap.set(
			"n",
			"<leader>mr",
			":RenderMarkdown toggle<CR>",
			vim.tbl_extend("force", md_opts, { desc = "󰍔 Toggle rendering" })
		)

		-- Toggle fold on current heading
		vim.keymap.set("n", "<leader>mf", function()
			local ok, _ = pcall(vim.cmd, "normal! za")
			if not ok then
				vim.notify("No fold found under cursor", vim.log.levels.WARN)
			end
		end, vim.tbl_extend("force", md_opts, { desc = "󰍔 Toggle fold (current heading)" }))

		-- Heading fold/unfold
		vim.keymap.set(
			"n",
			"<leader>me",
			":RenderMarkdown expand<CR>",
			vim.tbl_extend("force", md_opts, { desc = "󰍔 Expand all headings" })
		)
		vim.keymap.set("n", "<leader>mc", function()
			vim.opt_local.foldenable = true
			vim.opt_local.foldlevel = 0
			vim.notify("Headings collapsed", vim.log.levels.INFO)
		end, vim.tbl_extend("force", md_opts, { desc = "󰍔 Collapse all headings" }))

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
		end, vim.tbl_extend("force", md_opts, { desc = "󰍔 Cycle heading level" }))

		-- Toggle checkbox
		vim.keymap.set(
			"n",
			"<leader>mx",
			":RenderMarkdown toggle_checkbox<CR>",
			vim.tbl_extend("force", md_opts, { desc = "󰄵 Toggle checkbox" })
		)

		-- Open link (External/General)
		vim.keymap.set("n", "<leader>ml", function()
			vim.cmd("normal! gx")
		end, vim.tbl_extend("force", md_opts, { desc = "󰌹 Open link (External)" }))

		-- Mermaid preview (External)
		-- vim.keymap.set("n", "<leader>mp", function()
		-- 	local node = vim.treesitter.get_node()
		-- 	if not node then return end
		--
		-- 	-- Find the code block node
		-- 	while node and node:type() ~= "fenced_code_block" do
		-- 		node = node:parent()
		-- 	end
		--
		-- 	if not node then
		-- 		vim.notify("No code block found under cursor", vim.log.levels.WARN)
		-- 		return
		-- 	end
		--
		-- 	-- Get content and language
		-- 	local content = vim.treesitter.get_node_text(node, 0)
		-- 	local lang = content:match("^```(%w+)")
		--
		-- 	if lang ~= "mermaid" then
		-- 		vim.notify("Not a mermaid block", vim.log.levels.WARN)
		-- 		return
		-- 	end
		--
		-- 	-- Extract mermaid code (remove backticks and lang)
		-- 	local code = content:gsub("^```mermaid\n", ""):gsub("\n```$", "")
		-- 	local tmp_mmd = os.tmpname() .. ".mmd"
		-- 	local tmp_png = os.tmpname() .. ".png"
		--
		-- 	-- Write to temp file
		-- 	local f = io.open(tmp_mmd, "w")
		-- 	if f then
		-- 		f:write(code)
		-- 		f:close()
		--
		-- 		-- Run mmdc and open with xdg-open (default image viewer)
		-- 		vim.notify("Generating mermaid diagram...", vim.log.levels.INFO)
		-- 		vim.fn.jobstart({ "mmdc", "-i", tmp_mmd, "-o", tmp_png }, {
		-- 			on_exit = function(_, code_exit)
		-- 				if code_exit == 0 then
		-- 					vim.fn.jobstart({ "xdg-open", tmp_png })
		-- 					-- Clean up mmd file, png will be open
		-- 					os.remove(tmp_mmd)
		-- 				else
		-- 					vim.notify("mmdc failed. Is mermaid-cli installed?", vim.log.levels.ERROR)
		-- 				end
		-- 			end,
		-- 		})
		-- 	end
		-- end, vim.tbl_extend("force", md_opts, { desc = "Markdown: Preview Mermaid (External)" }))

		-- LaTeX preview (External Hibrid PoC) removed
	end,
}
