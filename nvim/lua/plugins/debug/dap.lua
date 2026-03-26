-- Debug Adapter Protocol (DAP) configuration
-- Provides debugging support for Java/Kotlin Android development
return {
  -- Core DAP plugin
  {
    "mfussenegger/nvim-dap",
    lazy = false, -- Load immediately to ensure signs are defined
    priority = 1000, -- Load before other plugins
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio", -- Required for nvim-dap-ui
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- Setup DAP UI with auto-open behavior
      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
        mappings = {
          -- Use colemak-friendly navigation in DAP UI
          expand = { "<CR>", "<2-LeftMouse>" },
          open = "o",
          remove = "d",
          edit = "l", -- 'l' enters insert mode (remapped from 'i')
          repl = "r",
          toggle = "t",
        },
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.40 },
              { id = "breakpoints", size = 0.20 },
              { id = "stacks", size = 0.20 },
              { id = "watches", size = 0.20 },
            },
            size = 40,
            position = "left",
          },
          {
            elements = {
              { id = "repl", size = 0.5 },
              { id = "console", size = 0.5 },
            },
            size = 10,
            position = "bottom",
          },
        },
        controls = {
          enabled = true,
          element = "repl",
          icons = {
            pause = "",
            play = "",
            step_into = "",
            step_over = "",
            step_out = "",
            step_back = "",
            run_last = "↻",
            terminate = "□",
          },
        },
        floating = {
          max_height = nil,
          max_width = nil,
          border = "rounded",
          mappings = {
            close = { "q", "<Esc>" },
          },
        },
        windows = { indent = 1 },
        render = {
          max_type_length = nil,
          max_value_lines = 100,
        },
      })

      -- Setup virtual text (shows variable values inline)
      require("nvim-dap-virtual-text").setup({
        enabled = true,
        enabled_commands = true,
        highlight_changed_variables = true,
        highlight_new_as_changed = false,
        show_stop_reason = true,
        commented = false,
        only_first_definition = true,
        all_references = false,
        filter_references_pattern = "<module",
        virt_text_pos = "eol",
        all_frames = false,
        virt_lines = false,
        virt_text_win_col = nil,
      })

      -- Auto-open DAP UI when debugging starts
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      -- F-key debug keybindings (traditional debugger keys)
      vim.keymap.set("n", "<F5>", function()
        dap.continue()
      end, { desc = "Debug: Continue" })

      vim.keymap.set("n", "<F6>", function()
        dap.pause()
      end, { desc = "Debug: Pause" })

      vim.keymap.set("n", "<F9>", function()
        dap.toggle_breakpoint()
      end, { desc = "Debug: Toggle Breakpoint" })

      vim.keymap.set("n", "<F10>", function()
        dap.step_over()
      end, { desc = "Debug: Step Over" })

      vim.keymap.set("n", "<F11>", function()
        dap.step_into()
      end, { desc = "Debug: Step Into" })

      vim.keymap.set("n", "<F12>", function()
        dap.step_out()
      end, { desc = "Debug: Step Out" })

      -- Additional debug keybindings with leader
      vim.keymap.set("n", "<leader>db", function()
        dap.toggle_breakpoint()
      end, { desc = "Debug: Toggle Breakpoint" })

      vim.keymap.set("n", "<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "Debug: Set Conditional Breakpoint" })

      vim.keymap.set("n", "<leader>dc", function()
        dap.continue()
      end, { desc = "Debug: Continue" })

      vim.keymap.set("n", "<leader>dC", function()
        dap.run_to_cursor()
      end, { desc = "Debug: Run to Cursor" })

      vim.keymap.set("n", "<leader>di", function()
        dap.step_into()
      end, { desc = "Debug: Step Into" })

      vim.keymap.set("n", "<leader>do", function()
        dap.step_over()
      end, { desc = "Debug: Step Over" })

      vim.keymap.set("n", "<leader>dO", function()
        dap.step_out()
      end, { desc = "Debug: Step Out" })

      vim.keymap.set("n", "<leader>dr", function()
        dap.repl.toggle()
      end, { desc = "Debug: Toggle REPL" })

      vim.keymap.set("n", "<leader>dl", function()
        dap.run_last()
      end, { desc = "Debug: Run Last" })

      vim.keymap.set("n", "<leader>dt", function()
        dap.terminate()
      end, { desc = "Debug: Terminate" })

      vim.keymap.set("n", "<leader>du", function()
        dapui.toggle()
      end, { desc = "Debug: Toggle UI" })

      vim.keymap.set({ "n", "v" }, "<leader>de", function()
        dapui.eval()
      end, { desc = "Debug: Evaluate Expression" })

      vim.keymap.set("n", "<leader>dh", function()
        require("dap.ui.widgets").hover()
      end, { desc = "Debug: Hover Variables" })

      vim.keymap.set("n", "<leader>dp", function()
        require("dap.ui.widgets").preview()
      end, { desc = "Debug: Preview" })

      -- DAP signs (gutter icons)
      -- Define signs with text fallback for compatibility
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
      vim.fn.sign_define("DapLogPoint", { text = "◉", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "→", texthl = "DiagnosticOk", linehl = "DapStoppedLine", numhl = "" })

      -- Highlight current line during debugging
      vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#2a3a2a" })
      
      -- Force define highlights to ensure they exist
      vim.api.nvim_set_hl(0, "DapBreakpoint", { link = "DiagnosticError" })
      vim.api.nvim_set_hl(0, "DapBreakpointCondition", { link = "DiagnosticWarn" })

      -- Setup Java/Kotlin debug configurations globally
      -- These will work even if JDTLS hasn't attached yet
      dap.configurations.java = {
        {
          type = 'java',
          request = 'attach',
          name = "Debug (Attach) - Android Device",
          hostName = "localhost",
          port = 5005,
        },
        {
          type = 'java',
          request = 'attach',
          name = "Debug (Attach) - Custom Port",
          hostName = "localhost",
          port = function()
            return vim.fn.input('Port: ', '5005')
          end,
        },
      }

      -- Kotlin uses same configurations as Java
      dap.configurations.kotlin = dap.configurations.java

      -- Configure the Java debug adapter
      dap.adapters.java = function(callback, config)
        callback({
          type = 'server',
          host = config.hostName or '127.0.0.1',
          port = config.port or 5005,
        })
      end
    end,
  },
}
