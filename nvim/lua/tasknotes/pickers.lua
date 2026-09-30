-- TaskNotes — 3-stage drill-down pickers (Key → Value → File) + shortcuts
-- + whole-vault tag browser (note_search).
--
-- The drill-down has two flavours driven by the data source:
--   - "global" (FS-scanned, all notes with frontmatter) — used by
--     <leader>ok, which the user requested be vault-wide.
--   - "tasks" (API-sourced, only TaskNotes-tagged notes) — used by the
--     <leader>os / <leader>ow shortcuts which are documented as task
--     filters and depend on live API data (status/priority metadata).
-- pick_value / pick_file take a `source` arg; pick_key is global-only.

local cache = require("tasknotes.cache")
local ui = require("tasknotes.ui")
local util = require("tasknotes.util")

local M = {}

-- Resolves the right index/data tables for a given source. Keeping this in
-- one place means the pickers don't need to know about cache internals.
local function source_tables(source)
	if source == "tasks" then
		return cache.keys_index, cache.data
	end
	return cache.global_keys_index, cache.global_data
end

-- Stage 3: Pick a file from the list matching key=value.
-- Displays filename with optional status/priority badge + time info.
-- On <CR>: opens the file. On close without confirm: back to Stage 2.
-- `source` selects "tasks" (API, status/priority metadata) or "global"
-- (FS, plain notes). Status/priority badges are best-effort — global
-- notes usually lack those fields and render as bare title rows.
function M.pick_file(key, value, from_shortcut, source)
	source = source or "global"
	local keys_index, data = source_tables(source)
	local filepaths = keys_index[key] and keys_index[key][value]
	if not filepaths or #filepaths == 0 then
		vim.notify(string.format("TaskNotes: no files found for %s = %s", key, value), vim.log.levels.WARN)
		return
	end

	local status_ranks, priority_ranks = ui.get_rank_tables()
	local status_colors, priority_colors = ui.get_color_tables()

	local items = {}
	for _, fp in ipairs(filepaths) do
		local fm = data[fp] and data[fp].fm or {}
		local title = util.task_title(fm, fp)

		local status_val = fm.status
		if type(status_val) == "table" then
			status_val = status_val[1]
		end
		local priority_val = fm.priority
		if type(priority_val) == "table" then
			priority_val = priority_val[1]
		end

		local time_info, time_hl = (source == "tasks") and util.due_info(fm.due, fm.scheduled) or "", "Comment"

		table.insert(items, {
			-- `text` drives fuzzy matching (status/priority/title); the visible
			-- row is rendered by ui.task_row_format from the fields below.
			text = string.format("%s %s %s", title, status_val or "", priority_val or ""),
			file = fp,
			status_rank = status_ranks[status_val] or 99,
			priority_rank = priority_ranks[priority_val] or 99,
			title = title,
			sort_date = util.effective_date(fm.due, fm.scheduled),
			icon = ui.icon_for_status(status_val),
			status_hl = ui.ensure_color_hl("TaskNotesRow_status", status_val or "none", status_colors[status_val]),
			priority_hl = ui.ensure_color_hl(
				"TaskNotesRow_priority",
				priority_val or "none",
				priority_colors[priority_val]
			),
			time_info = time_info,
			time_hl = time_hl,
		})
	end

	table.sort(items, util.compare_task_items)
	for i, item in ipairs(items) do
		item.idx = i
	end

	local confirmed = false
	Snacks.picker.pick({
		source = "tasknotes_file",
		title = string.format("%s: %s (%d files)", key, value, #filepaths),
		items = items,
		format = ui.task_row_format,
		preview = "file",
		-- Shared layout (0.4 preview) + nav keys (<Tab> dive / <Esc> back).
		layout = ui.picker_view.layout,
		win = ui.picker_view.win,
		confirm = function(picker, item)
			confirmed = true
			picker:close()
			if item then
				vim.cmd("edit " .. vim.fn.fnameescape(item.file))
			end
		end,
		on_close = function()
			if not confirmed then
				vim.schedule(function()
					M.pick_value(key, from_shortcut, source)
				end)
			end
		end,
	})
end

-- Stage 2: Pick a value for the given key.
-- Displays value + file count. On <CR>: transitions to Stage 3.
-- On close without confirm: back to Stage 1 (unless from_shortcut).
function M.pick_value(key, from_shortcut, source)
	source = source or "global"
	if source == "tasks" then
		cache.ensure()
	elseif not cache.notes.built then
		-- Global drill-down needs the FS index. Trigger async build if it
		-- hasn't run yet (mirrors the pattern in note_search, pickers.lua
		-- line 304-309).
		vim.notify("TaskNotes: indexing vault…", vim.log.levels.INFO)
		cache.notes.build(function()
			vim.schedule(function()
				M.pick_value(key, from_shortcut, source)
			end)
		end)
		return
	end

	local keys_index = source_tables(source)
	local value_map = keys_index[key]
	if not value_map then
		vim.notify(string.format("TaskNotes: no values found for key '%s'", key), vim.log.levels.WARN)
		return
	end

	local items = {}
	for v, fps in pairs(value_map) do
		table.insert(items, {
			text = string.format("%s (%d files)", v, #fps),
			value = v,
		})
	end

	table.sort(items, function(a, b)
		return a.value < b.value
	end)
	for i, item in ipairs(items) do
		item.idx = i
	end

	local confirmed = false
	Snacks.picker.pick({
		source = "tasknotes_value",
		title = string.format("Values for: %s", key),
		items = items,
		format = "text",
		preview = "none",
		layout = { hidden = { "preview" } },
		confirm = function(picker, item)
			confirmed = true
			picker:close()
			if item then
				vim.schedule(function()
					M.pick_file(key, item.value, from_shortcut, source)
				end)
			end
		end,
		on_close = function()
			if not confirmed and not from_shortcut then
				vim.schedule(function()
					M.pick_key()
				end)
			end
		end,
	})
end

-- Stage 1: Pick a frontmatter key from the vault index.
-- Displays key + file count. On <CR>: transitions to Stage 2.
-- Always operates on the whole-vault FS index (the user explicitly asked
-- for this drill-down to be global, not task-only).
function M.pick_key()
	local function stage_index()
		local items = {}
		for key, value_map in pairs(cache.global_keys_index) do
			local file_set = {}
			for _, fps in pairs(value_map) do
				for _, fp in ipairs(fps) do
					file_set[fp] = true
				end
			end
			local file_count = 0
			for _ in pairs(file_set) do
				file_count = file_count + 1
			end

			table.insert(items, {
				text = string.format("%s (%d files)", key, file_count),
				value = key,
			})
		end

		if #items == 0 then
			vim.notify("TaskNotes: vault index is empty. Try <leader>or to force refresh.", vim.log.levels.WARN)
			return
		end

		table.sort(items, function(a, b)
			return a.value < b.value
		end)
		for i, item in ipairs(items) do
			item.idx = i
		end

		Snacks.picker.pick({
			source = "tasknotes_key",
			title = "Frontmatter Key (vault)",
			items = items,
			format = "text",
			preview = "none",
			layout = { hidden = { "preview" } },
			confirm = function(picker, item)
				picker:close()
				if item then
					vim.schedule(function()
						M.pick_value(item.value, false, "global")
					end)
				end
			end,
		})
	end

	if cache.notes.built then
		stage_index()
	else
		vim.notify("TaskNotes: indexing vault…", vim.log.levels.INFO)
		cache.notes.build(stage_index)
	end
end

-- ──────────────────────────────────────────────────────────────────────
-- Shortcut pickers (skip Stage 1, task-only by contract)
-- ──────────────────────────────────────────────────────────────────────

-- Jumps directly to Stage 2 for the 'status' key. Task-only — depends on
-- live API data (status icons/colors come from /api/filter-options).
function M.pick_file_by_status()
	cache.ensure()
	M.pick_value("status", true, "tasks")
end

-- Jumps directly to Stage 2 for the 'tags' key. Task-only — <leader>ow was
-- originally documented as a task tag filter.
function M.pick_file_by_tag()
	cache.ensure()
	M.pick_value("tags", true, "tasks")
end

-- Whole-vault note search by tag (<leader>ow). Two-stage drill-down:
-- Stage 1 = distinct tags (no preview, fuzzy by tag name); pick one →
-- Stage 2 = notes carrying that tag (preview + shared view). <Esc> in
-- Stage 2 (without picking) returns to Stage 1. Cache-backed (instant);
-- cold cache builds async first. Distinct from ot (tasks-only tag filter).
function M.note_search()
	-- Stage 2: notes for a single tag, with preview.
	local function stage_notes(tag, notes, back)
		local items = {}
		for i, e in ipairs(notes) do
			items[#items + 1] = { idx = i, text = e.title, file = e.path }
		end

		local confirmed = false
		Snacks.picker.pick({
			source = "tasknotes_tag_notes",
			title = string.format("#%s (%d notes)", tag, #notes),
			items = items,
			format = "text",
			preview = "file",
			layout = ui.picker_view.layout,
			win = ui.picker_view.win,
			confirm = function(picker, item)
				confirmed = true
				picker:close()
				if item then
					vim.cmd("edit " .. vim.fn.fnameescape(item.file))
				end
			end,
			on_close = function()
				if not confirmed then
					vim.schedule(back)
				end
			end,
		})
	end

	-- Stage 1: distinct tags with note counts.
	local function stage_tags()
		local index = {} -- tag -> { entry, .. }
		for _, e in ipairs(cache.notes.entries) do
			for _, t in ipairs(e.tags) do
				if not index[t] then
					index[t] = {}
				end
				index[t][#index[t] + 1] = e
			end
		end

		local items = {}
		for t, notes in pairs(index) do
			items[#items + 1] = {
				text = string.format("%s (%d)", t, #notes),
				tag = t,
				notes = notes,
			}
		end

		if #items == 0 then
			vim.notify("TaskNotes: no tagged notes found in vault", vim.log.levels.WARN)
			return
		end

		table.sort(items, function(a, b)
			return a.tag < b.tag
		end)
		for i, it in ipairs(items) do
			it.idx = i
		end

		Snacks.picker.pick({
			source = "tasknotes_tags",
			title = string.format("Tags (%d)", #items),
			items = items,
			format = "text",
			preview = "none",
			layout = { hidden = { "preview" } },
			confirm = function(picker, item)
				picker:close()
				if item then
					vim.schedule(function()
						stage_notes(item.tag, item.notes, stage_tags)
					end)
				end
			end,
		})
	end

	if cache.notes.built then
		stage_tags()
	else
		vim.notify("TaskNotes: indexing vault…", vim.log.levels.INFO)
		cache.notes.build(stage_tags)
	end
end

return M
