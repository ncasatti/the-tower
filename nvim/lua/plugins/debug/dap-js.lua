-- JavaScript/TypeScript Debug Adapter Protocol Configuration
-- Uses vscode-js-debug (js-debug-adapter) installed via Mason
return {
    "mfussenegger/nvim-dap",
    optional = true,
    config = function()
        local dap = require("dap")

        -- Path to Mason-installed js-debug-adapter
        local mason_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter"
        local adapter_bin = mason_path .. "/js-debug-adapter"

        if vim.fn.executable(adapter_bin) ~= 1 then
            vim.notify(
                "js-debug-adapter not found. Install it with :MasonInstall js-debug-adapter",
                vim.log.levels.WARN
            )
            return
        end

        -- Register pwa-node adapter (Node.js debugging)
        dap.adapters["pwa-node"] = {
            type = "server",
            host = "localhost",
            port = "${port}",
            executable = {
                command = adapter_bin,
                args = { "${port}" },
            },
        }

        -- Register pwa-chrome adapter (Chrome/browser debugging)
        dap.adapters["pwa-chrome"] = {
            type = "server",
            host = "localhost",
            port = "${port}",
            executable = {
                command = adapter_bin,
                args = { "${port}" },
            },
        }

        -- Shared configurations for JS/TS and React variants
        local js_configs = {
            {
                type = "pwa-node",
                request = "launch",
                name = "Launch file (Node)",
                program = "${file}",
                cwd = "${workspaceFolder}",
                sourceMaps = true,
                protocol = "inspector",
                console = "integratedTerminal",
            },
            {
                type = "pwa-node",
                request = "launch",
                name = "Launch file with arguments (Node)",
                program = "${file}",
                cwd = "${workspaceFolder}",
                args = function()
                    local args_string = vim.fn.input("Arguments: ")
                    return vim.split(args_string, " +", { trimempty = true })
                end,
                sourceMaps = true,
                protocol = "inspector",
                console = "integratedTerminal",
            },
            {
                type = "pwa-node",
                request = "attach",
                name = "Attach to Node process",
                processId = require("dap.utils").pick_process,
                cwd = "${workspaceFolder}",
                sourceMaps = true,
            },
            {
                type = "pwa-node",
                request = "launch",
                name = "Debug Jest (current file)",
                runtimeExecutable = "node",
                runtimeArgs = {
                    "${workspaceFolder}/node_modules/.bin/jest",
                    "--runInBand",
                    "--no-coverage",
                    "${file}",
                },
                cwd = "${workspaceFolder}",
                sourceMaps = true,
                protocol = "inspector",
                console = "integratedTerminal",
                rootPath = "${workspaceFolder}",
                internalConsoleOptions = "neverOpen",
            },
            {
                type = "pwa-node",
                request = "launch",
                name = "Debug Vitest (current file)",
                runtimeExecutable = "node",
                runtimeArgs = {
                    "${workspaceFolder}/node_modules/.bin/vitest",
                    "run",
                    "${file}",
                },
                cwd = "${workspaceFolder}",
                sourceMaps = true,
                protocol = "inspector",
                console = "integratedTerminal",
            },
            {
                type = "pwa-chrome",
                request = "attach",
                name = "Attach to Chrome (port 9222)",
                program = "${file}",
                cwd = "${workspaceFolder}",
                sourceMaps = true,
                port = 9222,
                webRoot = "${workspaceFolder}",
            },
            {
                type = "pwa-chrome",
                request = "launch",
                name = "Launch Chrome (http://localhost:3000)",
                url = "http://localhost:3000",
                webRoot = "${workspaceFolder}",
                sourceMaps = true,
            },
        }

        -- Apply same configurations to all JS/TS filetypes
        for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
            dap.configurations[ft] = js_configs
        end
    end,
}
