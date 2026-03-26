-- Dadbod: Database interface for Neovim
-- URLs:
--   - https://github.com/tpope/vim-dadbod
--   - https://github.com/kristijanhusak/vim-dadbod-ui
--
-- Dadbod provides a database interface that works with multiple database types:
-- PostgreSQL, MySQL, SQLite, MongoDB, Redis, etc.
--
-- Usage:
--   :DBUI                     - Toggle database UI
--   :DB [connection] [query]  - Execute query directly
--   <leader>Bb                - Toggle DBUI
--   <leader>Bf                - Find buffer (in DBUI)
--   <leader>Br                - Rename buffer (in DBUI)
--   <leader>Bq                - Last query info
--   <leader>BS                - Execute SQL query (in SQL files)
--   <leader>BW                - Save query (in SQL files)
--
-- Configuration:
--   Database connections are stored in:
--   - Environment variables (recommended for security)
--   - g:dbs global variable
--   - .env files
--
-- Example connection setup in init.lua or separate config:
--   vim.g.dbs = {
--     { name = 'local_postgres', url = 'postgresql://user:password@localhost:5432/dbname' },
--     { name = 'local_mysql', url = 'mysql://user:password@localhost:3306/dbname' },
--   }

return {
  "kristijanhusak/vim-dadbod-ui",
  
  dependencies = {
    { "tpope/vim-dadbod", lazy = true },
    { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
  },

  cmd = {
    "DBUI",
    "DBUIToggle",
    "DBUIAddConnection",
    "DBUIFindBuffer",
  },

  keys = {
    { "<leader>Bb", "<cmd>DBUIToggle<cr>", desc = "Toggle Database UI" },
    { "<leader>Bf", "<cmd>DBUIFindBuffer<cr>", desc = "Find database buffer" },
    { "<leader>Br", "<cmd>DBUIRenameBuffer<cr>", desc = "Rename database buffer" },
    { "<leader>Bq", "<cmd>DBUILastQueryInfo<cr>", desc = "Last query info" },
  },

  init = function()
    -- Disable mappings that conflict with Colemak layout
    vim.g.db_ui_disable_mappings = 0

    -- UI Configuration
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.db_ui_show_database_icon = 1
    vim.g.db_ui_force_echo_notifications = 0
    vim.g.db_ui_win_position = "left"
    vim.g.db_ui_winwidth = 40

    -- Auto-execute query on save
    vim.g.db_ui_auto_execute_table_helpers = 1

    -- Save/Load queries
    vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"

    -- Icons for UI
    vim.g.db_ui_icons = {
      expanded = {
        db = "▾ ",
        buffers = "▾ ",
        saved_queries = "▾ ",
        schemas = "▾ ",
        schema = "▾ 󰙅",
        tables = "▾ 󰓫",
        table = "▾ ",
      },
      collapsed = {
        db = "▸ ",
        buffers = "▸ ",
        saved_queries = "▸ ",
        schemas = "▸ ",
        schema = "▸ 󰙅",
        tables = "▸ 󰓫",
        table = "▸ ",
      },
      saved_query = "",
      new_query = "璘",
      tables = "󰓫",
      buffers = "﬘",
      add_connection = "",
      connection_ok = "✓",
      connection_error = "✕",
    }

    -- Custom keybindings for DBUI buffer (respecting Colemak)
    vim.g.db_ui_execute_on_save = 0 -- Don't auto-execute on save (set to 1 if you want it)

    -- Database connections (example - OVERRIDE THIS in your init.lua or local config)
    -- IMPORTANT: For security, use environment variables instead:
    --   vim.g.dbs = {
    --     { name = 'production', url = vim.env.DATABASE_URL },
    --   }
    --
    -- Or use a separate file not tracked by git:
    --   local ok, local_dbs = pcall(require, 'local.databases')
    --   if ok then
    --     vim.g.dbs = local_dbs
    --   end
  end,

  config = function()
    -- SQL completion integration with nvim-cmp
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "sql", "mysql", "plsql" },
      callback = function()
        local cmp = require("cmp")
        local sources = vim.tbl_deep_extend("force", cmp.get_config().sources, {
          { name = "vim-dadbod-completion" },
        })
        cmp.setup.buffer({ sources = sources })
      end,
    })

    -- Custom keymaps for database buffers
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "dbui",
      callback = function()
        -- Colemak-friendly navigation
        vim.keymap.set("n", "u", "k", { buffer = true, desc = "Move up" })
        vim.keymap.set("n", "e", "j", { buffer = true, desc = "Move down" })
        vim.keymap.set("n", "<CR>", "<Plug>(DBUI_SelectLine)", { buffer = true, desc = "Select line" })
        vim.keymap.set("n", "o", "<Plug>(DBUI_SelectLineVsplit)", { buffer = true, desc = "Open in vsplit" })
        vim.keymap.set("n", "S", "<Plug>(DBUI_SelectLineSplit)", { buffer = true, desc = "Open in split" })
        vim.keymap.set("n", "R", "<Plug>(DBUI_Redraw)", { buffer = true, desc = "Redraw UI" })
        vim.keymap.set("n", "d", "<Plug>(DBUI_DeleteLine)", { buffer = true, desc = "Delete" })
        vim.keymap.set("n", "A", "<Plug>(DBUI_AddConnection)", { buffer = true, desc = "Add connection" })
        vim.keymap.set("n", "H", "<Plug>(DBUI_ToggleResultLayout)", { buffer = true, desc = "Toggle layout" })
      end,
    })

    -- SQL file keymaps
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "sql", "mysql", "plsql" },
      callback = function()
        -- Execute query under cursor or visual selection
        vim.keymap.set("n", "<leader>BS", "<Plug>(DBUI_ExecuteQuery)", { buffer = true, desc = "Execute query" })
        vim.keymap.set("v", "<leader>BS", "<Plug>(DBUI_ExecuteQuery)", { buffer = true, desc = "Execute query" })
        vim.keymap.set("n", "<leader>BW", "<Plug>(DBUI_SaveQuery)", { buffer = true, desc = "Save query" })
      end,
    })
  end,
}
