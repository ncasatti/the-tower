-- Zettelkasten templates loader — lazy.nvim spec.
--
-- The implementation lives at lua/zettelkasten/templates.lua (kept out of
-- plugins/ so lazy's { import = "plugins.writing" } does not try to load
-- the modules as plugin specs). Same pattern as TaskNotes — see CLAUDE.md.

return {
  "L3MON4D3/LuaSnip",
  event = "VeryLazy",
  config = function()
    local templates = require("zettelkasten.templates")
    templates.reload()

    -- Auto-reload when a file inside Templates/ is saved (BufWritePost fires
    -- even if you're editing the template from a different buffer context)
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = "*.md",
      callback = function(args)
        local path = vim.fn.fnamemodify(args.file, ":p")
        local tpl_dir = vim.fn.expand("~/.the-grid/zettelkasten/Templates/")
        if path:sub(1, #tpl_dir) == tpl_dir then
          templates.reload()
        end
      end,
    })

    -- Manual reload command (also chained into <leader>or)
    vim.api.nvim_create_user_command("ReloadTemplates", function()
      templates.reload()
    end, { desc = "Reload Zettelkasten templates from disk" })
  end,
}
