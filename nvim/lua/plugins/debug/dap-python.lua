-- Python Debug Adapter Protocol Configuration
-- Provides debugging support for Python scripts, tests, and Jupyter notebooks
return {
    "mfussenegger/nvim-dap-python",
    dependencies = {
        "mfussenegger/nvim-dap",
    },
    lazy = false, -- Load immediately to ensure adapter is available
    config = function()
        local dap_python = require("dap-python")

        -- Setup DAP Python with debugpy
        -- Mason installs debugpy at: ~/.local/share/nvim/mason/packages/debugpy/venv/bin/python
        local mason_path = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"

        -- Fallback to system python if Mason's debugpy not found
        if vim.fn.filereadable(mason_path) == 1 then
            dap_python.setup(mason_path)
        else
            -- Try to find debugpy in system python
            dap_python.setup("python3")
            vim.notify(
                "Mason's debugpy not found. Install it with :MasonInstall debugpy",
                vim.log.levels.WARN
            )
        end

        -- Python-specific debug configurations
        local dap = require("dap")

        -- Configure Python adapter settings to handle line/column indexing correctly
        if not dap.adapters.python then
            dap.adapters.python = {
                type = 'executable',
                command = mason_path,
                args = { '-m', 'debugpy.adapter' },
            }
        end

        -- Patch: Suppress false-positive "Cursor position outside buffer" warnings during Python debugging
        -- This happens when debugpy reports a frame position that's slightly out of sync with the buffer
        local original_notify = vim.notify
        vim.notify = function(msg, level, opts)
            -- Filter out the cursor position warning only during active DAP session
            if type(msg) == "string" 
                and msg:match("Cursor position outside buffer")
                and dap.session() then
                -- Debug: uncomment to see when this triggers
                -- vim.api.nvim_echo({{"[DAP] Suppressed cursor warning", "Comment"}}, false, {})
                return
            end
            return original_notify(msg, level, opts)
        end

        -- Override default configurations with more useful ones
        dap.configurations.python = {
            {
                type = 'python',
                request = 'launch',
                name = "Launch file",
                program = "${file}", -- Current file
                pythonPath = function()
                    -- Try to detect virtual environment
                    local cwd = vim.fn.getcwd()
                    if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
                        return cwd .. '/venv/bin/python'
                    elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
                        return cwd .. '/.venv/bin/python'
                    elseif vim.fn.executable(vim.fn.expand('~/.virtualenvs/nvim/bin/python')) == 1 then
                        return vim.fn.expand('~/.virtualenvs/nvim/bin/python')
                    else
                        return '/usr/bin/python3'
                    end
                end,
            },
            {
                type = 'python',
                request = 'launch',
                name = "Launch file with arguments",
                program = "${file}",
                args = function()
                    local args_string = vim.fn.input('Arguments: ')
                    return vim.split(args_string, " +")
                end,
                pythonPath = function()
                    local cwd = vim.fn.getcwd()
                    if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
                        return cwd .. '/venv/bin/python'
                    elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
                        return cwd .. '/.venv/bin/python'
                    else
                        return '/usr/bin/python3'
                    end
                end,
            },
            {
                type = 'python',
                request = 'launch',
                name = "Launch module",
                module = function()
                    return vim.fn.input('Module name: ')
                end,
                pythonPath = function()
                    local cwd = vim.fn.getcwd()
                    if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
                        return cwd .. '/venv/bin/python'
                    elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
                        return cwd .. '/.venv/bin/python'
                    else
                        return '/usr/bin/python3'
                    end
                end,
            },
            {
                type = 'python',
                request = 'attach',
                name = 'Attach remote',
                connect = function()
                    local host = vim.fn.input('Host [localhost]: ')
                    host = host ~= '' and host or 'localhost'
                    local port = tonumber(vim.fn.input('Port [5678]: ')) or 5678
                    return { host = host, port = port }
                end,
            },
            {
                type = 'python',
                request = 'launch',
                name = 'Django',
                program = vim.fn.getcwd() .. '/manage.py',
                args = { 'runserver', '--noreload' },
                pythonPath = function()
                    local cwd = vim.fn.getcwd()
                    if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
                        return cwd .. '/venv/bin/python'
                    elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
                        return cwd .. '/.venv/bin/python'
                    else
                        return '/usr/bin/python3'
                    end
                end,
                console = 'integratedTerminal',
            },
            {
                type = 'python',
                request = 'launch',
                name = 'Flask',
                module = 'flask',
                env = {
                    FLASK_APP = 'app.py',
                    FLASK_ENV = 'development',
                },
                args = { 'run', '--no-debugger', '--no-reload' },
                jinja = true,
                pythonPath = function()
                    local cwd = vim.fn.getcwd()
                    if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
                        return cwd .. '/venv/bin/python'
                    elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
                        return cwd .. '/.venv/bin/python'
                    else
                        return '/usr/bin/python3'
                    end
                end,
            },
        }

        -- Python-specific keybindings (only active in Python files)
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "python",
            callback = function()
                local opts = { buffer = true, silent = true }

                -- Test debugging shortcuts
                vim.keymap.set("n", "<leader>dtn", function()
                    require("dap-python").test_method()
                end, vim.tbl_extend("force", opts, { desc = "Debug: Test Method (Python)" }))

                vim.keymap.set("n", "<leader>dtc", function()
                    require("dap-python").test_class()
                end, vim.tbl_extend("force", opts, { desc = "Debug: Test Class (Python)" }))

                vim.keymap.set("v", "<leader>ds", function()
                    require("dap-python").debug_selection()
                end, vim.tbl_extend("force", opts, { desc = "Debug: Selection (Python)" }))
            end,
        })
    end,
}
