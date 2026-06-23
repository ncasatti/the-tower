-- nvim/lua/plugins/writing/nabla.lua
-- Text fallback for LaTeX math: ASCII-art rendering for terminals without
-- image support (e.g. cool-retro-term).
--
-- In kitty, snacks.image renders math as real images, so nabla's inline
-- auto-render stays OFF and only the on-demand keymaps remain (popup +
-- toggle) as a manual fallback. The image-vs-text decision lives in
-- util/term.lua (has_image()); render-markdown.nvim's anti_conceal follows
-- the same switch.

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
    -- Image-capable terminal (kitty): snacks.image owns inline math.
    -- Skip nabla's auto-inline entirely — the popup/toggle keymaps above
    -- stay available as a manual fallback. Only text-only terminals fall
    -- through to the inline ASCII renderer below.
    if require("util.term").has_image() then
      return
    end

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
