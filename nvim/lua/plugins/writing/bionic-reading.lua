-- nvim/lua/plugins/writing/bionic-reading.lua
-- Bionic Reading: bolds the leading letters of each word to create artificial
-- fixation points, easing prose reading. Highlight-based (extmarks) — NOT a
-- font feature, so it toggles per-buffer and never touches the .ttf.
--
-- Policy:
--   * Prose filetypes (markdown/text/gitcommit) auto-highlight on open.
--   * Code is deliberately NOT in file_types, so buffers stay clean by default.
--     Use <leader>mb / :BRToggle to turn it on for the current buffer on demand.
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
    -- Auto-highlight only reading-oriented buffers; code opts in via :BRToggle.
    auto_highlight = true,
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
