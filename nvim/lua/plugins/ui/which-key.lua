-- This file contains the configuration for the which-key.nvim plugin in Neovim.

return {
  -- Plugin: which-key.nvim
  -- URL: https://github.com/folke/which-key.nvim
  -- Description: A Neovim plugin that displays a popup with possible keybindings of the command you started typing.
  "folke/which-key.nvim",

  event = "VeryLazy", -- Load this plugin on the 'VeryLazy' event

  config = function()
    require("which-key").setup({
      preset = "modern", -- helix|modern|classic
      -- Hydra mode: keep which-key open for window commands
      show = {
        keys = '<c-w>',
        loop = true,
      },
    })
  end,

  init = function()
    -- Set the timeout for key sequences
    vim.o.timeout = true
    vim.o.timeoutlen = 500 -- Reduced for faster Colemak navigation response
  end,

  keys = {
    {
      -- Keybinding to show which-key popup
      "<leader>?",
      function()
        require("which-key").show({ global = false }) -- Show the which-key popup for local keybindings
      end,
    },
    {
      -- Define a group for Obsidian-related commands
      "<leader>o",
      group = "Obsidian",
    },
  },
}
