-- Android ADB Helper Functions
-- Provides device management and app operation utilities
-- This file is loaded automatically by Neovim from the plugin/ directory

local M = {}

-- Get package name from AndroidManifest.xml
M.get_package_name = function()
  local manifest_path = vim.fn.findfile("AndroidManifest.xml", ".;")
  if manifest_path == "" then
    return nil, "AndroidManifest.xml not found"
  end

  local manifest = vim.fn.readfile(manifest_path)
  for _, line in ipairs(manifest) do
    local match = line:match('package="([^"]+)"')
    if match then
      return match, nil
    end
  end

  return nil, "Could not find package name in manifest"
end

-- Check if device is connected
M.check_device = function()
  local result = vim.fn.system("adb devices | grep -w 'device' | wc -l")
  local count = tonumber(result)
  return count and count > 0
end

-- Get connected devices
M.get_devices = function()
  local output = vim.fn.system("adb devices -l")
  vim.notify(output, vim.log.levels.INFO)
end

-- Install APK
M.install_apk = function(apk_path)
  if not M.check_device() then
    vim.notify("No device connected", vim.log.levels.ERROR)
    return
  end

  if not apk_path then
    apk_path = vim.fn.input("APK path: ", "", "file")
    if apk_path == "" then
      return
    end
  end

  vim.notify("Installing APK...", vim.log.levels.INFO)
  local result = vim.fn.system("adb install -r " .. vim.fn.shellescape(apk_path))

  if vim.v.shell_error == 0 then
    vim.notify("APK installed successfully", vim.log.levels.INFO)
  else
    vim.notify("Failed to install APK:\n" .. result, vim.log.levels.ERROR)
  end
end

-- Uninstall app
M.uninstall_app = function()
  if not M.check_device() then
    vim.notify("No device connected", vim.log.levels.ERROR)
    return
  end

  local package_name, err = M.get_package_name()
  if not package_name then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  vim.notify("Uninstalling " .. package_name .. "...", vim.log.levels.INFO)
  local result = vim.fn.system("adb uninstall " .. package_name)

  if vim.v.shell_error == 0 then
    vim.notify("App uninstalled successfully", vim.log.levels.INFO)
  else
    vim.notify("Failed to uninstall app:\n" .. result, vim.log.levels.ERROR)
  end
end

-- Clear app data
M.clear_app_data = function()
  if not M.check_device() then
    vim.notify("No device connected", vim.log.levels.ERROR)
    return
  end

  local package_name, err = M.get_package_name()
  if not package_name then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  vim.notify("Clearing data for " .. package_name .. "...", vim.log.levels.INFO)
  local result = vim.fn.system("adb shell pm clear " .. package_name)

  if vim.v.shell_error == 0 then
    vim.notify("App data cleared successfully", vim.log.levels.INFO)
  else
    vim.notify("Failed to clear app data:\n" .. result, vim.log.levels.ERROR)
  end
end

-- Start app
M.start_app = function()
  if not M.check_device() then
    vim.notify("No device connected", vim.log.levels.ERROR)
    return
  end

  local package_name, err = M.get_package_name()
  if not package_name then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  vim.notify("Starting " .. package_name .. "...", vim.log.levels.INFO)
  local result = vim.fn.system("adb shell monkey -p " .. package_name .. " -c android.intent.category.LAUNCHER 1")

  if vim.v.shell_error == 0 then
    vim.notify("App started successfully", vim.log.levels.INFO)
  else
    vim.notify("Failed to start app:\n" .. result, vim.log.levels.ERROR)
  end
end

-- Stop app
M.stop_app = function()
  if not M.check_device() then
    vim.notify("No device connected", vim.log.levels.ERROR)
    return
  end

  local package_name, err = M.get_package_name()
  if not package_name then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  vim.notify("Stopping " .. package_name .. "...", vim.log.levels.INFO)
  local result = vim.fn.system("adb shell am force-stop " .. package_name)

  if vim.v.shell_error == 0 then
    vim.notify("App stopped successfully", vim.log.levels.INFO)
  else
    vim.notify("Failed to stop app:\n" .. result, vim.log.levels.ERROR)
  end
end

-- Restart app
M.restart_app = function()
  M.stop_app()
  vim.defer_fn(function()
    M.start_app()
  end, 500)
end

-- Enable debugging for current app
M.enable_debug = function()
  if not M.check_device() then
    vim.notify("No device connected", vim.log.levels.ERROR)
    return
  end

  local package_name, err = M.get_package_name()
  if not package_name then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  vim.notify("Starting app in debug mode on port 5005...", vim.log.levels.INFO)

  -- First, stop the app if it's running
  vim.fn.system("adb shell am force-stop " .. package_name)

  -- Start app with debugging enabled
  local result = vim.fn.system(
    "adb shell am start -D -n " .. package_name .. "/$(adb shell cmd package resolve-activity --brief " .. package_name .. " | tail -n 1)"
  )

  -- Forward debug port
  vim.fn.system("adb forward tcp:5005 jdwp:$(adb shell pidof -s " .. package_name .. ")")

  if vim.v.shell_error == 0 then
    vim.notify("App started in debug mode. Connect debugger to localhost:5005", vim.log.levels.INFO)
  else
    vim.notify("Failed to start app in debug mode:\n" .. result, vim.log.levels.ERROR)
  end
end

-- Keybindings for ADB helpers
vim.keymap.set("n", "<leader>ad", function()
  M.get_devices()
end, { desc = "Android: List Devices" })

vim.keymap.set("n", "<leader>ai", function()
  M.install_apk()
end, { desc = "Android: Install APK" })

vim.keymap.set("n", "<leader>au", function()
  M.uninstall_app()
end, { desc = "Android: Uninstall App" })

vim.keymap.set("n", "<leader>aD", function()
  M.clear_app_data()
end, { desc = "Android: Clear App Data" })

vim.keymap.set("n", "<leader>as", function()
  M.start_app()
end, { desc = "Android: Start App" })

vim.keymap.set("n", "<leader>aS", function()
  M.stop_app()
end, { desc = "Android: Stop App" })

vim.keymap.set("n", "<leader>ar", function()
  M.restart_app()
end, { desc = "Android: Restart App" })

vim.keymap.set("n", "<leader>adb", function()
  M.enable_debug()
end, { desc = "Android: Enable Debug Mode" })

-- Store module globally for access from other files
_G.AndroidADB = M
