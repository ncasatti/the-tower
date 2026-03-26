-- Java Language Server Configuration (JDTLS)
local home = os.getenv("HOME")
local mason_path = vim.fn.stdpath("data") .. "/mason"
local launcher_jar = vim.fn.glob(mason_path .. "/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar")

-- FIX: Handle cases where glob returns multiple lines or nothing
if launcher_jar == "" then
    -- Fallback or error handling if mason hasn't installed jdtls yet
    vim.notify("JDTLS launcher jar not found. Run :MasonInstall jdtls", vim.log.levels.WARN)
else
    launcher_jar = vim.split(launcher_jar, "\n")[1]
end

-- Determine OS config
local config_path = mason_path .. "/packages/jdtls/config_linux"
if vim.fn.has("mac") == 1 then
    config_path = mason_path .. "/packages/jdtls/config_mac"
end

return {
    name = 'jdtls',
    config = function(capabilities, on_attach)
        local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
        local workspace_dir = vim.fn.stdpath('data') .. '/jdtls-workspace/' .. project_name

        vim.lsp.config('jdtls', {
            cmd = {
                -- FIX: Use the absolute path to your Java 17 JDK.
                -- JDTLS *requires* Java 17+ to start the server process.
                home .. '/.jdks/jbr-17.0.14/bin/java',
                
                '-Declipse.application=org.eclipse.jdt.ls.core.id1.JavaLanguageServer',
                '-Dosgi.bundles.defaultStartLevel=4',
                '-Declipse.product=org.eclipse.jdt.ls.core.product',
                '-Dlog.protocol=true',
                '-Dlog.level=ALL',
                '-Xms1g',
                '--add-modules=ALL-SYSTEM',
                '--add-opens', 'java.base/java.util=ALL-UNNAMED',
                '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
                
                '-jar', launcher_jar,
                '-configuration', config_path,
                '-data', workspace_dir,
            },
            filetypes = { 'java' },
            root_markers = {
                'settings.gradle',
                'settings.gradle.kts',
                'gradlew',
                'pom.xml',
                'build.gradle',
            },
            cmd_env = {
                -- Ensure this path is correct for your system
                ANDROID_HOME = '/mnt/IDisk/Uts/android-sdk', 
            },
            capabilities = capabilities,
            on_attach = function(client, bufnr)
                on_attach(client, bufnr)

                -- Load DAP if available
                local dap_ok, dap = pcall(require, 'dap')
                if dap_ok then
                    dap.configurations.java = {
                        {
                            type = 'java',
                            request = 'attach',
                            name = "Debug (Attach) - Android Device",
                            hostName = "localhost",
                            port = 5005,
                        },
                    }
                end
            end,
            settings = {
                java = {
                    -- This controls what version your code is COMPILING against
                    configuration = {
                        runtimes = {
                            {
                                name = "JavaSE-17",
                                path = home .. "/.jdks/jbr-17.0.14",
                                default = true,
                            },
                        }
                    }
                }
            },
        })
    end
}
