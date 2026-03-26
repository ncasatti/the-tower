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
      ["@punctuation.separator"] = { fg = Colors.yellow2 }, -- Yellow brackets #edd522
      ["@punctuation.bracket"] = { fg = Colors.yellow2 },

      ["@tag"] = { fg = "#39BAE6" },  -- Cyan for HTML/JSX tags
      ["@tag.attribute"] = { fg = Colors.yellow2 },  -- Yellow for attributes "#FFB454"

      ["@constructor"] = { fg = "#59C2FF" },  -- Blue for constructors
      ["@parameter"] = { fg = "#D2A6FF" },  -- Purple for parameters

      -- Special types
      StorageClass = { fg = "#FF8F40" },  -- Orange for storage (const, let, var)
      ["@storageclass"] = { fg = "#FF8F40" },

      -- Additional semantic highlighting
      ["@namespace"] = { fg = "#AAD94C" },  -- Green for imports/packages
      ["@property"] = { fg = "#39BAE6" },  -- Cyan for properties

      -- Markdown code blocks - ensure transparent backgrounds
      ["@markup.raw"] = { bg = "None" },
      ["@markup.raw.block"] = { bg = "None" },
      ["@markup.raw.markdown_inline"] = { bg = "None" },
      ["@text.literal"] = { bg = "None" },
      ["@text.literal.block"] = { bg = "None" },
      markdownCode = { bg = "None" },
      markdownCodeBlock = { bg = "None" },
      markdownCodeDelimiter = { bg = "None" },
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

    -- Markdown code blocks transparency
    vim.api.nvim_set_hl(0, "@markup.raw", { bg = "None" })
    vim.api.nvim_set_hl(0, "@markup.raw.block", { bg = "None" })
    vim.api.nvim_set_hl(0, "markdownCode", { bg = "None" })
    vim.api.nvim_set_hl(0, "markdownCodeBlock", { bg = "None" })
    vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = "None" })
    vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { bg = "None" })
  end,
}

