-- TaskNotes — Neovim client for the TaskNotes REST API.
--
-- Public entry point. The lazy spec (lua/plugins/writing/tasknotes.lua) calls
-- require("tasknotes").setup(). Implementation is split across sibling modules:
--   config   — tunables (single source of truth)
--   api      — HTTP client + API caches
--   util     — pure helpers
--   cache    — task index + whole-vault notes index
--   ui       — Snacks view, color engine, rank tables
--   pickers  — Key → Value → File drill-down + tag browser
--   task_ops — NLP create + multi-field editor
--   query    — filter builder + finder + interactive query builder
--   pomodoro — Pomodoro & time-tracking panel

local config = require("tasknotes.config")
local api = require("tasknotes.api")
local cache = require("tasknotes.cache")
local pickers = require("tasknotes.pickers")
local task_ops = require("tasknotes.task_ops")
local query = require("tasknotes.query")
local pomodoro = require("tasknotes.pomodoro")
local templates = require("zettelkasten.templates")

local M = {}

-- Registers the <leader>ow* keymaps. All mutations route through the
-- multi-field editor (`owe`); per-field singles were collapsed into it.
local function register_keymaps()
	-- Zettelkasten search + filtering
	vim.keymap.set("n", "<leader>owk", pickers.pick_key, { desc = "Search by frontmatter key" })
	vim.keymap.set("n", "<leader>owr", function()
		cache.force_refresh()
		templates.reload()
	end, { desc = "Force cache rebuild + reload templates" })
	vim.keymap.set("n", "<leader>ows", pickers.pick_file_by_status, { desc = "Filter by status" })
	vim.keymap.set("n", "<leader>owo", pickers.pick_file_by_tag, { desc = "Filter by tag/project" })
	vim.keymap.set("n", "<leader>owt", pickers.note_search, { desc = "Search notes by tag (vault)" })
	vim.keymap.set("n", "<leader>owq", query.query_builder.open, { desc = "Task: Query builder" })

	vim.keymap.set("n", "<leader>own", task_ops.create_task, { desc = "Task: New" })
	vim.keymap.set("n", "<leader>owe", task_ops.edit_fields.open, { desc = "Task: Edit fields" })
	vim.keymap.set("n", "<leader>owp", pomodoro.panel, { desc = "Pomodoro & time tracking" })
end

-- Entry point. Merges user opts into the config table IN PLACE (never
-- replaces it, so modules holding `config` see the change), then gates
-- keymap registration on a live API.
--
-- Per the API-driven directive: if /api/health does not respond at startup
-- the plugin refuses to register keymaps and notifies the user. There is no
-- file-I/O fallback for mutations.
function M.setup(opts)
	if opts then
		for k, v in pairs(opts) do
			config[k] = v
		end
	end

	if not api.health() then
		vim.notify(
			"TaskNotes API not reachable at "
				.. config.api_url
				.. "\nKeymaps NOT registered. Start the TaskNotes API server and :Lazy reload tasknotes.",
			vim.log.levels.WARN
		)
		return
	end

	register_keymaps()
end

return M
