-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modular keymap setup:
--   core   - Colemak navigation remaps (i/v/n/o/t modes)
--   leader - <leader> globals: window mgmt, splits, buffer toggles
-- Plugin-specific keymaps live in each plugin spec under `keys = {}`
-- or buffer-local in `after/ftplugin/{lang}.lua`.
require("config.keys.core")
require("config.keys.leader")
