-- Gradle build system integration for Android development
-- This file is loaded automatically by Neovim from the plugin/ directory

local M = {}

-- Find Gradle project root (where settings.gradle or build.gradle is)
M.find_gradle_root = function()
  -- Try to find settings.gradle first (multi-module projects)
  local settings_gradle = vim.fn.findfile("settings.gradle", ".;")
  if settings_gradle ~= "" then
    return vim.fn.fnamemodify(settings_gradle, ":p:h")
  end

  -- Try settings.gradle.kts (Kotlin DSL)
  local settings_gradle_kts = vim.fn.findfile("settings.gradle.kts", ".;")
  if settings_gradle_kts ~= "" then
    return vim.fn.fnamemodify(settings_gradle_kts, ":p:h")
  end

  -- Fallback to build.gradle
  local build_gradle = vim.fn.findfile("build.gradle", ".;")
  if build_gradle ~= "" then
    return vim.fn.fnamemodify(build_gradle, ":p:h")
  end

  -- Return current directory if no Gradle files found
  return vim.fn.getcwd()
end

-- Find gradlew in the Gradle project root
M.find_gradlew = function()
  -- Find the Gradle project root
  local gradle_root = M.find_gradle_root()

  -- Look for gradlew in the Gradle root
  local gradlew_path = gradle_root .. "/gradlew"

  if vim.fn.filereadable(gradlew_path) == 1 then
    -- Make gradlew executable if it isn't already
    vim.fn.system("chmod +x " .. vim.fn.shellescape(gradlew_path))

    return gradlew_path
  end

  -- Fallback to global gradle if gradlew not found
  return "gradle"
end

-- Execute Gradle task in a terminal window
M.exec_task = function(task)
  local gradlew = M.find_gradlew()
  local cmd = gradlew .. " " .. task

  -- Use toggleterm if available, otherwise use built-in terminal
  local has_toggleterm, toggleterm = pcall(require, "toggleterm.terminal")
  if has_toggleterm then
    local Terminal = toggleterm.Terminal
    local gradle_term = Terminal:new({
      cmd = cmd,
      direction = "float",
      close_on_exit = false,
      float_opts = {
        border = "rounded",
      },
      on_open = function(term)
        vim.cmd("startinsert!")
      end,
    })
    gradle_term:toggle()
  else
    -- Fallback to built-in terminal
    vim.cmd("split | terminal " .. cmd)
  end
end

-- Show available Gradle tasks
M.show_tasks = function()
  M.exec_task("tasks --all")
end

-- Prompt for custom task
M.custom_task = function()
  local task = vim.fn.input("Gradle task: ")
  if task ~= "" then
    M.exec_task(task)
  end
end

-- Fix gradlew permissions
M.fix_gradlew_permissions = function()
  local gradle_root = M.find_gradle_root()
  local gradlew_path = gradle_root .. "/gradlew"

  if vim.fn.filereadable(gradlew_path) ~= 1 then
    vim.notify("gradlew not found at: " .. gradlew_path, vim.log.levels.ERROR)
    return
  end

  vim.fn.system("chmod +x " .. vim.fn.shellescape(gradlew_path))

  if vim.v.shell_error == 0 then
    vim.notify("Made gradlew executable: " .. gradlew_path, vim.log.levels.INFO)
  else
    vim.notify("Failed to make gradlew executable", vim.log.levels.ERROR)
  end
end

-- Create Ex commands
vim.api.nvim_create_user_command("GradleExec", function(opts)
  M.exec_task(opts.args)
end, { nargs = "+", desc = "Execute Gradle task" })

vim.api.nvim_create_user_command("GradleTasks", function()
  M.show_tasks()
end, { desc = "Show all Gradle tasks" })

vim.api.nvim_create_user_command("GradleFixPermissions", function()
  M.fix_gradlew_permissions()
end, { desc = "Make gradlew executable" })

vim.api.nvim_create_user_command("GradleWhich", function()
  local gradlew = M.find_gradlew()
  local gradle_root = M.find_gradle_root()
  vim.notify("Gradle root: " .. gradle_root .. "\nUsing: " .. gradlew, vim.log.levels.INFO)
end, { desc = "Show which gradlew will be used" })

-- Keybindings for common Gradle tasks (Android-optimized)
vim.keymap.set("n", "<leader>gb", function()
  M.exec_task("build")
end, { desc = "Gradle: Build" })

vim.keymap.set("n", "<leader>gc", function()
  M.exec_task("clean")
end, { desc = "Gradle: Clean" })

vim.keymap.set("n", "<leader>gr", function()
  -- For Android projects, installDebug is more useful than "run"
  M.exec_task("installDebug")
end, { desc = "Gradle: Install & Run Debug" })

vim.keymap.set("n", "<leader>gt", function()
  M.exec_task("test")
end, { desc = "Gradle: Test" })

vim.keymap.set("n", "<leader>gd", function()
  M.exec_task("assembleDebug")
end, { desc = "Gradle: Assemble Debug" })

vim.keymap.set("n", "<leader>gR", function()
  M.exec_task("assembleRelease")
end, { desc = "Gradle: Assemble Release" })

vim.keymap.set("n", "<leader>gi", function()
  M.exec_task("installDebug")
end, { desc = "Gradle: Install Debug" })

vim.keymap.set("n", "<leader>gI", function()
  M.exec_task("installRelease")
end, { desc = "Gradle: Install Release" })

vim.keymap.set("n", "<leader>gu", function()
  M.exec_task("uninstallDebug")
end, { desc = "Gradle: Uninstall Debug" })

vim.keymap.set("n", "<leader>gU", function()
  M.exec_task("uninstallRelease")
end, { desc = "Gradle: Uninstall Release" })

vim.keymap.set("n", "<leader>gs", function()
  M.show_tasks()
end, { desc = "Gradle: Show Tasks" })

vim.keymap.set("n", "<leader>gx", function()
  M.custom_task()
end, { desc = "Gradle: Execute Custom Task" })

-- Store module globally for access from other files
_G.Gradle = M
