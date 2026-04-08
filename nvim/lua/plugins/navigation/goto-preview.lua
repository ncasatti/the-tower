return {
  'rmagatti/goto-preview',
  config = function()
    require('goto-preview').setup {
      width = 120,
      height = 15,
      border = {"↖", "─" ,"┐", "│", "┘", "─", "└", "│"},
       default_mappings = false,
      debug = false,
      opacity = nil,
      resizing_mappings = false,
      post_open_hook = nil,
      -- references configuration removed (Telescope dependency)
      focus_on_open = true,
      dismiss_on_move = false,
      force_close = true,
      bufhidden = "wipe",
      stack_floating_preview_windows = true,
       preview_window_title = { enable = true, position = "left" },
     }

     -- Custom keymaps (gz* prefix instead of gp*)
     vim.keymap.set("n", "gpp", "<cmd>lua require('goto-preview').goto_preview_definition()<CR>", { desc = "Preview definition" })
     vim.keymap.set("n", "gpt", "<cmd>lua require('goto-preview').goto_preview_type_definition()<CR>", { desc = "Preview type definition" })
     vim.keymap.set("n", "gpi", "<cmd>lua require('goto-preview').goto_preview_implementation()<CR>", { desc = "Preview implementation" })
     vim.keymap.set("n", "gpr", "<cmd>lua require('goto-preview').goto_preview_references()<CR>", { desc = "Preview references" })
     vim.keymap.set("n", "gpz", "<cmd>lua require('goto-preview').close_all_win()<CR>", { desc = "Close all preview windows" })
   end
}
