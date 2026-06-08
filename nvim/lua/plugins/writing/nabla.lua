-- nvim/lua/plugins/writing/nabla.lua
-- ASCII art rendering for LaTeX expressions — works in cool-retro-term.
-- Two modes: always-on inline virt-text + on-demand popup.
--
-- Note: render-markdown.nvim's anti_conceal is disabled in render-markdown.lua
-- to prevent its CursorMoved re-render cycle from clobbering nabla's marks.

return {
  "jbyuki/nabla.nvim",
  ft = { "markdown", "md", "tex", "latex", "plaintex" },
  keys = {
    {
      "<leader>mn",
      function() require("nabla").popup() end,
      ft = { "markdown", "md", "tex", "latex", "plaintex" },
      desc = "󰈎 Math popup (nabla)",
    },
    {
      "<leader>mN",
      function() require("nabla").toggle_virt() end,
      ft = { "markdown", "md", "tex", "latex", "plaintex" },
      desc = "󰈎 Toggle inline math (nabla)",
    },
  },
  config = function()
    -- Auto-enable inline rendering on markdown/tex buffers.
    -- autogen=true → regenerates on InsertLeave + TextChanged (internal autocmd).
    local function enable()
      local ok, nabla = pcall(require, "nabla")
      if not ok then return end
      if nabla.is_virt_enabled and nabla.is_virt_enabled() then return end
      pcall(nabla.enable_virt, { autogen = true })
    end

    -- Current buffer (the one that triggered the ft-lazy load).
    vim.schedule(enable)

    -- Subsequent buffer entries.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "markdown", "tex", "latex", "plaintex" },
      callback = function() vim.schedule(enable) end,
      desc = "nabla: auto-enable inline math",
    })
  end,
}
