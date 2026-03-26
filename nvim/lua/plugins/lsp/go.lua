return {
  {
    "ray-x/go.nvim",
    dependencies = {  -- optional packages
      "ray-x/guihua.lua",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      -- Ensure Mason bin is in PATH before go.nvim loads
      local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
      if not vim.env.PATH:match(mason_bin) then
        vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
      end

      require("go").setup({
        goimports = 'gopls', -- if set to 'gopls' will use golsp format
        gofmt = 'golines', -- golines respects max_line_len, gofumpt does not
        max_line_len = 120,
        -- CRITICAL: Must use gofmt_args (not formatter!) - see go.nvim/lua/go/format.lua:102
        gofmt_args = { '--max-len=120', '--base-formatter=gofmt' },
        tag_transform = false,
        test_dir = '',
        comment_placeholder = '   ',
        lsp_cfg = false, -- false: use your own lspconfig
        lsp_gofumpt = false, -- disabled since we're using golines
        lsp_on_attach = false, -- use on_attach from gopls
        dap_debug = true,
        verbose = true, -- Enable verbose logging
        log_path = vim.fn.stdpath("cache") .. "/gonvim.log", -- Use Neovim's cache directory
      })

      -- AUTO-FORMAT ON SAVE DISABLED
      -- Uncomment the block below to re-enable auto-format on save
      -- You can still format manually with <leader>ll or :Format command

      --[[ Custom formatter using stdin/stdout to avoid file timing issues
      local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.go",
        callback = function()
          local bufnr = vim.api.nvim_get_current_buf()
          local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/golines"

          -- Get current buffer content
          local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

          local cmd = {
            mason_bin,
            '--max-len=120',
            '--base-formatter=gofmt',
          }

          local stdout_output = {}
          local stderr_output = {}

          local job_id = vim.fn.jobstart(cmd, {
            on_stdout = function(_, data, _)
              if data then
                for _, line in ipairs(data) do
                  if line ~= "" then
                    table.insert(stdout_output, line)
                  end
                end
              end
            end,
            on_stderr = function(_, data, _)
              if data then
                for _, line in ipairs(data) do
                  if line ~= "" then
                    table.insert(stderr_output, line)
                  end
                end
              end
            end,
            on_exit = function(_, exit_code, _)
              if exit_code ~= 0 then
                local err_msg = table.concat(stderr_output, "\n")
                vim.notify(
                  string.format("golines failed (exit %d):\n%s", exit_code, err_msg),
                  vim.log.levels.ERROR
                )
              else
                -- Replace buffer content with formatted output
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, stdout_output)
              end
            end,
            stdout_buffered = true,
            stderr_buffered = true,
          })

          -- Send buffer content to golines via stdin
          vim.fn.chansend(job_id, lines)
          vim.fn.chanclose(job_id, 'stdin')
        end,
        group = format_sync_grp,
      })
      --]]
      
      -- Go-specific keymaps
      vim.keymap.set("n", "<leader>gsj", "<cmd>GoAddTag json<cr>", { desc = "Add json struct tags" })
      vim.keymap.set("n", "<leader>gsy", "<cmd>GoAddTag yaml<cr>", { desc = "Add yaml struct tags" })
      vim.keymap.set("n", "<leader>gst", "<cmd>GoAddTag<cr>", { desc = "Add struct tags" })
      vim.keymap.set("n", "<leader>gsr", "<cmd>GoRmTag<cr>", { desc = "Remove struct tags" })
      vim.keymap.set("n", "<leader>gsf", "<cmd>GoFillStruct<cr>", { desc = "Fill struct" })
      vim.keymap.set("n", "<leader>gsi", "<cmd>GoIfErr<cr>", { desc = "Add if err" })
      vim.keymap.set("n", "<leader>gch", "<cmd>GoCoverage<cr>", { desc = "Test coverage" })
      vim.keymap.set("n", "<leader>gtt", "<cmd>GoTest<cr>", { desc = "Run tests" })
      vim.keymap.set("n", "<leader>gts", "<cmd>GoTestSum<cr>", { desc = "Run tests with summary" })
      vim.keymap.set("n", "<leader>gtf", "<cmd>GoTestFunc<cr>", { desc = "Run test for current func" })
      vim.keymap.set("n", "<leader>gtF", "<cmd>GoTestFile<cr>", { desc = "Run test for current file" })
      vim.keymap.set("n", "<leader>gta", "<cmd>GoAlt!<cr>", { desc = "Open alt file" })
      vim.keymap.set("n", "<leader>gdb", "<cmd>GoDebug<cr>", { desc = "Start debugging" })
      vim.keymap.set("n", "<leader>gdt", "<cmd>GoDbgStop<cr>", { desc = "Stop debugging" })
    end,
    event = {"CmdlineEnter"},
    ft = {"go", 'gomod'},
    build = ':lua require("go.install").update_all_sync()' -- if you need to install/update all binaries
  },
  {
    "olexsmir/gopher.nvim",
    ft = "go",
    config = function(_, opts)
      require("gopher").setup(opts)
      
      -- Additional gopher keymaps
      vim.keymap.set("n", "<leader>gsm", "<cmd>GoMod tidy<cr>", { desc = "Go mod tidy" })
      vim.keymap.set("n", "<leader>gsi", "<cmd>GoImpl<cr>", { desc = "Go impl" })
      vim.keymap.set("n", "<leader>gie", "<cmd>GoIfErr<cr>", { desc = "Go if err" })
    end,
    build = function()
      vim.cmd [[silent! GoInstallDeps]]
    end,
  },
}
