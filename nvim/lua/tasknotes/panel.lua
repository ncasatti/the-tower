-- TaskNotes — task info side panel (leaf renderer).
--
-- Renders the full context of the current task in a right-hand split
-- (Snacks.win, position = "right"). Rendering performs ZERO requests:
-- it reads the in-memory cache only (ADR-005) and asks for a background
-- refresh when the cache is stale, exactly like the inline card does.
--
-- The panel is editable, but only through explicit keys: a property
-- row plus `<CR>` on it, or `s`/`p`/`c`/`d`. Those keys go through
-- `task_ops.edit_field` → `task_ops.apply_patch` (ADR-009), which
-- writes the note buffer, PUTs the field and reloads the note.
--
-- Sections: header (status icon + priority dot + title), properties
-- (one editable row per field), parents, subtasks
-- (with a text progress bar), dependencies (blocked by / blocking),
-- checklist and time. Empty sections are omitted.
--
-- Every row is fitted to the panel width: the optional trailing
-- segments (a subtask's priority and dates) are dropped first, and a
-- row that still does not fit is cut with "…" on a character boundary.
-- The width is the panel window's own width, so a resize re-fits the
-- rows.
--
-- The panel follows the buffer under the cursor: entering another
-- buffer re-renders it for that buffer, entering the panel itself
-- never re-renders it.
--
-- The panel's keys (<CR> to open a Ref or edit a property, s/p/c/d to
-- edit status/priority/scheduled/due, q to close) are buffer-local on the
-- panel's own scratch buffer, which only ever lives in the panel
-- window — Neovim 0.12 removed the window-local mapping API, so this
-- is the equivalent scope.
--
-- It must not require `tasknotes.api`, `tasknotes.task_ops` or
-- `plenary.curl` at load time: its only path to the API is
-- `task_ops`, required lazily inside the edit handlers.

local cache = require("tasknotes.cache")
local card = require("tasknotes.card")
local config = require("tasknotes.config")
local ui = require("tasknotes.ui")
local util = require("tasknotes.util")

local M = {}

-- Dedicated namespace: clearing it removes the panel highlights only.
M.ns = vim.api.nvim_create_namespace("tasknotes_panel")

-- Panel state.
--
--   buf      — the panel buffer (a scratch buffer, never modified)
--   win      — the panel window id (nil when closed)
--   snacks   — the Snacks window object (owns the window lifecycle)
--   edit_win — the window the task note lives in (where <CR> edits)
--   followed — the buffer the panel currently renders
--   rows     — { [buf] = { [row] = absolute path } }
--   fields   — { [buf] = { [row] = api field name } }
M.buf = nil
M.win = nil
M.snacks = nil
M.edit_win = nil
M.followed = nil
M.rows = {}
M.fields = {}

-- Number of renders performed. Exposed for the headless tests.
M.render_count = 0

-- Width of the text progress bar (in block characters).
local BAR_WIDTH = 8

-- The checklist rows, in order: the context key, the label the USER
-- uses, and the task status whose icon and color the row borrows.
local CHECKLIST_ROWS = {
	{ key = "open", label = "open", status = "inbox" },
	{ key = "doing", label = "doing", status = "in-progress" },
	{ key = "on_hold", label = "on-hold", status = "on-hold" },
	{ key = "waiting", label = "waiting", status = "waiting" },
	{ key = "done", label = "done", status = "done" },
}

-- ──────────────────────────────────────────────────────────────────────
-- Formatting helpers
-- ──────────────────────────────────────────────────────────────────────

-- A single text segment with an optional highlight group.
--
-- `optional` marks the least important segments of a row (a subtask's
-- priority and dates): the fitter drops them before cutting the text.
local function seg(text, hl, optional)
	return { text = text, hl = hl, optional = optional }
end

-- Normalizes a date field to YYYY-MM-DD (the API sends full ISO
-- timestamps for dateCreated / dateModified).
local function short_date(value)
	if type(value) ~= "string" or value == "" then
		return nil
	end
	return value:match("^(%d%d%d%d%-%d%d%-%d%d)") or value
end

-- Minutes as `1h 26m` / `45m`. Returns nil for zero minutes.
local function fmt_minutes(minutes)
	local mins = tonumber(minutes) or 0
	if mins <= 0 then
		return nil
	end
	local h = math.floor(mins / 60)
	local m = mins % 60
	if h == 0 then
		return string.format("%dm", m)
	end
	if m == 0 then
		return string.format("%dh", h)
	end
	return string.format("%dh %dm", h, m)
end

-- The value of a list-valued field as one line ("a, b"). nil when empty.
local function join_list(value)
	if type(value) == "table" then
		local parts = {}
		for _, v in ipairs(value) do
			if type(v) == "string" and v ~= "" then
				parts[#parts + 1] = v
			end
		end
		if #parts == 0 then
			return nil
		end
		return table.concat(parts, ", ")
	end
	if type(value) == "string" and value ~= "" then
		return value
	end
	return nil
end

-- The text progress bar: `████░░░░ 2/6`.
local function progress_bar(done, total)
	if total <= 0 then
		return nil
	end
	local filled = math.floor(done * BAR_WIDTH / total + 0.5)
	if filled < 0 then
		filled = 0
	end
	if filled > BAR_WIDTH then
		filled = BAR_WIDTH
	end
	return string.rep("█", filled) .. string.rep("░", BAR_WIDTH - filled) .. string.format(" %d/%d", done, total)
end

-- The highlight group for a status / priority color. Falls back to
-- `Comment` when the API has no color for the value.
local function color_hl(prefix, value, color)
	if not color or not value then
		return "Comment"
	end
	return ui.ensure_color_hl(prefix, value, color)
end

-- The ellipsis that marks a row cut at the panel width.
local ELLIPSIS = "…"

-- The display name of a wiki link, as shown in the panel:
--   [[Name]]            -> Name
--   [[folder/Name]]     -> Name
--   [[Name|Alias]]      -> Alias
--   "[[Name]]"          -> Name
-- The alias wins over the target, and the folder prefix is dropped.
-- The value sent on edit is never touched: this is display only.
local function link_label(raw)
	if type(raw) ~= "string" then
		return nil
	end

	local s = vim.trim(raw)

	-- Surrounding quotes (single or double).
	s = s:gsub('^"(.*)"$', "%1")
	s = s:gsub("^'(.*)'$", "%1")
	s = vim.trim(s)

	-- Wiki brackets.
	s = s:gsub("^%[%[", "")
	s = s:gsub("%]%]$", "")
	s = vim.trim(s)

	-- The alias after `|` is the label the user wrote.
	local target, alias = s:match("^([^|]*)|(.*)$")
	if alias and vim.trim(alias) ~= "" then
		s = vim.trim(alias)
	else
		s = vim.trim(target or s)
		-- Heading and folder prefix are not part of the name.
		s = s:gsub("#.*$", "")
		s = vim.trim(s)
		s = s:match("([^/]+)$") or s
		s = s:gsub("%.md$", "")
	end

	s = vim.trim(s)
	if s == "" then
		return nil
	end
	return s
end

-- The value of a link-valued field as one line ("a, b"), with the
-- link names instead of the raw wikilinks. nil when empty.
local function join_links(value)
	local list = value
	if type(list) == "string" then
		list = { list }
	end
	if type(list) ~= "table" then
		return nil
	end

	local parts = {}
	for _, raw in ipairs(list) do
		local label = link_label(raw)
		if label then
			parts[#parts + 1] = label
		end
	end
	if #parts == 0 then
		return nil
	end
	return table.concat(parts, ", ")
end

-- The width the rows were last fitted to. A WinResized event that
-- changes it means the rows must be fitted again.
local rendered_width = nil

-- The panel width in columns: `config.panel_width` below 1 is a share
-- of the editor width, 1 or more a fixed column count.
local function panel_columns()
	local width = tonumber(config.panel_width) or 0.4
	if width > 0 and width < 1 then
		return math.max(1, math.floor(vim.o.columns * width))
	end
	return math.floor(width)
end

-- The width available for a row: the panel window's width when the
-- panel is open, the configured width otherwise. The panel has no
-- sign column and no line numbers, so the window width IS the text
-- width. With 'wrap' on in the panel window the window wraps long
-- rows itself, so nothing is cut (nil = no limit).
local function available_width()
	if M.win and vim.api.nvim_win_is_valid(M.win) then
		if vim.wo[M.win].wrap then
			return nil
		end
		return vim.api.nvim_win_get_width(M.win)
	end
	return panel_columns()
end

-- The display width of a row (its segments concatenated).
local function row_width(segments)
	local parts = {}
	for _, segment in ipairs(segments) do
		parts[#parts + 1] = segment.text
	end
	return vim.fn.strdisplaywidth(table.concat(parts))
end

-- A copy of a segment (the fit never mutates its input).
local function copy_segment(segment)
	local copy = {}
	for key, value in pairs(segment) do
		copy[key] = value
	end
	return copy
end

-- The number of characters of the longest prefix of `text` whose
-- display width is at most `budget`. The prefix always ends on a
-- character boundary, so a multibyte glyph is never cut in half.
--
-- The display width of a prefix grows monotonically with its length,
-- so the longest fitting prefix is found by bisection.
local function prefix_chars(text, budget)
	if budget <= 0 then
		return 0
	end

	local chars = vim.fn.strchars(text)
	local lo, hi = 0, chars
	while lo < hi do
		local mid = math.floor((lo + hi + 1) / 2)
		if vim.fn.strdisplaywidth(vim.fn.strcharpart(text, 0, mid)) <= budget then
			lo = mid
		else
			hi = mid - 1
		end
	end
	return lo
end

-- The byte length of the longest prefix of `text` that fits in
-- `max_bytes` and ends on a character boundary.
local function head_bytes(text, max_bytes)
	if max_bytes >= #text then
		return #text
	end
	if max_bytes <= 0 then
		return 0
	end

	local chars = vim.fn.strchars(text)
	local lo, hi = 0, chars
	while lo < hi do
		local mid = math.floor((lo + hi + 1) / 2)
		if #vim.fn.strcharpart(text, 0, mid) <= max_bytes then
			lo = mid
		else
			hi = mid - 1
		end
	end
	return #vim.fn.strcharpart(text, 0, lo)
end

-- Fits a row to `width` display cells.
--
-- The optional trailing segments (the least important ones: a
-- subtask's priority and dates) are dropped from the end first; only
-- when the row still does not fit is its text cut, on a character
-- boundary, and marked with "…".
--
-- Pure: the segments it is given are never modified.
--
--   M._fit_segments(segments, width) -> segments
function M._fit_segments(segments, width)
	width = tonumber(width) or 0
	if width <= 0 or type(segments) ~= "table" then
		return segments
	end

	local kept = {}
	for _, segment in ipairs(segments) do
		kept[#kept + 1] = copy_segment(segment)
	end

	-- 1. Drop the optional trailing segments while the row is too wide:
	--    the date and the priority go before the name is cut.
	while row_width(kept) > width do
		local last = kept[#kept]
		if not (last and last.optional) then
			break
		end
		table.remove(kept)
	end

	if row_width(kept) <= width then
		return kept
	end

	-- 2. Cut the text and mark the cut with an ellipsis.
	local parts = {}
	for _, segment in ipairs(kept) do
		parts[#parts + 1] = segment.text
	end
	local text = table.concat(parts)
	local cut = prefix_chars(text, width - vim.fn.strdisplaywidth(ELLIPSIS))
	local cut_bytes = #vim.fn.strcharpart(text, 0, cut)

	local fitted = {}
	local offset = 0
	for _, segment in ipairs(kept) do
		local length = #segment.text
		if offset >= cut_bytes then
			-- The segments after the cut are dropped.
			break
		end
		local piece = segment.text
		if offset + length > cut_bytes then
			-- The segment is cut: keep its character-aligned head.
			piece = segment.text:sub(1, head_bytes(segment.text, cut_bytes - offset))
		end
		local copy = copy_segment(segment)
		copy.text = piece
		fitted[#fitted + 1] = copy
		offset = offset + length
	end

	if #fitted == 0 then
		-- Nothing fits: the ellipsis stands alone.
		fitted[1] = { text = ELLIPSIS, hl = kept[1].hl }
	else
		local last = fitted[#fitted]
		last.text = last.text .. ELLIPSIS
	end

	return fitted
end

-- ──────────────────────────────────────────────────────────────────────
-- Layout
--
-- Rows are lists of segments; a row may carry a path (navigable:
-- <CR> opens it) and/or a field (editable: <CR> edits that field of
-- the followed task).
-- ──────────────────────────────────────────────────────────────────────
local function build_rows(ctx)
	local rows = {}

	local function add(segments, path, field)
		rows[#rows + 1] = { segments = segments, path = path, field = field }
	end

	local function heading(text)
		add({ seg(text, "Title") })
	end

	-- ── Header ────────────────────────────────────────────────────────
	if ctx then
		local task = ctx.task or {}
		local status_colors, priority_colors = ui.get_color_tables({ cached_only = true })

		local status = task.status
		local priority = task.priority

		add({
			seg(ui.icon_for_status(status), color_hl("TaskNotesStatus", status, status_colors[status])),
			seg(" "),
			seg(config.priority_icon, color_hl("TaskNotesPriority", priority, priority_colors[priority])),
			seg("  "),
			seg(util.task_title(task, ctx.path)),
		})
	end

	-- ── Properties ────────────────────────────────────────────────────
	-- One editable row per field: the label, the current value (the
	-- live label and color for status/priority), and the API field
	-- name the row edits.
	if ctx then
		local task = ctx.task or {}
		local status_colors, priority_colors = ui.get_color_tables({ cached_only = true })
		local status_labels, priority_labels = ui.get_label_tables({ cached_only = true })

		heading("Properties")

		-- An empty field shows an em dash, dimmed.
		local function property(label, field, value, hl)
			if value == nil or value == "" then
				value = nil
			end
			add({
				seg(string.format("  %-10s", label), "Comment"),
				seg(value or "—", value and hl or "Comment"),
			}, nil, field)
		end

		local status = task.status
		local priority = task.priority

		property("Task", "title", util.task_title(task, ctx.path))
		property(
			"Status",
			"status",
			status_labels[status] or status,
			color_hl("TaskNotesStatus", status, status_colors[status])
		)
		property(
			"Priority",
			"priority",
			priority_labels[priority] or priority,
			color_hl("TaskNotesPriority", priority, priority_colors[priority])
		)
		property("Scheduled", "scheduled", short_date(task.scheduled))
		property("Due", "due", short_date(task.due))
		property("Contexts", "contexts", join_list(task.contexts))
		-- The projects are wiki links: show their names, not the raw
		-- links. The value sent on edit is untouched.
		property("Projects", "projects", join_links(task.projects))
		property("Tags", "tags", join_list(task.tags))

		-- The estimate is stored in minutes; show the raw number so it
		-- round-trips into the editor's minute prompt.
		local estimate = ctx.time and ctx.time.estimate_min
		property("Estimate", "timeEstimate", estimate and tostring(estimate) or nil)
	end

	-- ── Parents ───────────────────────────────────────────────────────
	if ctx and #ctx.parents > 0 then
		heading("Parents")
		for _, parent in ipairs(ctx.parents) do
			add({ seg("  ↑ "), seg(parent.name) }, parent.path)
		end
	end

	-- ── Subtasks ──────────────────────────────────────────────────────
	if ctx and #ctx.subtasks > 0 then
		heading("Subtasks")
		local status_colors, priority_colors = ui.get_color_tables({ cached_only = true })
		local status_labels, priority_labels = ui.get_label_tables({ cached_only = true })
		for _, sub in ipairs(ctx.subtasks) do
			local segments = {
				seg("  "),
				seg(ui.icon_for_status(sub.status), color_hl("TaskNotesStatus", sub.status, status_colors[sub.status])),
				seg(" " .. (sub.name or "")),
			}
			-- The priority and the dates are the least important parts
			-- of the row: they are dropped before the name is cut.
			if sub.priority then
				segments[#segments + 1] = seg("  " .. (priority_labels[sub.priority] or sub.priority), "Comment", true)
			end
			local scheduled = short_date(sub.scheduled)
			local due = short_date(sub.due)
			if scheduled then
				segments[#segments + 1] = seg("  sched " .. scheduled, "Comment", true)
			end
			if due then
				segments[#segments + 1] = seg("  due " .. due, "Comment", true)
			end
			add(segments, sub.path)
		end
		local bar = progress_bar(ctx.progress.done, ctx.progress.total)
		if bar then
			add({ seg("  " .. bar, "Comment") })
		end
	end

	-- ── Dependencies ──────────────────────────────────────────────────
	if ctx and (#ctx.blocked_by > 0 or #ctx.blocking > 0) then
		heading("Dependencies")
		if #ctx.blocked_by > 0 then
			add({ seg("  Blocked by", "Comment") })
			for _, ref in ipairs(ctx.blocked_by) do
				add({ seg("    "), seg(ref.name) }, ref.path)
			end
		end
		if #ctx.blocking > 0 then
			add({ seg("  Blocking", "Comment") })
			for _, ref in ipairs(ctx.blocking) do
				add({ seg("    "), seg(ref.name) }, ref.path)
			end
		end
	end

	-- ── Checklist ─────────────────────────────────────────────────────
	-- One row per state in use, with the icon and live color of the
	-- matching task status, so a checklist reads like a task list.
	if ctx then
		local checklist = ctx.checklist or {}
		if (checklist.total or 0) > 0 then
			heading("Checklist")
			local status_colors = ui.get_color_tables({ cached_only = true })
			for _, state in ipairs(CHECKLIST_ROWS) do
				local n = checklist[state.key] or 0
				if n > 0 then
					add({
						seg("  "),
						seg(
							ui.icon_for_status(state.status),
							color_hl("TaskNotesStatus", state.status, status_colors[state.status])
						),
						seg(string.format(" %-8s", state.label)),
						seg(string.format("%d", n), "Comment"),
					})
				end
			end
		end
	end

	-- ── Time ──────────────────────────────────────────────────────────
	if ctx then
		local time = ctx.time or {}
		local tracked = fmt_minutes(time.tracked_min)
		local estimate = fmt_minutes(time.estimate_min)
		if tracked or estimate then
			heading("Time")
			local segments = { seg("  ") }
			if tracked then
				segments[#segments + 1] = seg(tracked)
			else
				segments[#segments + 1] = seg("—")
			end
			if estimate then
				segments[#segments + 1] = seg(" / ")
				segments[#segments + 1] = seg(estimate)
			end
			add(segments)
		end
	end

	-- ── Footer hint ──────────────────────────────────────────────────
	-- The keys that work in the panel. Only shown for a real task.
	-- Two rows, each short enough to fit the default panel width (48).
	if ctx then
		add({ seg("<CR> edit/open · q close", "Comment") })
		add({ seg("s status · p prio · c sched · d due", "Comment") })
	end

	return rows
end

-- The empty-state rows: the cache is still filling, or the buffer is
-- not a task at all.
local function empty_rows()
	local rows = {}
	if next(cache.data) == nil then
		rows[1] = { segments = { seg("Loading tasks…", "Comment") } }
	else
		rows[1] = { segments = { seg("Not a TaskNotes task", "Comment") } }
	end
	return rows
end

-- ──────────────────────────────────────────────────────────────────────
-- Rendering
-- ──────────────────────────────────────────────────────────────────────

-- Writes the rows into a buffer: the text as real lines, the
-- highlights as extmarks in the panel namespace.
--
-- Every row is fitted to the panel width first: the optional trailing
-- segments are dropped and the text is cut with an ellipsis, so a row
-- is never cut at the window edge.
--
-- The buffer is never left modified — the text is written with
-- `modifiable` temporarily on, and the modified flag is cleared
-- afterwards.
local function apply_rows(buf, rows)
	local width = available_width()
	rendered_width = width

	local fitted = {}
	local lines = {}
	for i, row in ipairs(rows) do
		local segments = M._fit_segments(row.segments, width)
		fitted[i] = segments
		local parts = {}
		for _, segment in ipairs(segments) do
			parts[#parts + 1] = segment.text
		end
		lines[i] = table.concat(parts)
	end

	vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)

	local modifiable = vim.bo[buf].modifiable
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = modifiable
	vim.bo[buf].modified = false

	for i, segments in ipairs(fitted) do
		local col = 0
		for _, segment in ipairs(segments) do
			local len = #segment.text
			if segment.hl and len > 0 then
				vim.api.nvim_buf_set_extmark(buf, M.ns, i - 1, col, {
					end_col = col + len,
					hl_group = segment.hl,
				})
			end
			col = col + len
		end
	end
end

-- Renders a context into a buffer. A nil context renders the empty
-- state ("Loading tasks…" while the cache is empty, "Not a TaskNotes
-- task" otherwise).
--
-- Returns the row → path map: row number (1-based) → absolute path.
function M.render_into(buf, ctx)
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return {}
	end

	local rows = ctx and build_rows(ctx) or empty_rows()
	apply_rows(buf, rows)

	local paths = {}
	local fields = {}
	for i, row in ipairs(rows) do
		if row.path then
			paths[i] = row.path
		end
		if row.field then
			fields[i] = row.field
		end
	end
	M.rows[buf] = paths
	M.fields[buf] = fields
	M.render_count = M.render_count + 1

	return paths
end

-- The path of the row under `row` in `buf`, or nil when the row is
-- not a navigable row.
function M.path_at(buf, row)
	local paths = M.rows[buf]
	if not paths then
		return nil
	end
	return paths[row]
end

-- The API field the row under `row` in `buf` edits, or nil when the
-- row is not an editable property row.
function M.field_at(buf, row)
	local fields = M.fields[buf]
	if not fields then
		return nil
	end
	return fields[row]
end

-- Renders a context into the panel buffer (or into opts.buf).
function M.render(ctx, opts)
	opts = opts or {}
	local buf = opts.buf or M.buf
	if not buf then
		return {}
	end
	return M.render_into(buf, ctx)
end

-- ──────────────────────────────────────────────────────────────────────
-- Following
-- ──────────────────────────────────────────────────────────────────────

-- Renders the panel for a buffer.
local function follow(buf)
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	M.followed = buf
	local ctx = card.context_for(buf)
	M.render(ctx)
end

-- ──────────────────────────────────────────────────────────────────────
-- Window layer
-- ──────────────────────────────────────────────────────────────────────

-- Creates the panel buffer (a scratch buffer that is never modified).
local function ensure_buffer()
	if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
		return M.buf
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].filetype = "tasknotes-panel"
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "hide"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false
	M.buf = buf
	return buf
end

-- The window a Ref is opened in: the window that shows the buffer the
-- panel follows (the editing window), falling back to the window the
-- panel was opened from and finally to any other window.
local function target_window()
	if M.followed then
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			if win ~= M.win and vim.api.nvim_win_get_buf(win) == M.followed then
				return win
			end
		end
	end

	if M.edit_win and vim.api.nvim_win_is_valid(M.edit_win) and M.edit_win ~= M.win then
		return M.edit_win
	end

	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if win ~= M.win and vim.api.nvim_win_get_config(win).relative == "" then
			return win
		end
	end

	return nil
end

-- Opens the Ref under the cursor in the window the note lives in.
-- Rows without a path do nothing.
local function open_ref_under_cursor()
	if not M.buf or not M.win or not vim.api.nvim_win_is_valid(M.win) then
		return
	end

	local row = vim.api.nvim_win_get_cursor(M.win)[1]
	local path = M.path_at(M.buf, row)
	if not path then
		return
	end

	local target = target_window()
	if not target then
		return
	end

	vim.api.nvim_win_call(target, function()
		vim.cmd("edit " .. vim.fn.fnameescape(path))
	end)
end

-- ──────────────────────────────────────────────────────────────────────
-- Editing (ADR-009)
--
-- The panel's edit keys act on the task the panel FOLLOWS, not on the
-- buffer under the cursor. The write path (task_ops → api) is loaded
-- lazily, inside the handler: the panel must not pull the HTTP layer
-- in at load time, and rendering must stay request-free (ADR-005).
-- ──────────────────────────────────────────────────────────────────────

-- The vault-relative id of the task the panel follows — the API's task
-- id — or nil when the panel does not follow a task.
local function followed_task_id()
	if not M.followed or not vim.api.nvim_buf_is_valid(M.followed) then
		return nil
	end
	-- Only a known task can be edited.
	local name = vim.api.nvim_buf_get_name(M.followed)
	if name == "" then
		return nil
	end
	local tasks = cache.data or {}
	if not tasks[vim.fs.normalize(name)] and not tasks[name] then
		return nil
	end
	-- The id is the buffer's path relative to the vault — the same id
	-- the API knows the task by.
	local id
	pcall(vim.api.nvim_buf_call, M.followed, function()
		id = util.buffer_to_id()
	end)
	return id
end

-- Edits one property of the followed task and saves it through the API.
local function edit_field(field)
	local id = followed_task_id()
	if not id then
		return
	end
	require("tasknotes.task_ops").edit_field(id, field, { buf = M.followed })
end

-- <CR> on a row: opens the Ref it points at, or edits the property it
-- shows.
local function activate_row()
	if not M.buf or not M.win or not vim.api.nvim_win_is_valid(M.win) then
		return
	end

	local row = vim.api.nvim_win_get_cursor(M.win)[1]
	local path = M.path_at(M.buf, row)
	if path then
		open_ref_under_cursor()
		return
	end

	local field = M.field_at(M.buf, row)
	if field then
		edit_field(field)
	end
end

-- Opens the panel in a right-hand split. Returns true when the panel
-- is open afterwards.
function M.open()
	if M.is_open() then
		return true
	end

	local buf = ensure_buffer()
	M.edit_win = vim.api.nvim_get_current_win()

	local snacks = _G.Snacks
	if not snacks then
		local ok, mod = pcall(require, "snacks")
		if not ok then
			return false
		end
		snacks = mod
	end

	local win = snacks.win.new({
		position = "right",
		width = panel_columns(),
		enter = false,
		buf = buf,
		bo = {
			filetype = "tasknotes-panel",
			modifiable = false,
			bufhidden = "hide",
			swapfile = false,
		},
		wo = {
			number = false,
			signcolumn = "no",
			-- Inherit the global wrap settings (config.lua); <leader>W
			-- toggles them per window, the panel included.
			wrap = vim.go.wrap,
			linebreak = vim.go.linebreak,
			cursorline = true,
		},
		keys = {
			["<CR>"] = function()
				activate_row()
			end,
			s = function()
				edit_field("status")
			end,
			p = function()
				edit_field("priority")
			end,
			c = function()
				edit_field("scheduled")
			end,
			d = function()
				edit_field("due")
			end,
		},
		on_close = function()
			M.win = nil
			M.snacks = nil
			M.edit_win = nil
		end,
	})

	M.snacks = win
	M.win = win.win

	-- Render the buffer the panel was opened on.
	follow(vim.api.nvim_get_current_buf())

	return M.is_open()
end

-- Closes the panel (the buffer is kept for the next open).
function M.close()
	if M.snacks then
		local win = M.snacks
		M.snacks = nil
		pcall(function()
			win:close()
		end)
	end
	M.win = nil
	M.edit_win = nil
end

-- True when the panel window is open.
function M.is_open()
	return M.win ~= nil and vim.api.nvim_win_is_valid(M.win)
end

-- The id of the panel window (nil when closed).
function M.window()
	return M.win
end

-- Toggles the panel.
function M.toggle()
	if M.is_open() then
		M.close()
		return false
	end
	return M.open()
end

-- Registers the autocmds that keep the panel in sync. They live in the
-- shared `TaskNotesViews` augroup (created by `card.attach`), so the
-- inline card and the panel stay wired together.
--
-- Called after `card.attach()` — the augroup is created with
-- `clear = false` so the card's autocmds survive.
function M.attach()
	local group = vim.api.nvim_create_augroup("TaskNotesViews", { clear = false })

	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		callback = function(ev)
			if not M.is_open() then
				return
			end
			-- Entering the panel itself must not re-render it.
			if ev.buf == M.buf then
				return
			end
			-- Special buffers (pickers, terminals, noice, help) and floating
			-- windows are transient: keep showing the last followed file.
			if vim.bo[ev.buf].buftype ~= "" then
				return
			end
			if vim.api.nvim_win_get_config(0).relative ~= "" then
				return
			end
			follow(ev.buf)
		end,
	})

	vim.api.nvim_create_autocmd("BufWritePost", {
		group = group,
		callback = function(ev)
			if not M.is_open() then
				return
			end
			-- Writing the panel itself is impossible (it is not
			-- modifiable), but guard anyway.
			if ev.buf == M.buf then
				return
			end
			follow(ev.buf)
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "TaskNotesCacheRefreshed",
		callback = function()
			if not M.is_open() or not M.followed then
				return
			end
			follow(M.followed)
		end,
	})

	-- The rows are fitted to the panel width: when the panel window
	-- is resized, the rows are cut for the new width.
	vim.api.nvim_create_autocmd("WinResized", {
		group = group,
		pattern = "*",
		callback = function()
			if not M.is_open() or not M.followed then
				return
			end
			-- Only the panel's own width matters.
			if available_width() == rendered_width then
				return
			end
			follow(M.followed)
		end,
	})

	-- A share-of-the-editor width follows the editor: when the terminal
	-- is resized, give the panel its share again (the split has a fixed
	-- width otherwise) and fit the rows to it.
	vim.api.nvim_create_autocmd("VimResized", {
		group = group,
		callback = function()
			if not M.is_open() then
				return
			end
			local width = panel_columns()
			if vim.api.nvim_win_get_width(M.win) ~= width then
				vim.api.nvim_win_set_width(M.win, width)
			end
			if M.followed and available_width() ~= rendered_width then
				follow(M.followed)
			end
		end,
	})

	-- Toggling wrap in the panel window (<leader>W) switches between
	-- wrapped rows and rows cut with an ellipsis: render again.
	vim.api.nvim_create_autocmd("OptionSet", {
		group = group,
		pattern = "wrap",
		callback = function()
			if not M.is_open() or not M.followed then
				return
			end
			if vim.api.nvim_get_current_win() ~= M.win then
				return
			end
			follow(M.followed)
		end,
	})
end

return M
