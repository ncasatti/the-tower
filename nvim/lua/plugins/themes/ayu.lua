-- https://htmlcolorcodes.com/color-picker/
-- https://raw.githubusercontent.com/ayu-theme/ayu-colors/e3f44fdf2a1c83e3f183d4e8acd40c6a452dcb1c/palette.svg
Colors = {
	blue1 = "#39BAE6",
	blue2 = "#1CB1E3",
	blue3 = "#1791BA",
	pink1 = "#FB2372",
	pink2 = "#CD044E",
	pink3 = "#A0033D",
	pink4 = "#A3335D",
	pink5 = "#e65064",
	yellow1 = "#FFB454", -- Naranja suave (Ayu-like)
	yellow2 = "#C1AD10",
	orange = "#FF8F40",
	orange2 = "#FFB454",
	orange3 = "#DBA55E", -- C79454
	white1 = "#FFFFFF",
	fg_default = "#BFBDB6", -- common/body text ayu's default
	-- fg_bright = "#D9D7D0", -- brighter than ayu's default
	white2 = "#828282",
	white3 = "#666666",
	white4 = "#262626", --525252
	black = "#000000",
	green = "#91BA18", -- 86B300
	green2 = "#AAD94C",
	green3 = "#70BF56",
	cyan_gray = "#33596B",
	cyan_gray2 = "#7D9CA8",
	cyan_gray3 = "#346982",
	cyan_gray4 = "#619CC7", --598FB5
	cyan_gray5 = "#2F4E5C",
	gray = "#4F6166",
	gray2 = "#2F3E45",
	gray3 = "#4E626B",
	gray4 = "#768A94",
	cyan = "#00FFFF",
	blue_note = "#39BAE6",
	red = "#D26464",
	blue_dark = "#334454", -- 253340
	blue_dark2 = "#2b3b4d",
	blue_dark3 = "#1C2733", -- darker selection box → more contrast for white text
	-- Inline markup (opaque, so headings dominate the page)
	code_muted = "#73A0AE", -- inline `code` / code blocks (was blue1 #39BAE6)
	code_blue = "#59C2FF", --2888A8 209EC7
	bold_orange = "#E68C50", -- FF8F40 E0803A
	-- Markdown heading colors — distinct hues (inline now muted, so collisions are minor)
	-- prior alts kept for quick revert:
	--   mono-violet:  E0B3FF C892F2 B279DE 9C66C7 875AAD 714C90
	--   ember:        FF6D7E FF8A5C FFB454 FFD580 E8CB8E C9B88A
	--   vivid-teal:   63C1CE 51ABBA 4396A6 388193 2F6D80 29596D
	h1 = "#e65064", -- ayu red (kept)
	h2 = "#59C2FF", -- blue
	h3 = "#7FD962", -- green
	h4 = "#C385FE", -- violet
	h5 = "#FFB454", -- amber
	h6 = "#6FD0C0", -- teal-mint
}
Elements = {
	bold = Colors.bold_orange,
	code = Colors.code_blue,
	italic = Colors.gray4,
	cursor = Colors.white1,
	selection = Colors.blue_dark3, -- darker box → white selection text pops more
	matched = Colors.red,
	comments = Colors.gray,
}
-- Ayu theme configuration for Neovim
return {
	"Shatur/neovim-ayu",
	priority = 1000,
	config = function()
		local darkvenom = {
			-- Background transparent + brighter body text (less gray)
			Normal = { fg = Colors.fg_bright, bg = "None" },
			ColorColumn = { bg = "None" },
			SignColumn = { bg = "None" },
			Folded = { bg = "None" },
			FoldColumn = { bg = "None" },
			CursorLine = { bg = "None" },
			CursorColumn = { bg = "None" },
			WhichKeyFloat = { bg = "None" },
			VertSplit = { bg = "None" },

			-- Floating windows transparency (for Snacks.picker, which-key, etc.)
			NormalFloat = { bg = "None" },
			FloatBorder = { bg = "None" },
			FloatTitle = { bg = "None" },

			-- Popup menu transparency
			Pmenu = { bg = "None" },
			PmenuSel = { bg = "#253340" }, -- Slightly visible selection
			PmenuSbar = { bg = "None" },
			PmenuThumb = { bg = "#39BAE6" },

			-- Which-key transparency
			WhichKey = { bg = "None" },
			WhichKeyGroup = { bg = "None" },
			WhichKeyDesc = { bg = "None" },
			WhichKeySeparator = { bg = "None" },
			WhichKeyValue = { bg = "None" },
			WhichKeyNormal = { bg = "None" },
			WhichKeyBorder = { bg = "None" },

			-- Snacks specific
			SnacksNormal = { bg = "None" },
			SnacksBorder = { bg = "None" },

			-- Search highlights
			Search = { fg = Colors.yellow1, bg = "None", bold = true, underline = true },
			IncSearch = { fg = Colors.orange, bg = "None", bold = true, underline = true },
			CurSearch = { fg = Colors.orange, bg = "None", bold = true, underline = true },

			--- Cursor and selection
			-- Cursor
			Cursor = { fg = Colors.black, bg = Elements.cursor },
			-- Visual selection
			Visual = { fg = Colors.white1, bg = Elements.selection, bold = true },
			VisualNOS = { fg = Colors.white1, bg = Elements.selection, bold = true },
			-- Snacks picker selected row: decoupled from Visual (Snacks links it to
			-- Visual by default in core/list.lua). NO fg so colored task icons
			-- keep their status/priority color when the row is selected.
			SnacksPickerListCursorLine = { bg = Elements.selection },
			-- Matched parens
			MatchParen = { fg = Elements.matched, bold = true, underline = true },

			-- Snacks picker colors
			SnacksPickerDir = { fg = "#BFBDB6" }, -- White/light gray for path
			SnacksPickerFile = { fg = "#39BAE6" }, -- Subtle cyan for filename
			Directory = { fg = "#BFBDB6" }, -- Fallback for directories

			-- Darkvenom custom colors (from Best Themes - Ayu Darkvenom)

			-- Strings (OK)
			String = { fg = "#AAD94C" }, -- Green strings
			["@string"] = { fg = "#AAD94C" },

			-- Comments (OK)
			Comment = { fg = Elements.comments, italic = true }, -- Gray comments with italic - 575c61
			["@comment"] = { fg = Elements.comments, italic = true },

			-- Keywords (OK)
			Keyword = { fg = Colors.pink2 }, -- Pink keywords  #e30e75
			["@keyword"] = { fg = Colors.pink2 },
			["@keyword.control"] = { fg = Colors.pink2 },

			-- Functions (OK)
			Function = { fg = "#ff8f40" }, -- Orange functions
			["@function"] = { fg = "#ff8f40" },
			["@function.call"] = { fg = "#ff8f40" },

			-- Types (OK)
			-- Blue
			Type = { fg = Colors.blue3 }, -- Blue types
			["@type"] = { fg = Colors.blue3 },
			["@type.builtin"] = { fg = Colors.blue3 },

			-- Variables (OK)
			Identifier = { fg = Colors.fg_bright }, -- common text (was #BFBDB6)
			["@variable"] = { fg = Colors.fg_bright },
			["@variable.member"] = { fg = Colors.fg_bright },
			["@variable.builtin"] = { fg = Colors.fg_bright, italic = true },

			-- Numbers (OK)
			Number = { fg = "#D2A6FF" }, -- Purple numbers
			["@number"] = { fg = "#D2A6FF" },
			["@constant"] = { fg = "#D2A6FF" },
			["@constant.builtin"] = { fg = "#D2A6FF" },

			-- Operators (OK)
			Operator = { fg = "#ff8f40" }, -- Orange operators
			["@operator"] = { fg = "#ff8f40" },

			-- Special elements brackets (OK)
			["@punctuation.separator"] = { fg = Colors.yellow2 }, -- Yellow brackets
			["@punctuation.bracket"] = { fg = Colors.yellow2 },

			["@tag"] = { fg = "#39BAE6" }, -- Cyan for HTML/JSX tags
			["@tag.attribute"] = { fg = Colors.yellow2 }, -- Yellow for attributes

			["@constructor"] = { fg = "#59C2FF" }, -- Blue for constructors
			["@parameter"] = { fg = "#D2A6FF" }, -- Purple for parameters

			-- Special types
			StorageClass = { fg = "#FF8F40" }, -- Orange for storage (const, let, var)
			["@storageclass"] = { fg = "#FF8F40" },

			-- Additional semantic highlighting
			["@namespace"] = { fg = "#AAD94C" }, -- Green for imports/packages
			["@property"] = { fg = "#39BAE6" }, -- Cyan for properties

			-- Markdown bold - bright white for emphasis
			["@markup.strong"] = { fg = Elements.bold, bold = true },
			markdownBold = { fg = Elements.bold, bold = true },

			-- Markdown italic
			["@markup.italic"] = { fg = Elements.italic, italic = true },
			markdownItalic = { fg = Elements.italic, italic = true },

			-- Markdown heading colors for render-markdown
			RenderMarkdownH1 = { fg = Colors.h1 },
			RenderMarkdownH1Bg = { bg = "#10141C" },
			RenderMarkdownH2 = { fg = Colors.h2 },
			RenderMarkdownH2Bg = { bg = "None" },
			RenderMarkdownH3 = { fg = Colors.h3 },
			RenderMarkdownH3Bg = { bg = "None" },
			RenderMarkdownH4 = { fg = Colors.h4 },
			RenderMarkdownH4Bg = { bg = "None" },
			RenderMarkdownH5 = { fg = Colors.h5 },
			RenderMarkdownH5Bg = { bg = "None" },
			RenderMarkdownH6 = { fg = Colors.h6 },
			RenderMarkdownH6Bg = { bg = "None" },
			RenderMarkdownIndentActive = { fg = Colors.gray },

			-- Markdown Math and Code blocks
			RenderMarkdownMath = { fg = Elements.code },
			RenderMarkdownCode = { fg = Elements.code },
			["@markup.math"] = { fg = Elements.code },
			["@markup.raw"] = { fg = Elements.code },
			["@markup.raw.block"] = { fg = Elements.code },
			["@markup.raw.inline"] = { fg = Elements.code },
			["@function.macro.latex"] = { fg = Elements.code },
			["@function.latex"] = { fg = Elements.code },
			["@punctuation.special.latex"] = { fg = Elements.code },
			["@variable.parameter.latex"] = { fg = Elements.code },

			-- Callout custom colors for render-markdown
			RenderMarkdownInfo = { fg = Colors.blue_note }, -- Note (blue)
			RenderMarkdownHint = { fg = "#7FD962" }, -- Tip (green mint)
			RenderMarkdownWarn = { fg = "#F07178" }, -- Warning (dark red)
			RenderMarkdownError = { fg = "#F07178" }, -- Error (red)
			RenderMarkdownSuccess = { fg = "#4CAF50" }, -- Success (emerald)
			RenderMarkdownQuote = { fg = "#ACB6BF" }, -- Quote (gray)

			-- Custom per-callout highlights for maximum color variety
			RenderMarkdownCalloutInfo = { fg = "#59C2FF" }, -- Info (cyan)
			RenderMarkdownCalloutAbstract = { fg = "#00BCD4" }, -- Abstract (teal)
			RenderMarkdownCalloutTodo = { fg = "#AAD94C" }, -- Todo (lime green)
			RenderMarkdownCalloutFaq = { fg = Colors.yellow1 }, -- FAQ (orange-yellow)
			RenderMarkdownCalloutBug = { fg = "#FF5370" }, -- Bug (hot pink)
			RenderMarkdownCalloutFail = { fg = "#D95757" }, -- Fail (dark red)
			RenderMarkdownCalloutExample = { fg = "#D2A6FF" }, -- Example (purple)
			RenderMarkdownCalloutImportant = { fg = "#95E6CB" }, -- Important (mint)
		}

		require("ayu").setup({
			mirage = false,
			terminal = true,
			overrides = darkvenom,
		})

		-- Set the colorscheme to ayu-dark
		vim.cmd.colorscheme("ayu-dark")

		-- Cursor shape and color (guicursor)
		-- n-v-c: normal, visual, command (block cursor)
		-- i-ci-ve: insert, command-line insert, visual-exclude (vertical bar)
		-- r-cr-o: replace, command-line replace, operator-pending (horizontal bar)
		-- All modes use the 'Cursor' highlight group
		vim.opt.guicursor = "n-v-c:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor"

		-- Force transparent backgrounds for floating windows after colorscheme loads
		vim.api.nvim_create_autocmd("ColorScheme", {
			pattern = "*",
			callback = function()
				vim.api.nvim_set_hl(0, "NormalFloat", { bg = "None" })
				vim.api.nvim_set_hl(0, "FloatBorder", { bg = "None" })
				vim.api.nvim_set_hl(0, "Pmenu", { bg = "None" })
			end,
		})

		-- Apply immediately
		vim.api.nvim_set_hl(0, "NormalFloat", { bg = "None" })
		vim.api.nvim_set_hl(0, "FloatBorder", { bg = "None" })
		vim.api.nvim_set_hl(0, "Pmenu", { bg = "None" })
		vim.api.nvim_set_hl(0, "SnacksPickerDir", { fg = "#BFBDB6" })
		vim.api.nvim_set_hl(0, "SnacksPickerFile", { fg = "#39BAE6" })
		vim.api.nvim_set_hl(0, "Directory", { fg = "#BFBDB6" })

		-- Search highlights
		vim.api.nvim_set_hl(0, "Search", { fg = Colors.yellow1, bg = "None", bold = true, underline = true })
		vim.api.nvim_set_hl(0, "IncSearch", { fg = Colors.orange, bg = "None", bold = true, underline = true })
		vim.api.nvim_set_hl(0, "CurSearch", { fg = Colors.orange, bg = "None", bold = true, underline = true })

		-- Cursor and selection colors
		vim.api.nvim_set_hl(0, "Cursor", { fg = Colors.black, bg = Elements.cursor })
		vim.api.nvim_set_hl(0, "Visual", { fg = Colors.white1, bg = Elements.selection, bold = true })
		vim.api.nvim_set_hl(0, "VisualNOS", { fg = Colors.white1, bg = Elements.selection, bold = true })
		vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { bg = Elements.selection })
		vim.api.nvim_set_hl(0, "MatchParen", { fg = Elements.matched, bold = true, underline = true })

		-- Markdown bold - bright white
		vim.api.nvim_set_hl(0, "@markup.strong", { fg = Elements.bold, bold = true })
		vim.api.nvim_set_hl(0, "markdownBold", { fg = Elements.bold, bold = true })

		-- Markdown italic
		vim.api.nvim_set_hl(0, "@markup.italic", { fg = Elements.italic, italic = true })
		vim.api.nvim_set_hl(0, "markdownItalic", { fg = Elements.italic, italic = true })

		-- Markdown heading colors
		vim.api.nvim_set_hl(0, "RenderMarkdownH1", { fg = Colors.h1 })
		vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = "None" })
		vim.api.nvim_set_hl(0, "RenderMarkdownH2", { fg = Colors.h2 })
		vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { bg = "None" })
		vim.api.nvim_set_hl(0, "RenderMarkdownH3", { fg = Colors.h3 })
		vim.api.nvim_set_hl(0, "RenderMarkdownH3Bg", { bg = "None" })
		vim.api.nvim_set_hl(0, "RenderMarkdownH4", { fg = Colors.h4 })
		vim.api.nvim_set_hl(0, "RenderMarkdownH4Bg", { bg = "None" })
		vim.api.nvim_set_hl(0, "RenderMarkdownH5", { fg = Colors.h5 })
		vim.api.nvim_set_hl(0, "RenderMarkdownH5Bg", { bg = "None" })
		vim.api.nvim_set_hl(0, "RenderMarkdownH6", { fg = Colors.h6 })
		vim.api.nvim_set_hl(0, "RenderMarkdownH6Bg", { bg = "None" })

		-- Markdown Math and Code blocks
		vim.api.nvim_set_hl(0, "RenderMarkdownMath", { fg = Elements.code })
		vim.api.nvim_set_hl(0, "RenderMarkdownCode", { fg = Elements.code })
		vim.api.nvim_set_hl(0, "@markup.math", { fg = Elements.code })
		vim.api.nvim_set_hl(0, "@markup.raw", { fg = Elements.code })
		vim.api.nvim_set_hl(0, "@markup.raw.block", { fg = Elements.code })
		vim.api.nvim_set_hl(0, "@markup.raw.inline", { fg = Elements.code })
		vim.api.nvim_set_hl(0, "@function.macro.latex", { fg = Elements.code })
		vim.api.nvim_set_hl(0, "@function.latex", { fg = Elements.code })
		vim.api.nvim_set_hl(0, "@punctuation.special.latex", { fg = Elements.code })
		vim.api.nvim_set_hl(0, "@variable.parameter.latex", { fg = Elements.code })

		-- snacks.image LaTeX math → white. Overrides snacks' default group
		-- (linked to @markup.math.latex/Special = ayu gold). This fg is baked
		-- into the generated .tex (\color), so changing it recompiles the image.
		vim.api.nvim_set_hl(0, "SnacksImageMath", { fg = Colors.white1 })

		-- Callout colors
		vim.api.nvim_set_hl(0, "RenderMarkdownInfo", { fg = Colors.blue_note })
		vim.api.nvim_set_hl(0, "RenderMarkdownHint", { fg = "#7FD962" })
		vim.api.nvim_set_hl(0, "RenderMarkdownWarn", { fg = "#F07178" }) -- Dark red
		vim.api.nvim_set_hl(0, "RenderMarkdownError", { fg = "#F07178" })
		vim.api.nvim_set_hl(0, "RenderMarkdownSuccess", { fg = "#4CAF50" })
		vim.api.nvim_set_hl(0, "RenderMarkdownQuote", { fg = "#ACB6BF" })

		-- Custom per-callout highlights for maximum color variety
		vim.api.nvim_set_hl(0, "RenderMarkdownCalloutInfo", { fg = "#59C2FF" })
		vim.api.nvim_set_hl(0, "RenderMarkdownCalloutAbstract", { fg = "#00BCD4" })
		vim.api.nvim_set_hl(0, "RenderMarkdownCalloutTodo", { fg = "#AAD94C" })
		vim.api.nvim_set_hl(0, "RenderMarkdownCalloutFaq", { fg = Colors.yellow1 }) -- Orange-yellow
		vim.api.nvim_set_hl(0, "RenderMarkdownCalloutBug", { fg = "#FF5370" })
		vim.api.nvim_set_hl(0, "RenderMarkdownCalloutFail", { fg = "#D95757" })
		vim.api.nvim_set_hl(0, "RenderMarkdownCalloutExample", { fg = "#D2A6FF" })
		vim.api.nvim_set_hl(0, "RenderMarkdownCalloutImportant", { fg = "#95E6CB" })
	end,
}
