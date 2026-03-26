-- Android Build Helper Functions
-- Provides quick workflows for building, installing, and running Android apps
-- This file is loaded automatically by Neovim from the plugin/ directory

local M = {}

-- Find the built APK path
M.find_apk = function(build_type)
  build_type = build_type or "debug"
  local apk_path = vim.fn.glob("app/build/outputs/apk/" .. build_type .. "/*.apk")

  if apk_path == "" then
    -- Try alternative path structure
    apk_path = vim.fn.glob("build/outputs/apk/" .. build_type .. "/*.apk")
  end

  if apk_path == "" then
    return nil, "APK not found. Build the project first."
  end

  -- If multiple APKs found, take the first one
  local apks = vim.split(apk_path, "\n")
  return apks[1], nil
end

-- Build debug APK
M.build_debug = function()
  vim.notify("Building debug APK...", vim.log.levels.INFO)
  if _G.Gradle then
    _G.Gradle.exec_task("assembleDebug")
  else
    vim.cmd("GradleExec assembleDebug")
  end
end

-- Build release APK
M.build_release = function()
  vim.notify("Building release APK...", vim.log.levels.INFO)
  if _G.Gradle then
    _G.Gradle.exec_task("assembleRelease")
  else
    vim.cmd("GradleExec assembleRelease")
  end
end

-- Build and install debug APK
M.build_install_debug = function()
  vim.notify("Building and installing debug APK...", vim.log.levels.INFO)
  if _G.Gradle then
    _G.Gradle.exec_task("installDebug")
  else
    vim.cmd("GradleExec installDebug")
  end
end

-- Build, install, and run debug APK
M.build_install_run_debug = function()
  -- Check if device is connected
  if not _G.AndroidADB or not _G.AndroidADB.check_device() then
    vim.notify("No device connected", vim.log.levels.ERROR)
    return
  end

  vim.notify("Building, installing, and running debug APK...", vim.log.levels.INFO)

  -- Build and install
  if _G.Gradle then
    _G.Gradle.exec_task("installDebug")
  else
    vim.cmd("GradleExec installDebug")
  end

  -- Wait for installation to complete, then start the app
  vim.defer_fn(function()
    if _G.AndroidADB then
      _G.AndroidADB.start_app()
    end
  end, 2000)
end

-- Build, install, and debug
M.build_install_debug_mode = function()
  -- Check if device is connected
  if not _G.AndroidADB or not _G.AndroidADB.check_device() then
    vim.notify("No device connected", vim.log.levels.ERROR)
    return
  end

  vim.notify("Building, installing, and starting in debug mode...", vim.log.levels.INFO)

  -- Build and install
  if _G.Gradle then
    _G.Gradle.exec_task("installDebug")
  else
    vim.cmd("GradleExec installDebug")
  end

  -- Wait for installation to complete, then enable debug
  vim.defer_fn(function()
    if _G.AndroidADB then
      _G.AndroidADB.enable_debug()
      vim.notify("Ready to attach debugger. Press F5 to start debugging.", vim.log.levels.INFO)
    end
  end, 2000)
end

-- Quick rebuild (clean + build)
M.quick_rebuild = function()
  vim.notify("Cleaning and rebuilding...", vim.log.levels.INFO)
  if _G.Gradle then
    _G.Gradle.exec_task("clean assembleDebug")
  else
    vim.cmd("GradleExec clean assembleDebug")
  end
end

-- Install existing APK
M.install_existing_apk = function(build_type)
  build_type = build_type or "debug"

  if not _G.AndroidADB or not _G.AndroidADB.check_device() then
    vim.notify("No device connected", vim.log.levels.ERROR)
    return
  end

  local apk_path, err = M.find_apk(build_type)
  if not apk_path then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  vim.notify("Installing " .. vim.fn.fnamemodify(apk_path, ":t") .. "...", vim.log.levels.INFO)

  if _G.AndroidADB then
    _G.AndroidADB.install_apk(apk_path)
  end
end

-- Run without rebuild (if APK exists)
M.run_existing = function()
  if not _G.AndroidADB or not _G.AndroidADB.check_device() then
    vim.notify("No device connected", vim.log.levels.ERROR)
    return
  end

  -- Check if APK exists
  local apk_path, err = M.find_apk("debug")
  if not apk_path then
    vim.notify("No built APK found. Build the project first.", vim.log.levels.WARN)
    return
  end

  if _G.AndroidADB then
    _G.AndroidADB.start_app()
  end
end

-- Keybindings for build helpers
vim.keymap.set("n", "<leader>ab", function()
  M.build_debug()
end, { desc = "Android: Build Debug" })

vim.keymap.set("n", "<leader>aB", function()
  M.build_release()
end, { desc = "Android: Build Release" })

vim.keymap.set("n", "<leader>aI", function()
  M.build_install_debug()
end, { desc = "Android: Build & Install Debug" })

vim.keymap.set("n", "<leader>aR", function()
  M.build_install_run_debug()
end, { desc = "Android: Build, Install & Run" })

vim.keymap.set("n", "<leader>aDb", function()
  M.build_install_debug_mode()
end, { desc = "Android: Build, Install & Debug" })

vim.keymap.set("n", "<leader>aq", function()
  M.quick_rebuild()
end, { desc = "Android: Quick Rebuild (Clean + Build)" })

vim.keymap.set("n", "<leader>ax", function()
  M.install_existing_apk("debug")
end, { desc = "Android: Install Existing APK" })

vim.keymap.set("n", "<leader>aX", function()
  M.run_existing()
end, { desc = "Android: Run Existing App" })

-- Store module globally for access from other files
_G.AndroidBuild = M
