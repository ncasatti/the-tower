return {
  'fei6409/log-highlight.nvim',
  config = function()
    require('log-highlight').setup({
      -- File extension to highlight
      extension = 'log',

      -- Additional filename patterns to highlight
      filename = {
        'syslog',
        'messages',
      },

      -- Patterns to match log files (for files without .log extension)
      pattern = {
        '/var/log/.*',      -- System logs
        '%.logcat$',        -- Android logcat files
        '%.log%.[%d]+$',    -- Rotated logs (app.log.1, app.log.2)
      },
    })
  end,
}
