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
    { "<leader>os", "<cmd>Obsidian search<cr>", desc = "Search Notes" },
    { "<leader>og", "<cmd>Obsidian grep<cr>", desc = "Grep Notes" },

    -- Main commands
    { "<leader>on", "<cmd>Obsidian new<cr>", desc = "New Note" },
    { "<leader>ot", "<cmd>Obsidian template<cr>", desc = "Insert Template" },
    { "<leader>oo", "<cmd>Obsidian quick_switch<cr>", desc = "Quick Switch" },

    -- Link commands
    { "<leader>oa", "<cmd>Obsidian links<cr>", desc = "Show All Links" },
    { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Show Backlinks" },

    -- Link and checkbox commands
    { "<leader>of", "<cmd>Obsidian follow_link<cr>", desc = "Follow Link" },
    { "<leader>ox", "<cmd>Obsidian toggle_checkbox<cr>", desc = "Toggle Checkbox" },

    -- Additional commands
    { "<leader>o#", "<cmd>Obsidian tags<cr>", desc = "Search Tags" },
    {
      "<leader>or",
      function()
        return require("obsidian").util.rename_with_visual_selection()
      end,
      desc = "Rename Note",
    },
    { "<leader>oi", "<cmd>Obsidian paste_img<cr>", desc = "Paste Image" },
    { "<leader>ov", "<cmd>Obsidian open<cr>", desc = "Open in Obsidian App" },
  },
  config = function(_, opts)
    require("obsidian").setup({
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
    })

    -- Disable documentSymbol on obsidian-ls (marksman provides cleaner rendered symbols)
    vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client and client.name == "obsidian-ls" then
                client.server_capabilities.documentSymbolProvider = false
            end
        end,
    })
  end,
}
