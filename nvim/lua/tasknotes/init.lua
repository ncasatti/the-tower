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
local wk = require("which-key")

local M = {}

-- Registers the <leader>o* keymaps (shared namespace with obsidian — see
-- docs/keys/writing.md). Tasks take single keys; the four obsidian bindings
-- we displaced (Search/New note/Template/Rename) moved to Shift variants
-- (<leader>oS / oN / oT / oR). All mutations route through the multi-field
-- editor (`oe`); per-field singles were collapsed into it.
--
-- `bind()` registers each binding twice: `vim.keymap.set` for the actual
-- mapping, `wk.add` for which-key's display metadata (icon + desc).
-- which-key ignores the `icon` field of `vim.keymap.set` opts, so we have
-- to feed it explicitly through `wk.add`.
local function register_keymaps()
	local function bind(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { desc = desc })
		wk.add({ { lhs, desc = desc, icon = config.keymap_icon } })
	end

	-- Search + filtering
	bind("<leader>ok", pickers.pick_key, "Task: Search by frontmatter key")
	bind("<leader>or", function()
		cache.force_refresh()
		templates.reload()
	end, "Task: Force cache rebuild + reload templates")
	bind("<leader>os", pickers.pick_file_by_status, "Task: Filter by status")
	bind("<leader>ow", pickers.pick_file_by_tag, "Task: Filter by tag/project")
	bind("<leader>ot", pickers.note_search, "Task: Search notes by tag (vault)")
	bind("<leader>oq", query.query_builder.open, "Task: Query builder")

	bind("<leader>on", task_ops.create_task, "Task: New")
	bind("<leader>oe", task_ops.edit_fields.open, "Task: Edit fields")
	bind("<leader>op", pomodoro.panel, "Task: Pomodoro & time tracking")
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
