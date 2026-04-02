-- Add Mason bin directory to PATH
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH
vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/site")

require("config.keys")
require("config.config")
require("config.lazy")

-- Cargar conexiones de bases de datos locales (si existen)
local ok, local_dbs = pcall(require, "local.databases")
if ok then
	vim.g.dbs = local_dbs
end
