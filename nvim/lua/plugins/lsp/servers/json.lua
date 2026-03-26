-- JSON Language Server Configuration
return {
  name = 'jsonls',
  config = function(capabilities, on_attach)
    vim.lsp.config('jsonls', {
      cmd = { 'vscode-json-language-server', '--stdio' },
      filetypes = { 'json', 'jsonc' },
      root_markers = { '.git', 'package.json' },
      capabilities = capabilities,
      on_attach = on_attach,
      settings = {
        json = {
          schemas = {
            {
              fileMatch = { 'package.json' },
              url = 'https://json.schemastore.org/package.json',
            },
            {
              fileMatch = { 'tsconfig*.json' },
              url = 'https://json.schemastore.org/tsconfig.json',
            },
          },
        },
      },
    })

    -- JSON formatting using jq (override <leader>ll for JSON files)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "json", "jsonc" },
      callback = function(args)
        local bufnr = args.buf
        -- Override the format keymap for JSON files to use jq
        vim.keymap.set('n', '<leader>ll', function()
          local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
          local content = table.concat(lines, "\n")

          local stdout_output = {}
          local stderr_output = {}

          local job_id = vim.fn.jobstart({ 'jq', '.' }, {
            on_stdout = function(_, data, _)
              if data then
                for _, line in ipairs(data) do
                  table.insert(stdout_output, line)
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
                  string.format("jq formatting failed (exit %d):\n%s", exit_code, err_msg),
                  vim.log.levels.ERROR
                )
              else
                -- Remove empty last line that jq adds
                if stdout_output[#stdout_output] == "" then
                  table.remove(stdout_output, #stdout_output)
                end
                -- Replace buffer content with formatted output
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, stdout_output)
              end
            end,
            stdout_buffered = true,
            stderr_buffered = true,
          })

          -- Send buffer content to jq via stdin
          vim.fn.chansend(job_id, content)
          vim.fn.chanclose(job_id, 'stdin')
        end, { buffer = bufnr, desc = 'Format JSON with jq' })

        -- Also override :Format command
        vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<leader>ll', true, false, true), 'n', false)
        end, { desc = 'Format JSON with jq' })
      end,
    })
  end
}
