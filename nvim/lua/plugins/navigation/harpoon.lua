return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup({
      settings = {
        save_on_toggle = true, -- Auto-save when you open/close the menu
        sync_on_ui_close = true, -- Sync when closing the UI
      },
    })

    -- Core Harpoon actions (using <leader>t for "travel")
    vim.keymap.set("n", "<leader>ta", function() harpoon:list():add() end, { desc = "Harpoon: Add file" })
    vim.keymap.set("n", "<leader>th", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon: Menu" })
    vim.keymap.set("n", "<leader>ty", function() harpoon:list():clear() end, { desc = "Harpoon: Clear all" })

    -- Quick navigation to marked files (using number keys 1-4)
    vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end, { desc = "Harpoon: File 1" })
    vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end, { desc = "Harpoon: File 2" })
    vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end, { desc = "Harpoon: File 3" })
    vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end, { desc = "Harpoon: File 4" })

    -- Navigate through harpoon list sequentially
    vim.keymap.set("n", "<leader>tu", function() harpoon:list():prev() end, { desc = "Harpoon: Previous" })
    vim.keymap.set("n", "<leader>tn", function() harpoon:list():next() end, { desc = "Harpoon: Next" })
  end,
}
