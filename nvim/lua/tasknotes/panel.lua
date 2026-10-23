-- TaskNotes — task info side panel (leaf renderer).
--
-- Renders the full context of the current task in a right-hand split
-- (Snacks.win, position = "right"). The panel is READ-ONLY: it never
-- mutates a task and never performs a request of its own — it reads
-- the in-memory cache only (ADR-005) and asks for a background refresh
-- when the cache is stale, exactly like the inline card does.
--
-- Sections: header (status icon + priority dot + title + labels),
-- dates, parents, subtasks (with a text progress bar), dependencies
-- (blocked by / blocking), checklist and time. Empty sections are
-- omitted.
--
-- The panel follows the buffer under the cursor: entering another
-- buffer re-renders it for that buffer, entering the panel itself
-- never re-renders it.
--
-- The panel's keys (<CR> to open a Ref, q to close) are buffer-local
-- on the panel's own scratch buffer, which only ever lives in the panel
-- window — Neovim 0.12 removed the window-local mapping API, so this is
-- the equivalent scope.
--
-- It must not require `tasknotes.api`, `tasknotes.task_ops` or
-- `plenary.curl` directly: its only path to the API is `ui` in
-- cached-only mode.

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
M.buf = nil
M.win = nil
M.snacks = nil
M.edit_win = nil
M.followed = nil
M.rows = {}

-- Number of renders performed. Exposed for the headless tests.
M.render_count = 0

-- Width of the text progress bar (in block characters).
local BAR_WIDTH = 8

-- ──────────────────────────────────────────────────────────────────────
-- Formatting helpers
-- ──────────────────────────────────────────────────────────────────────

-- A single text segment with an optional highlight group.
local function seg(text, hl)
	return { text = text, hl = hl }
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

-- ──────────────────────────────────────────────────────────────────────
-- Layout
--
-- Rows are lists of segments; a row may carry a path, which makes it
-- a navigable row (<CR> opens it).
-- ──────────────────────────────────────────────────────────────────────
local function build_rows(ctx)
	local rows = {}

	local function add(segments, path)
		rows[#rows + 1] = { segments = segments, path = path }
	end

	local function heading(text)
		add({ seg(text, "Title") })
	end

	-- ── Header ────────────────────────────────────────────────────────
	if ctx then
		local task = ctx.task or {}
		local status_colors, priority_colors = ui.get_color_tables({ cached_only = true })
		local status_labels, priority_labels = ui.get_label_tables({ cached_only = true })

		local status = task.status
		local priority = task.priority

		add({
			seg(ui.icon_for_status(status), color_hl("TaskNotesStatus", status, status_colors[status])),
			seg(" "),
			seg(config.priority_icon, color_hl("TaskNotesPriority", priority, priority_colors[priority])),
			seg("  "),
			seg(util.task_title(task, ctx.path)),
		})

		add({
			seg("status: ", "Comment"),
			seg(status_labels[status] or status or "—"),
			seg("  ·  priority: ", "Comment"),
			seg(priority_labels[priority] or priority or "—"),
		})
	end

	-- ── Dates ─────────────────────────────────────────────────────────
	local dates = {}
	if ctx then
		local task = ctx.task or {}
		local scheduled = short_date(task.scheduled)
		local due = short_date(task.due)
		local created = short_date(task.dateCreated)
		local modified = short_date(task.dateModified)
		if scheduled then
			dates[#dates + 1] = { "scheduled", scheduled }
		end
		if due then
			dates[#dates + 1] = { "due", due }
		end
		if created then
			dates[#dates + 1] = { "created", created }
		end
		if modified then
			dates[#dates + 1] = { "modified", modified }
		end
	end
	if #dates > 0 then
		heading("Dates")
		for _, entry in ipairs(dates) do
			add({
				seg(string.format("  %-10s", entry[1]), "Comment"),
				seg(entry[2]),
			})
		end
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
			if sub.priority then
				segments[#segments + 1] = seg("  " .. (priority_labels[sub.priority] or sub.priority), "Comment")
			end
			local scheduled = short_date(sub.scheduled)
			local due = short_date(sub.due)
			if scheduled then
				segments[#segments + 1] = seg("  sched " .. scheduled, "Comment")
			end
			if due then
				segments[#segments + 1] = seg("  due " .. due, "Comment")
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
	if ctx then
		local checklist = ctx.checklist or {}
		local total = (checklist.done or 0) + (checklist.doing or 0) + (checklist.open or 0)
		if total > 0 then
			heading("Checklist")
			add({
				seg(string.format("  done %d", checklist.done or 0)),
				seg("  ·  ", "Comment"),
				seg(string.format("doing %d", checklist.doing or 0)),
				seg("  ·  ", "Comment"),
				seg(string.format("open %d", checklist.open or 0)),
			})
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
-- The buffer is never left modified — the text is written with
-- `modifiable` temporarily on, and the modified flag is cleared
-- afterwards.
local function apply_rows(buf, rows)
	local lines = {}
	for i, row in ipairs(rows) do
		local parts = {}
		for _, segment in ipairs(row.segments) do
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

	for i, row in ipairs(rows) do
		local col = 0
		for _, segment in ipairs(row.segments) do
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
	for i, row in ipairs(rows) do
		if row.path then
			paths[i] = row.path
		end
	end
	M.rows[buf] = paths
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
		width = config.panel_width or 48,
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
			wrap = false,
			cursorline = true,
		},
		keys = {
			["<CR>"] = function()
				open_ref_under_cursor()
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
end

return M
