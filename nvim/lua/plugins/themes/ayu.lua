-- https://htmlcolorcodes.com/color-picker/
Colors = {
  blue1 = "#39BAE6",
  blue2 = "#1CB1E3",
  blue3 = "#1791BA",
  pink1 = "#FB2372",
  pink2 = "#CD044E",
  pink3 = "#A0033D",
  yellow1 = "#edd522",
  yellow2 = "#C1AD10",
  white1 = "#FFFFFF",
}
-- Ayu theme configuration for Neovim
return {
  "Shatur/neovim-ayu",
  priority = 1000,
  config = function()
    local darkvenom = {
      -- Background transparent
      Normal = { bg = "None" },
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
      PmenuSel = { bg = "#253340" },  -- Slightly visible selection
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

      -- Snacks picker colors
      SnacksPickerDir = { fg = "#BFBDB6" },  -- White/light gray for path
      SnacksPickerFile = { fg = "#39BAE6" },  -- Subtle cyan for filename
      Directory = { fg = "#BFBDB6" },  -- Fallback for directories

      -- Darkvenom custom colors (from Best Themes - Ayu Darkvenom)

      -- Strings (OK)
      String = { fg = "#AAD94C" },  -- Green strings
      ["@string"] = { fg = "#AAD94C" },

      -- Comments (OK)
      Comment = { fg = "#575c61", italic = true },  -- Gray comments with italic
      ["@comment"] = { fg = "#575c61", italic = true },

      -- Keywords (OK)
      Keyword = { fg = Colors.pink2 },  -- Pink keywords  #e30e75
      ["@keyword"] = { fg = Colors.pink2 },
      ["@keyword.control"] = { fg = Colors.pink2 },

      -- Functions (OK)
      Function = { fg = "#ff8f40" },  -- Orange functions
      ["@function"] = { fg = "#ff8f40" },
      ["@function.call"] = { fg = "#ff8f40" },

      -- Types (OK)
      -- Blue
      Type = { fg = Colors.blue3 },  -- Blue types
      ["@type"] = { fg = Colors.blue3 },
      ["@type.builtin"] = { fg = Colors.blue3 },

      -- Variables (OK)
      Identifier = { fg = "#BFBDB6" },  -- Light gray variables
      ["@variable"] = { fg = "#BFBDB6" },
      ["@variable.member"] = { fg = "#BFBDB6" },
      ["@variable.builtin"] = { fg = "#BFBDB6", italic = true },

      -- Numbers (OK)
      Number = { fg = "#D2A6FF" },  -- Purple numbers
      ["@number"] = { fg = "#D2A6FF" },
      ["@constant"] = { fg = "#D2A6FF" },
      ["@constant.builtin"] = { fg = "#D2A6FF" },

      -- Operators (OK)
      Operator = { fg = "#ff8f40" },  -- Orange operators
      ["@operator"] = { fg = "#ff8f40" },

       -- Special elements brackets (OK)
       ["@punctuation.separator"] = { fg = Colors.white1 }, -- Neutral brackets
       ["@punctuation.bracket"] = { fg = Colors.white1 },

       ["@tag"] = { fg = "#39BAE6" },  -- Cyan for HTML/JSX tags
       ["@tag.attribute"] = { fg = Colors.white1 },  -- Neutral for attributes


      ["@constructor"] = { fg = "#59C2FF" },  -- Blue for constructors
      ["@parameter"] = { fg = "#D2A6FF" },  -- Purple for parameters

      -- Special types
      StorageClass = { fg = "#FF8F40" },  -- Orange for storage (const, let, var)
      ["@storageclass"] = { fg = "#FF8F40" },

      -- Additional semantic highlighting
       ["@namespace"] = { fg = "#AAD94C" },  -- Green for imports/packages
       ["@property"] = { fg = "#39BAE6" },  -- Cyan for properties

        -- Markdown bold - bright white for emphasis
       ["@markup.strong"] = { fg = "#FFFFFF", bold = true },
       markdownBold = { fg = "#FFFFFF", bold = true },

       -- Markdown heading colors for render-markdown
       RenderMarkdownH1 = { fg = "#F07178" },           -- Red (keep default feel)
       RenderMarkdownH1Bg = { bg = "None" },
       RenderMarkdownH2 = { fg = "#39BAE6" },           -- Blue (differentiated from H1)
       RenderMarkdownH2Bg = { bg = "None" },
       RenderMarkdownH3 = { fg = "#AAD94C" },           -- Green
       RenderMarkdownH3Bg = { bg = "None" },
       RenderMarkdownH4 = { fg = Colors.white1 },           -- Changed from yellow to neutral
       RenderMarkdownH4Bg = { bg = "None" },
       RenderMarkdownH5 = { fg = "#D2A6FF" },           -- Purple
       RenderMarkdownH5Bg = { bg = "None" },
       RenderMarkdownH6 = { fg = "#95E6CB" },           -- Mint
       RenderMarkdownH6Bg = { bg = "None" },

       -- Markdown Math and Code blocks
       RenderMarkdownMath = { fg = Colors.white1 },
       RenderMarkdownCode = { fg = Colors.white1 },
       ["@markup.math"] = { fg = Colors.white1 },
       ["@markup.raw"] = { fg = Colors.white1 },
       ["@markup.raw.block"] = { fg = Colors.white1 },
       ["@markup.raw.inline"] = { fg = Colors.white1 },
       ["@function.macro.latex"] = { fg = Colors.white1 },
       ["@function.latex"] = { fg = Colors.white1 },
       ["@punctuation.special.latex"] = { fg = Colors.white1 },
       ["@variable.parameter.latex"] = { fg = Colors.white1 },

       -- Callout custom colors for render-markdown
       RenderMarkdownInfo = { fg = "#39BAE6" },        -- Note (blue)
       RenderMarkdownHint = { fg = "#7FD962" },         -- Tip (green mint)
       RenderMarkdownWarn = { fg = Colors.white1 },         -- Changed from amber to neutral
       RenderMarkdownError = { fg = "#F07178" },        -- Error (red)
       RenderMarkdownSuccess = { fg = "#4CAF50" },      -- Success (emerald)
       RenderMarkdownQuote = { fg = "#ACB6BF" },        -- Quote (gray)

       -- Custom per-callout highlights for maximum color variety
       RenderMarkdownCalloutInfo = { fg = "#59C2FF" },       -- Info (cyan)
       RenderMarkdownCalloutAbstract = { fg = "#00BCD4" },   -- Abstract (teal)
       RenderMarkdownCalloutTodo = { fg = "#AAD94C" },       -- Todo (lime green)
       RenderMarkdownCalloutFaq = { fg = Colors.white1 },        -- Changed from yellow to neutral
       RenderMarkdownCalloutBug = { fg = "#FF5370" },        -- Bug (hot pink)
       RenderMarkdownCalloutFail = { fg = "#D95757" },       -- Fail (dark red)
       RenderMarkdownCalloutExample = { fg = "#D2A6FF" },    -- Example (purple)
       RenderMarkdownCalloutImportant = { fg = "#95E6CB" },  -- Important (mint)

     }

    require('ayu').setup({
      mirage = false,
      terminal = true,
      overrides = darkvenom,
    })

    -- Set the colorscheme to ayu-dark
    vim.cmd.colorscheme("ayu-dark")

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

     -- Markdown bold - bright white
     vim.api.nvim_set_hl(0, "@markup.strong", { fg = "#FFFFFF", bold = true })
     vim.api.nvim_set_hl(0, "markdownBold", { fg = "#FFFFFF", bold = true })

     -- Markdown heading colors
     vim.api.nvim_set_hl(0, "RenderMarkdownH1", { fg = "#F07178" })
     vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = "None" })
     vim.api.nvim_set_hl(0, "RenderMarkdownH2", { fg = "#39BAE6" })
     vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { bg = "None" })
     vim.api.nvim_set_hl(0, "RenderMarkdownH3", { fg = "#AAD94C" })
     vim.api.nvim_set_hl(0, "RenderMarkdownH3Bg", { bg = "None" })
     vim.api.nvim_set_hl(0, "RenderMarkdownH4", { fg = Colors.white1 }) -- Changed
     vim.api.nvim_set_hl(0, "RenderMarkdownH4Bg", { bg = "None" })
     vim.api.nvim_set_hl(0, "RenderMarkdownH5", { fg = "#D2A6FF" })
     vim.api.nvim_set_hl(0, "RenderMarkdownH5Bg", { bg = "None" })
     vim.api.nvim_set_hl(0, "RenderMarkdownH6", { fg = "#95E6CB" })
     vim.api.nvim_set_hl(0, "RenderMarkdownH6Bg", { bg = "None" })

     -- Markdown Math and Code blocks
     vim.api.nvim_set_hl(0, "RenderMarkdownMath", { fg = Colors.white1 })
     vim.api.nvim_set_hl(0, "RenderMarkdownCode", { fg = Colors.white1 })
     vim.api.nvim_set_hl(0, "@markup.math", { fg = Colors.white1 })
     vim.api.nvim_set_hl(0, "@markup.raw", { fg = Colors.white1 })
     vim.api.nvim_set_hl(0, "@markup.raw.block", { fg = Colors.white1 })
     vim.api.nvim_set_hl(0, "@markup.raw.inline", { fg = Colors.white1 })
     vim.api.nvim_set_hl(0, "@function.macro.latex", { fg = Colors.white1 })
     vim.api.nvim_set_hl(0, "@function.latex", { fg = Colors.white1 })
     vim.api.nvim_set_hl(0, "@punctuation.special.latex", { fg = Colors.white1 })
     vim.api.nvim_set_hl(0, "@variable.parameter.latex", { fg = Colors.white1 })

     -- Callout colors
    vim.api.nvim_set_hl(0, "RenderMarkdownInfo", { fg = "#39BAE6" })
    vim.api.nvim_set_hl(0, "RenderMarkdownHint", { fg = "#7FD962" })
    vim.api.nvim_set_hl(0, "RenderMarkdownWarn", { fg = Colors.white1 }) -- Changed
    vim.api.nvim_set_hl(0, "RenderMarkdownError", { fg = "#F07178" })
    vim.api.nvim_set_hl(0, "RenderMarkdownSuccess", { fg = "#4CAF50" })
    vim.api.nvim_set_hl(0, "RenderMarkdownQuote", { fg = "#ACB6BF" })

    -- Custom per-callout highlights for maximum color variety
    vim.api.nvim_set_hl(0, "RenderMarkdownCalloutInfo", { fg = "#59C2FF" })
    vim.api.nvim_set_hl(0, "RenderMarkdownCalloutAbstract", { fg = "#00BCD4" })
    vim.api.nvim_set_hl(0, "RenderMarkdownCalloutTodo", { fg = "#AAD94C" })
    vim.api.nvim_set_hl(0, "RenderMarkdownCalloutFaq", { fg = Colors.white1 }) -- Changed
    vim.api.nvim_set_hl(0, "RenderMarkdownCalloutBug", { fg = "#FF5370" })
    vim.api.nvim_set_hl(0, "RenderMarkdownCalloutFail", { fg = "#D95757" })
    vim.api.nvim_set_hl(0, "RenderMarkdownCalloutExample", { fg = "#D2A6FF" })
    vim.api.nvim_set_hl(0, "RenderMarkdownCalloutImportant", { fg = "#95E6CB" })
   end,
 }

