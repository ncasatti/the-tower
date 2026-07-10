-- nvim/lua/plugins/writing/bionic-reading.lua
-- Bionic Reading: bolds the leading letters of each word to create artificial
-- fixation points, easing prose reading. Highlight-based (extmarks) — NOT a
-- font feature, so it toggles per-buffer and never touches the .ttf.
--
-- Policy:
--   * DISABLED by default. Bionic now ships baked into the font (3270 Bionic,
--     see docs/bionic-font.md), so this plugin is redundant and kept only as a
--     fallback. auto_highlight = false -> it never activates on its own.
--   * Turn it on for the current buffer on demand with <leader>mb / :BRToggle.
--   * To re-enable prose auto-highlight, flip auto_highlight back to true;
--     file_types below already scopes it to markdown/text/gitcommit.
--   * treesitter = true lets file_types scope to node types (e.g. only
--     "comment") if we later opt a code filetype in.

return {
  "FluxxField/bionic-reading.nvim",
  ft = { "markdown", "md", "text", "gitcommit" },
  cmd = { "BRToggle", "BRToggleAutoHighlight", "BRToggleUpdateInsertMode" },
  keys = {
    { "<leader>mb", "<cmd>BRToggle<cr>", desc = "󰈈 Toggle Bionic Reading" },
  },
  opts = {
    -- Dormant by default (font handles bionic now). Flip to true to restore
    -- prose auto-highlight. On-demand toggle via <leader>mb still works.
    auto_highlight = false,
    file_types = {
      ["markdown"] = "any",
      ["text"] = "any",
      ["gitcommit"] = "any",
    },
    -- A synthetic Bold face now ships in fonts/IBM-3270NerdMono-Bold.ttf
    -- (same family, style Bold), so kitty's `bold_font auto` renders real bold
    -- for the fixation letters — no fg color needed.
    hl_group_value = {
      bold = true,
    },
    treesitter = true,
    prompt_user = false,
    update_in_insert_mode = false,
  },
  config = function(_, opts)
    require("bionic-reading").setup(opts)
  end,
}
