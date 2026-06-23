-- nvim/lua/util/term.lua
-- Terminal capability detection — single source of truth for "can this
-- terminal render images via the kitty graphics protocol".
--
-- Drives the LaTeX-math rendering strategy across plugins:
--   image-capable (kitty) → snacks.image renders math as real images;
--                           nabla.nvim stays an on-demand popup fallback.
--   text-only (cool-retro-term) → nabla.nvim renders inline ASCII-art math.
--
-- Consumers: plugins/snacks/init.lua (enable image rendering),
--            plugins/writing/nabla.lua (text-only auto-inline fallback).
local M = {}

--- True when running inside kitty, including through a tmux session.
--- kitty exports KITTY_WINDOW_ID; the tmux server inherits it, so it is
--- present in panes even though TERM is rewritten to xterm-256color.
--- cool-retro-term sets neither KITTY_WINDOW_ID nor TERM=xterm-kitty.
---@return boolean
function M.has_image()
  return vim.env.TERM == "xterm-kitty" or vim.env.KITTY_WINDOW_ID ~= nil
end

return M
