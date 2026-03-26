-- Auto-detect Jupyter notebooks and convert to Python with Jupytext
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  pattern = "*.ipynb",
  callback = function()
    -- Set filetype to jupyter (not json)
    vim.bo.filetype = "jupyter"
    
    -- Trigger Jupytext conversion
    vim.schedule(function()
      local has_jupytext, jupytext = pcall(require, "jupytext")
      if has_jupytext then
        -- Jupytext will handle the conversion
        vim.cmd("edit")
      else
        vim.notify("Jupytext not loaded. Install jupytext CLI.", vim.log.levels.WARN)
      end
    end)
  end,
})
