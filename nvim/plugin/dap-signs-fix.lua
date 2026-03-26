-- Force DAP signs to be defined after startup
-- This ensures signs are available even if something clears them

vim.api.nvim_create_autocmd("VimEnter", {
  pattern = "*",
  callback = function()
    -- Wait a bit for all plugins to load
    vim.defer_fn(function()
      -- Define DAP signs
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
      vim.fn.sign_define("DapLogPoint", { text = "◉", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "→", texthl = "DiagnosticOk", linehl = "DapStoppedLine", numhl = "" })
      
      -- Define highlights
      vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#2a3a2a" })
      vim.api.nvim_set_hl(0, "DapBreakpoint", { link = "DiagnosticError" })
      vim.api.nvim_set_hl(0, "DapBreakpointCondition", { link = "DiagnosticWarn" })
      
      -- Silent mode - no print message
      -- print("DAP signs redefined")
    end, 100) -- 100ms delay
  end,
})
