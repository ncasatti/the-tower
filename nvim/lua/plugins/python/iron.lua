-- Iron.nvim - Interactive REPL for Python
-- Send code to iPython/Python REPL for quick iteration
return {
  "Vigemus/iron.nvim",
  ft = { "python" }, -- Load only for Python files
  config = function()
    local iron = require("iron.core")
    local view = require("iron.view")

    iron.setup({
      config = {
        -- Whether a repl should be discarded or not
        scratch_repl = true,
        
        -- Your repl definitions come here
        repl_definition = {
          python = {
            -- Can be a string or a list of strings
            command = { "ipython", "--no-autoindent" },
            -- command = { "python3" }, -- Fallback if ipython not installed
            format = require("iron.fts.common").bracketed_paste,
          },
        },
        
        -- How the repl window will be displayed
        -- See :h iron-repl-positioning for more options
        repl_open_cmd = view.split.vertical.botright(80), -- 80 cols on right side
        -- repl_open_cmd = view.split.horizontal.botright(15), -- 15 rows on bottom
        -- repl_open_cmd = "vertical botright 80 split", -- Alternative
      },
      
      -- Iron doesn't set keymaps by default anymore
      -- You can set them here or manually add keymaps to your config
      keymaps = {
        send_motion = "<leader>rc", -- Send motion (e.g., <leader>rc + ip for paragraph)
        visual_send = "<leader>rc", -- Send visual selection
        send_line = "<leader>rl",   -- Send current line
        send_until_cursor = "<leader>ru", -- Send from start to cursor
        send_mark = "<leader>rm",   -- Send mark
        mark_motion = "<leader>rmc", -- Mark motion
        mark_visual = "<leader>rmc", -- Mark visual
        remove_mark = "<leader>rmd", -- Remove mark
        cr = "<leader>r<cr>",       -- Send carriage return
        interrupt = "<leader>r<space>", -- Interrupt REPL
        exit = "<leader>rq",        -- Exit REPL
        clear = "<leader>rx",       -- Clear REPL
      },
      
      -- If the highlight is on, you can change how it looks
      highlight = {
        italic = true,
      },
      
      ignore_blank_lines = true, -- Ignore blank lines when sending code
    })

    -- Python-specific keybindings
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "python",
      callback = function()
        local opts = { buffer = true, silent = true, noremap = true }
        
        -- REPL lifecycle
        vim.keymap.set("n", "<leader>rs", "<cmd>IronRepl<cr>",
          vim.tbl_extend("force", opts, { desc = "Start/Toggle" }))

        vim.keymap.set("n", "<leader>rr", "<cmd>IronRestart<cr>",
          vim.tbl_extend("force", opts, { desc = "Restart" }))

        vim.keymap.set("n", "<leader>rf", "<cmd>IronFocus<cr>",
          vim.tbl_extend("force", opts, { desc = "Focus" }))

        vim.keymap.set("n", "<leader>rh", "<cmd>IronHide<cr>",
          vim.tbl_extend("force", opts, { desc = "Hide" }))

        -- Send code shortcuts (iron.core wrappers)
        vim.keymap.set("n", "<leader>rF", function()
          require("iron.core").send_file()
        end, vim.tbl_extend("force", opts, { desc = "Send file" }))

        -- Ergonomic motion shortcuts (pre-baked send_motion calls)
        vim.keymap.set("n", "<leader>rp", function()
          require("iron.core").send_motion("ip")
        end, vim.tbl_extend("force", opts, { desc = "Send paragraph" }))

        vim.keymap.set("n", "<leader>rb", function()
          require("iron.core").send_motion("ab")
        end, vim.tbl_extend("force", opts, { desc = "Send block" }))
      end,
    })
  end,
}
