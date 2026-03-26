-- Neotest - Test Runner Integration
-- Provides inline test execution, debugging, and results visualization
return {
    "nvim-neotest/neotest",
    dependencies = {
        "nvim-neotest/nvim-nio",
        "nvim-lua/plenary.nvim",
        "antoinemadec/FixCursorHold.nvim",
        "nvim-treesitter/nvim-treesitter",

        -- Test adapters for different languages
        "nvim-neotest/neotest-python", -- Python (pytest, unittest)

        -- Optional: Add more adapters as needed
        -- "nvim-neotest/neotest-jest",     -- JavaScript/TypeScript
        -- "nvim-neotest/neotest-go",       -- Go
        -- "rouge8/neotest-rust",           -- Rust
    },
    lazy = false, -- Load immediately to register keybindings
    config = function()
        local neotest = require("neotest")

        neotest.setup({
            -- Adapters configuration
            adapters = {
                require("neotest-python")({
                    -- Python test runner (pytest by default)
                    dap = { justMyCode = false }, -- Enable debugging into library code

                    -- Auto-detect test runner
                    runner = "pytest",

                    -- Python executable (respects virtualenv)
                    python = function()
                        local cwd = vim.fn.getcwd()
                        -- Try to detect virtual environment
                        if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
                            return cwd .. '/venv/bin/python'
                        elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
                            return cwd .. '/.venv/bin/python'
                        else
                            return 'python3'
                        end
                    end,

                    -- Pytest arguments
                    args = { "--log-level", "DEBUG", "--color", "yes" },

                    -- Test file pattern
                    is_test_file = function(file_path)
                        -- Match test_*.py or *_test.py
                        local file_name = vim.fn.fnamemodify(file_path, ":t")
                        return file_name:match("^test_.*%.py$") or file_name:match(".*_test%.py$")
                    end,
                }),
            },

            -- UI configuration
            icons = {
                running = "●",
                passed = "✓",
                failed = "✗",
                skipped = "○",
                unknown = "?",
                running_animated = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
            },

            -- Highlight groups
            highlights = {
                passed = "NeotestPassed",
                failed = "NeotestFailed",
                running = "NeotestRunning",
                skipped = "NeotestSkipped",
            },

            -- Floating window configuration
            floating = {
                border = "rounded",
                max_height = 0.8,
                max_width = 0.8,
                options = {},
            },

            -- Summary window configuration
            summary = {
                enabled = true,
                expand_errors = true,
                follow = true,
                mappings = {
                    attach = "a",
                    clear_marked = "M",
                    clear_target = "T",
                    debug = "d",
                    debug_marked = "D",
                    expand = { "<CR>", "<2-LeftMouse>" },
                    expand_all = "e",
                    jumpto = "i", -- 'i' for navigation (Colemak friendly)
                    mark = "m",
                    next_failed = "n", -- 'n' for next (Colemak right)
                    output = "o",
                    prev_failed = "u", -- 'u' for prev (Colemak up)
                    run = "r",
                    run_marked = "R",
                    short = "O",
                    stop = "s",
                    target = "t",
                    watch = "w",
                },
            },

            -- Output window configuration
            output = {
                enabled = true,
                open_on_run = "short", -- "short" | "long" | false
            },

            -- Quickfix integration
            quickfix = {
                enabled = true,
                open = false, -- Don't auto-open quickfix
            },

            -- Status line integration
            status = {
                enabled = true,
                virtual_text = false, -- Don't show status in virtual text
                signs = true, -- Show signs in gutter
            },

            -- Strategies for running tests
            -- "integrated" runs in nvim terminal
            -- "dap" runs with debugger attached
            strategies = {
                integrated = {
                    height = 15,
                    width = 120,
                },
            },

            -- Log level
            log_level = vim.log.levels.WARN,
        })

        -- Define highlight groups
        vim.api.nvim_set_hl(0, "NeotestPassed", { fg = "#9ece6a", bold = true })
        vim.api.nvim_set_hl(0, "NeotestFailed", { fg = "#f7768e", bold = true })
        vim.api.nvim_set_hl(0, "NeotestRunning", { fg = "#e0af68", bold = true })
        vim.api.nvim_set_hl(0, "NeotestSkipped", { fg = "#565f89", bold = true })

        -- Python-specific keybindings (only active in Python test files)
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "python",
            callback = function()
                local opts = { buffer = true, silent = true }

                -- Run tests (using <leader>T - capital T for tests)
                vim.keymap.set("n", "<leader>Tr", function()
                    neotest.run.run()
                end, vim.tbl_extend("force", opts, { desc = "Test: Run Nearest" }))

                vim.keymap.set("n", "<leader>Tf", function()
                    neotest.run.run(vim.fn.expand("%"))
                end, vim.tbl_extend("force", opts, { desc = "Test: Run File" }))

                vim.keymap.set("n", "<leader>Ta", function()
                    neotest.run.run(vim.fn.getcwd())
                end, vim.tbl_extend("force", opts, { desc = "Test: Run All" }))

                vim.keymap.set("n", "<leader>Tl", function()
                    neotest.run.run_last()
                end, vim.tbl_extend("force", opts, { desc = "Test: Run Last" }))

                vim.keymap.set("n", "<leader>Ts", function()
                    neotest.run.stop()
                end, vim.tbl_extend("force", opts, { desc = "Test: Stop" }))

                -- Debug tests
                vim.keymap.set("n", "<leader>Td", function()
                    neotest.run.run({ strategy = "dap" })
                end, vim.tbl_extend("force", opts, { desc = "Test: Debug Nearest" }))

                -- Test UI
                vim.keymap.set("n", "<leader>To", function()
                    neotest.output.open({ enter = true, auto_close = true })
                end, vim.tbl_extend("force", opts, { desc = "Test: Show Output" }))

                vim.keymap.set("n", "<leader>TO", function()
                    neotest.output_panel.toggle()
                end, vim.tbl_extend("force", opts, { desc = "Test: Toggle Output Panel" }))

                vim.keymap.set("n", "<leader>TS", function()
                    neotest.summary.toggle()
                end, vim.tbl_extend("force", opts, { desc = "Test: Toggle Summary" }))

                -- Navigation
                vim.keymap.set("n", "[T", function()
                    neotest.jump.prev({ status = "failed" })
                end, vim.tbl_extend("force", opts, { desc = "Test: Jump to Previous Failed" }))

                vim.keymap.set("n", "]T", function()
                    neotest.jump.next({ status = "failed" })
                end, vim.tbl_extend("force", opts, { desc = "Test: Jump to Next Failed" }))

                -- Watch mode
                vim.keymap.set("n", "<leader>Tw", function()
                    neotest.watch.toggle(vim.fn.expand("%"))
                end, vim.tbl_extend("force", opts, { desc = "Test: Toggle Watch" }))
            end,
        })
    end,
}
