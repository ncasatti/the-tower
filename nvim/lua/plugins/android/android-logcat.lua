-- Android Logcat Viewer
-- Provides logcat viewing and filtering capabilities in Neovim
-- This file is loaded automatically by Neovim from the plugin/ directory

local M = {}
local logcat_term = nil

-- Function to open logcat in a terminal buffer
M.open_logcat = function(filter)
  -- Check if toggleterm is available
  local has_toggleterm, Terminal_mod = pcall(require, "toggleterm.terminal")

  if not has_toggleterm then
    vim.notify("toggleterm.nvim not installed. Please install it first.", vim.log.levels.ERROR)
    return
  end

  local Terminal = Terminal_mod.Terminal

  local cmd = "adb logcat"
  if filter then
    cmd = cmd .. " " .. filter
  end

  logcat_term = Terminal:new({
    cmd = cmd,
    hidden = false,
    direction = "float",
    float_opts = {
      border = "rounded",
      width = math.floor(vim.o.columns * 0.9),
      height = math.floor(vim.o.lines * 0.9),
    },
    on_open = function(term)
      vim.cmd("startinsert!")
      -- Map q to close in normal mode
      vim.keymap.set("n", "q", function()
        term:close()
      end, { buffer = term.bufnr, nowait = true, silent = true })
      -- Map <Esc> to close
      vim.keymap.set("n", "<Esc>", function()
        term:close()
      end, { buffer = term.bufnr, nowait = true, silent = true })
    end,
    on_close = function()
      logcat_term = nil
    end,
  })

  logcat_term:toggle()
end

-- Function to clear logcat
M.clear_logcat = function()
  vim.fn.system("adb logcat -c")
  vim.notify("Logcat cleared", vim.log.levels.INFO)
end

-- Function to open logcat with error filter
M.open_logcat_errors = function()
  M.open_logcat("*:E")
end

-- Function to open logcat with warning filter
M.open_logcat_warnings = function()
  M.open_logcat("*:W")
end

-- Function to open logcat with custom filter
M.open_logcat_custom = function()
  local filter = vim.fn.input("Logcat filter (e.g., tag:level): ")
  if filter ~= "" then
    M.open_logcat(filter)
  end
end

-- Function to open logcat for current package
M.open_logcat_package = function()
  -- Try to get package name from AndroidManifest.xml
  local manifest_path = vim.fn.findfile("AndroidManifest.xml", ".;")
  if manifest_path == "" then
    vim.notify("AndroidManifest.xml not found", vim.log.levels.WARN)
    return
  end

  local manifest = vim.fn.readfile(manifest_path)
  local package_name = nil
  for _, line in ipairs(manifest) do
    local match = line:match('package="([^"]+)"')
    if match then
      package_name = match
      break
    end
  end

  if package_name then
    M.open_logcat("--pid=$(adb shell pidof -s " .. package_name .. ")")
  else
    vim.notify("Could not find package name in manifest", vim.log.levels.WARN)
  end
end

-- Keybindings for logcat
vim.keymap.set("n", "<leader>al", function()
  M.open_logcat()
end, { desc = "Android: Logcat (All)" })

vim.keymap.set("n", "<leader>ae", function()
  M.open_logcat_errors()
end, { desc = "Android: Logcat (Errors)" })

vim.keymap.set("n", "<leader>aw", function()
  M.open_logcat_warnings()
end, { desc = "Android: Logcat (Warnings)" })

vim.keymap.set("n", "<leader>ac", function()
  M.clear_logcat()
end, { desc = "Android: Clear Logcat" })

vim.keymap.set("n", "<leader>ap", function()
  M.open_logcat_package()
end, { desc = "Android: Logcat (Current Package)" })

vim.keymap.set("n", "<leader>af", function()
  M.open_logcat_custom()
end, { desc = "Android: Logcat (Custom Filter)" })

-- Store module globally for access from other files
_G.AndroidLogcat = M
