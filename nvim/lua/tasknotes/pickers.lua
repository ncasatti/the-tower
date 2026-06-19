-- TaskNotes — 3-stage drill-down pickers (Key → Value → File) + shortcuts
-- + whole-vault tag browser (note_search).

local cache = require("tasknotes.cache")
local ui = require("tasknotes.ui")
local util = require("tasknotes.util")

local M = {}

-- Stage 3: Pick a file from the list matching key=value.
-- Displays filename with optional status/priority badge + time info.
-- On <CR>: opens the file. On close without confirm: back to Stage 2.
function M.pick_file(key, value, from_shortcut)
	local filepaths = cache.keys_index[key] and cache.keys_index[key][value]
	if not filepaths or #filepaths == 0 then
		vim.notify(string.format("TaskNotes: no files found for %s = %s", key, value), vim.log.levels.WARN)
		return
	end

	local status_ranks, priority_ranks = ui.get_rank_tables()
	local status_colors, priority_colors = ui.get_color_tables()

	local items = {}
	for _, fp in ipairs(filepaths) do
		local filename = vim.fn.fnamemodify(fp, ":t")
		local title = filename:gsub("%.md$", "")
		local fm = cache.data[fp] and cache.data[fp].fm or {}

		local status_val = fm.status
		if type(status_val) == "table" then
			status_val = status_val[1]
		end
		local priority_val = fm.priority
		if type(priority_val) == "table" then
			priority_val = priority_val[1]
		end

		local time_info, time_hl = util.due_info(fm.due, fm.scheduled)

		table.insert(items, {
			-- `text` drives fuzzy matching (status/priority/title); the visible
			-- row is rendered by ui.task_row_format from the fields below.
			text = string.format("%s %s %s", title, status_val or "", priority_val or ""),
			file = fp,
			status_rank = status_ranks[status_val] or 99,
			priority_rank = priority_ranks[priority_val] or 99,
			title = title,
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

	table.sort(items, function(a, b)
		if a.status_rank ~= b.status_rank then
			return a.status_rank < b.status_rank
		end
		if a.priority_rank ~= b.priority_rank then
			return a.priority_rank < b.priority_rank
		end
		return a.title < b.title
	end)
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
					M.pick_value(key, from_shortcut)
				end)
			end
		end,
	})
end

-- Stage 2: Pick a value for the given key.
-- Displays value + file count. On <CR>: transitions to Stage 3.
-- On close without confirm: back to Stage 1 (unless from_shortcut).
function M.pick_value(key, from_shortcut)
	cache.ensure()

	local value_map = cache.keys_index[key]
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
					M.pick_file(key, item.value, from_shortcut)
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
function M.pick_key()
	cache.ensure()

	local items = {}
	for key, value_map in pairs(cache.keys_index) do
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
		vim.notify("TaskNotes: vault index is empty. Try <leader>owr to force refresh.", vim.log.levels.WARN)
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
		title = "Frontmatter Key",
		items = items,
		format = "text",
		preview = "none",
		layout = { hidden = { "preview" } },
		confirm = function(picker, item)
			picker:close()
			if item then
				vim.schedule(function()
					M.pick_value(item.value, false)
				end)
			end
		end,
	})
end

-- ──────────────────────────────────────────────────────────────────────
-- Shortcut pickers (skip Stage 1)
-- ──────────────────────────────────────────────────────────────────────

-- Jumps directly to Stage 2 for the 'status' key
function M.pick_file_by_status()
	cache.ensure()
	M.pick_value("status", true)
end

-- Jumps directly to Stage 2 for the 'tags' key
function M.pick_file_by_tag()
	cache.ensure()
	M.pick_value("tags", true)
end

-- Whole-vault note search by tag (<leader>owt). Two-stage drill-down:
-- Stage 1 = distinct tags (no preview, fuzzy by tag name); pick one →
-- Stage 2 = notes carrying that tag (preview + shared view). <Esc> in
-- Stage 2 (without picking) returns to Stage 1. Cache-backed (instant);
-- cold cache builds async first. Distinct from owo (tasks only).
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
