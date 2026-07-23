return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {
    -- Sessions stored under nvim's state dir, kept out of the repo
    dir = vim.fn.stdpath("state") .. "/sessions",
  },
  config = function(_, opts)
    require("persistence").setup(opts)

    -- Auto-save session on every clean exit so a crash/restart is recoverable
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = vim.api.nvim_create_augroup("persistence_save", { clear = true }),
      callback = function()
        require("persistence").save()
      end,
    })
  end,
}
