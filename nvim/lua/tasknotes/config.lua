-- TaskNotes — configuration (single source of truth)
--
-- This table is the tunable surface. `init.setup(opts)` MUTATES it in place
-- (never replaces it) so every module that did `local config = require(...)`
-- sees the merged values.

local M = {
	vault_path = vim.fn.expand("~/.the-grid/zettelkasten"),
	tasks_folder = "TaskNotes/Tasks",
	api_url = "http://localhost:8080/api",
	cache_ttl = 30, -- seconds, applies to local frontmatter cache only
	-- Defaults for NLP-driven create_task when parser doesn't provide them.
	-- Live statuses/priorities are pulled from /api/filter-options.
	default_status = "inbox",
	default_priority = "normal",
	-- Optional override for the pomodoro WORK length (minutes). Left nil so
	-- the TaskNotes plugin uses its own configured length. Breaks are
	-- always server-managed (auto short/long-break), so only work applies.
	pomodoro_minutes = nil,

	-- Row rendering (search pickers). The status GLYPH is user-tunable here;
	-- its COLOR still comes live from /api/filter-options, so custom icons and
	-- live colors coexist. (The API `icon` field is a Lucide *name*, not a
	-- glyph — unusable in a terminal — so this local map replaces it.)
	-- Keys are status `value`s; unmapped statuses fall back to default_icon.
	status_icons = {
		inbox = "",
		["in-progress"] = "",
		["on-hold"] = "󰦖",
		waiting = "",
		done = "",
	},
	default_icon = "●", -- status fallback (universal, no Nerd Font needed)
	priority_icon = "●", -- the priority marker (colored by priority)

	-- Icon shown next to each task binding in which-key's <leader>o* group.
	-- Single source of truth — change here and all 9 task keymaps pick it up.
	-- Read by init.lua's `bind()` helper, which passes it to `wk.add` (the
	-- `icon` field of `vim.keymap.set` opts is silently ignored by which-key).
	keymap_icon = " ",
}

return M
