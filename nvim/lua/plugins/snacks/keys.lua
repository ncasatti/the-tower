return {
  -- Top Pickers & Explorer
  { "<leader>bb",       function() Snacks.picker.buffers() end,                                 desc = "Buffers" },
  { "<leader>/",        function() Snacks.picker.grep() end,                                    desc = "Grep" },
  { "<leader>:",        function() Snacks.picker.command_history() end,                         desc = "Command History" },
  -- { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
  -- { "<leader>e", function() Snacks.explorer() end, desc = "File Explorer" },

  -- Buffer Management
  { "<leader>bd",       function() Snacks.bufdelete() end,                                      desc = "Delete Buffer" },
  { "<leader>bD",       function()
                          local current_buf = vim.api.nvim_get_current_buf()
                          local buffers = vim.api.nvim_list_bufs()
                          for _, buf in ipairs(buffers) do
                            if buf ~= current_buf and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
                              vim.api.nvim_buf_delete(buf, { force = false })
                            end
                          end
                        end,                                                                     desc = "Delete All Buffers Except Current" },
  { "<leader>bw",       function()
                          local current_buf = vim.api.nvim_get_current_buf()
                          local wins = vim.api.nvim_list_wins()
                          local visible_bufs = {}
                          for _, win in ipairs(wins) do
                            local buf = vim.api.nvim_win_get_buf(win)
                            visible_bufs[buf] = true
                          end
                          local buffers = vim.api.nvim_list_bufs()
                          for _, buf in ipairs(buffers) do
                            if buf ~= current_buf and not visible_bufs[buf] and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
                              vim.api.nvim_buf_delete(buf, { force = false })
                            end
                          end
                        end,                                                                     desc = "Wipe Hidden Buffers" },

  -- Find
  { "<leader>ts",       function() Snacks.picker.smart() end,                                   desc = "Smart Find Files" },
  { "<leader>tt",       function() Snacks.picker.buffers() end,                                 desc = "Buffers" },
  { "<leader>tc",       function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find Config File" },
  { "<leader><leader>", function() Snacks.picker.files() end,                                   desc = "Find Files" },
  { "<leader>tg",       function() Snacks.picker.git_files() end,                               desc = "Find Git Files" },
  { "<leader>tp",       function() Snacks.picker.projects() end,                                desc = "Projects" },
  { "<leader>tr",       function() Snacks.picker.recent({ filter = { cwd = true } }) end,       desc = "Recent (CWD)" },
  { "<leader>tR",       function() Snacks.picker.recent() end,                                  desc = "Recent (Global)" },

  -- Git
  { "<leader>gb",       function() Snacks.picker.git_branches() end,                            desc = "Git Branches" },
  { "<leader>gl",       function() Snacks.picker.git_log() end,                                 desc = "Git Log" },
  { "<leader>gL",       function() Snacks.picker.git_log_line() end,                            desc = "Git Log Line" },
  { "<leader>gs",       function() Snacks.picker.git_status() end,                              desc = "Git Status" },
  { "<leader>gS",       function() Snacks.picker.git_stash() end,                               desc = "Git Stash" },
  { "<leader>gd",       function() Snacks.picker.git_diff() end,                                desc = "Git Diff (Hunks)" },
  { "<leader>gf",       function() Snacks.picker.git_log_file() end,                            desc = "Git Log File" },

  -- Grep
  { "<leader>sb",       function() Snacks.picker.lines() end,                                   desc = "Buffer Lines" },
  { "<leader>sB",       function() Snacks.picker.grep_buffers() end,                            desc = "Grep Open Buffers" },
  { "<leader>sg",       function() Snacks.picker.grep() end,                                    desc = "Grep" },
  { "<leader>sw",       function() Snacks.picker.grep_word() end,                               desc = "Visual selection or word", mode = { "n", "x" } },

  -- Search
  { '<leader>s"',       function() Snacks.picker.registers() end,                               desc = "Registers" },
  { '<leader>s/',       function() Snacks.picker.search_history() end,                          desc = "Search History" },
  { "<leader>sa",       function() Snacks.picker.autocmds() end,                                desc = "Autocmds" },
  { "<leader>sb",       function() Snacks.picker.lines() end,                                   desc = "Buffer Lines" },
  { "<leader>sc",       function() Snacks.picker.command_history() end,                         desc = "Command History" },
  { "<leader>sC",       function() Snacks.picker.commands() end,                                desc = "Commands" },
  { "<leader>sd",       function() Snacks.picker.diagnostics() end,                             desc = "Diagnostics" },
  { "<leader>sD",       function() Snacks.picker.diagnostics_buffer() end,                      desc = "Buffer Diagnostics" },
  { "<leader>sh",       function() Snacks.picker.help() end,                                    desc = "Help Pages" },
  { "<leader>sH",       function() Snacks.picker.highlights() end,                              desc = "Highlights" },
  { "<leader>si",       function() Snacks.picker.icons() end,                                   desc = "Icons" },
  { "<leader>sj",       function() Snacks.picker.jumps() end,                                   desc = "Jumps" },
  { "<leader>sk",       function() Snacks.picker.keymaps() end,                                 desc = "Keymaps" },
  { "<leader>sl",       function() Snacks.picker.loclist() end,                                 desc = "Location List" },
  { "<leader>sm",       function() Snacks.picker.marks() end,                                   desc = "Marks" },
  { "<leader>sM",       function() Snacks.picker.man() end,                                     desc = "Man Pages" },
  { "<leader>sp",       function() Snacks.picker.lazy() end,                                    desc = "Search for Plugin Spec" },
  { "<leader>sq",       function() Snacks.picker.qflist() end,                                  desc = "Quickfix List" },
  { "<leader>sR",       function() Snacks.picker.resume() end,                                  desc = "Resume" },
  { "<leader>su",       function() Snacks.picker.undo() end,                                    desc = "Undo History" },
  -- { "<leader>uC",      function() Snacks.picker.colorschemes() end,                            desc = "Colorschemes" },

  -- LSP
  { "gd",               function() Snacks.picker.lsp_definitions() end,                         desc = "Goto Definition" },
  { "gD",               function() Snacks.picker.lsp_declarations() end,                        desc = "Goto Declaration" },
  { "gr",               function() Snacks.picker.lsp_references() end,                          nowait = true,                     desc = "References" },
  { "gI",               function() Snacks.picker.lsp_implementations() end,                     desc = "Goto Implementation" },
  { "gy",               function() Snacks.picker.lsp_type_definitions() end,                    desc = "Goto T[y]pe Definition" },
  { "<leader>ss",       function() Snacks.picker.lsp_symbols() end,                             desc = "LSP Symbols" },
  { "<leader>sS",       function() Snacks.picker.lsp_workspace_symbols() end,                   desc = "LSP Workspace Symbols" },

  -- Other
  { "<leader>z",        function() Snacks.zen() end,                                            desc = "Toggle Zen Mode" },
  { "<leader>Z",        function() Snacks.zen({ toggles = { dim = true } }) end,                desc = "Toggle Zen Mode (Dim)" },
  { "<leader>.",        function() Snacks.scratch() end,                                        desc = "Toggle Scratch Buffer" },
  { "<leader>S",        function() Snacks.scratch.select() end,                                 desc = "Select Scratch Buffer" },
  -- { "<leader>n",  function() Snacks.notifier.show_history() end, desc = "Notification History" },
  { "<leader>cR",       function() Snacks.rename.rename_file() end,                             desc = "Rename File" },
  { "<leader>gB",       function() Snacks.gitbrowse() end,                                      desc = "Git Browse",               mode = { "n", "v" } },
  { "<leader>gg",       function() Snacks.lazygit() end,                                        desc = "Lazygit" },
  -- { "<leader>un",      function() Snacks.notifier.hide() end,                                  desc = "Dismiss All Notifications" },
  { "<c-/>",            function() Snacks.terminal() end,                                       desc = "Toggle Terminal" },
  { "<c-_>",            function() Snacks.terminal() end,                                       desc = "which_key_ignore" },
  { "]]",               function() Snacks.words.jump(vim.v.count1) end,                         desc = "Next Reference",           mode = { "n", "t" } },
  { "[[",               function() Snacks.words.jump(-vim.v.count1) end,                        desc = "Prev Reference",           mode = { "n", "t" } },
}
