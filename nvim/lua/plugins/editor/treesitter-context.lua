return {
  "nvim-treesitter/nvim-treesitter-context",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("treesitter-context").setup({
      enable = true, -- Enable by default
      max_lines = 5, -- Maximum number of context lines to show
      min_window_height = 10, -- Minimum editor window height to enable context
      line_numbers = true, -- Show line numbers in context
      multiline_threshold = 1, -- Minimum number of lines for multiline context
      trim_scope = "outer", -- Remove whitespace from context
      mode = "cursor", -- Line used to calculate context (cursor or topline)
      separator = "-", -- Separator between context and content
      zindex = 20, -- Z-index of context window
    })
  end,
  keys = {
    {
      "<leader>ct",
      function()
        require("treesitter-context").toggle()
      end,
      desc = "Toggle Treesitter Context",
    },
    {
      "[c",
      function()
        require("treesitter-context").go_to_context(vim.v.count1)
      end,
      desc = "Jump to Context",
    },
  },
}
