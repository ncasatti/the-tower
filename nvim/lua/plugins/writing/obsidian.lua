return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  lazy = true,
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  keys = {
    -- Search commands
    { "<leader>os", "<cmd>Obsidian search<cr>", desc = "Obsidian: Search Notes" },
    { "<leader>og", "<cmd>Obsidian grep<cr>", desc = "Obsidian: Grep Notes" },

    -- Main commands
    { "<leader>on", "<cmd>Obsidian new<cr>", desc = "Obsidian: New Note" },
    { "<leader>ot", "<cmd>Obsidian template<cr>", desc = "Obsidian: Insert Template" },
    { "<leader>oo", "<cmd>Obsidian quick_switch<cr>", desc = "Obsidian: Quick Switch" },

    -- Link commands
    { "<leader>oa", "<cmd>Obsidian links<cr>", desc = "Obsidian: Show All Links" },
    { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Obsidian: Show Backlinks" },

    -- Link and checkbox commands
    { "<leader>of", "<cmd>Obsidian follow_link<cr>", desc = "Obsidian: Follow Link" },
    { "<leader>ox", "<cmd>Obsidian toggle_checkbox<cr>", desc = "Obsidian: Toggle Checkbox" },

    -- Additional commands
    { "<leader>o#", "<cmd>Obsidian tags<cr>", desc = "Obsidian: Search Tags" },
    {
      "<leader>or",
      function()
        return require("obsidian").util.rename_with_visual_selection()
      end,
      desc = "Obsidian: Rename Note",
    },
    { "<leader>oi", "<cmd>Obsidian paste_img<cr>", desc = "Obsidian: Paste Image" },
    { "<leader>ov", "<cmd>Obsidian open<cr>", desc = "Obsidian: Open in Obsidian App" },
  },
  opts = {
    workspaces = {
      {
        name = "Zettelkasten",
        path = vim.fn.expand("~/Documents/Zettelkasten"),
      },
    },

    -- SETOPTS: Disable legacy commands
    legacy_commands = false,

    notes_subdir = "Fleeting",

    -- Other useful settings from our previous attempts
    completion = {
      nvim_cmp = true,
      min_chars = 2,
    },
    templates = {
      subdir = "Templates",
      date_format = "%Y-%m-%d-%a",
      time_format = "%H:%M",
    },
  },
}
