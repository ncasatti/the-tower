-- Filetype detection for log files
-- Ensures treesitter-log highlighting is applied to various log file types

vim.filetype.add({
  extension = {
    log = "log",
    logcat = "log",
  },
  filename = {
    ["syslog"] = "log",
    ["messages"] = "log",
  },
  pattern = {
    ["%.log%.[%d]+$"] = "log", -- Rotated logs like app.log.1, app.log.2
    ["%.log%.%d%d%d%d%-%d%d%-%d%d$"] = "log", -- Date-stamped logs like app.log.2024-01-15
  },
})
