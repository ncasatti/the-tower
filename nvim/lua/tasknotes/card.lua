-- TaskNotes — inline task card (leaf renderer).
--
-- Draws a task context as virtual lines right below the closing
-- frontmatter fence, in its own namespace (`tasknotes_card`). The card is
-- pure virtual text: the buffer is never modified (ADR-006).
--
-- This module is a leaf: it formats a Context into chunks. It never
-- mutates anything and it never performs a network call — it reads the
-- in-memory cache only, and asks for a background refresh when the cache
-- is stale (ADR-005).
--
-- It must not require `tasknotes.api`, `tasknotes.task_ops` or
-- `plenary.curl` directly: its only path to the API is `ui` in
-- cached-only mode.

local cache = require("tasknotes.cache")
local config = require("tasknotes.config")
local context = require("tasknotes.context")
local ui = require("tasknotes.ui")

local M = {}

-- Dedicated namespace: clearing it removes the card and nothing else.
M.ns = vim.api.nvim_create_namespace("tasknotes_card")

-- Global, session-scoped switch (on by default).
M.enabled = true

-- ──────────────────────────────────────────────────────────────────────
-- Chunk helpers
-- ──────────────────────────────────────────────────────────────────────
local function chunk(text, hl)
	return { text, hl or "Comment" }
end

-- Resolves the highlight group for a status/priority color. Falls back
-- to `Comment` when the API has no color for the value.
local function color_hl(prefix, value, color)
	if not color or not value then
		return "Comment"
	end
	return ui.ensure_color_hl(prefix, value, color)
end

-- Normalizes a date field to YYYY-MM-DD (the API may send a full ISO
-- timestamp).
local function short_date(value)
	if type(value) ~= "string" or value == "" then
		return nil
	end
	local date = value:match("^(%d%d%d%d%-%d%d%-%d%d)")
	return date or value
end

-- The task's title: the API record's title, falling back to the filename.
local function task_title(ctx)
	local title = ctx.task and ctx.task.title
	if type(title) == "table" then
		title = title[1]
	end
	if type(title) == "string" and title ~= "" then
		return title
	end
	return vim.fn.fnamemodify(ctx.path, ":t:r")
end

-- The tag list of a task, normalized to an array of strings.
local function task_tags(task)
	local tags = task and task.tags
	if type(tags) == "string" then
		tags = { tags }
	end
	if type(tags) ~= "table" then
		return {}
	end
	local out = {}
	for _, tag in ipairs(tags) do
		if type(tag) == "string" and tag ~= "" then
			out[#out + 1] = tag
		end
	end
	return out
end

-- ──────────────────────────────────────────────────────────────────────
-- Card layout
--
--   <status icon> <priority dot>  <title>   <scheduled/due>  #tag #tag
--   ↑ parentA, parentB
--   ├ <icon> <subtask>
--   └ <icon> <subtask>
--     +3 more
--   subtasks 1/4 · checklist 2/5
-- ──────────────────────────────────────────────────────────────────────
local function build_lines(ctx)
	local status_colors, priority_colors = ui.get_color_tables({ cached_only = true })
	local task = ctx.task or {}

	local status = task.status
	local status_hl = color_hl("TaskNotesStatus", status, status_colors[status])
	local priority_hl = color_hl("TaskNotesPriority", task.priority, priority_colors[task.priority])

	-- Header.
	local header = {
		chunk(ui.icon_for_status(status), status_hl),
		chunk(" "),
		chunk(config.priority_icon, priority_hl),
		chunk("  "),
		chunk(task_title(ctx)),
	}

	-- Dates: scheduled and/or due.
	local dates = {}
	local scheduled = short_date(task.scheduled)
	local due = short_date(task.due)
	if scheduled then
		dates[#dates + 1] = "sched " .. scheduled
	end
	if due then
		dates[#dates + 1] = "due " .. due
	end
	if #dates > 0 then
		header[#header + 1] = chunk("   ")
		header[#header + 1] = chunk(table.concat(dates, " · "))
	end

	-- Tags.
	local tags = task_tags(task)
	if #tags > 0 then
		local rendered = {}
		for _, tag in ipairs(tags) do
			rendered[#rendered + 1] = "#" .. tag
		end
		header[#header + 1] = chunk("  ")
		header[#header + 1] = chunk(table.concat(rendered, " "))
	end

	local lines = { header }

	-- Parents.
	if #ctx.parents > 0 then
		local names = {}
		for _, parent in ipairs(ctx.parents) do
			names[#names + 1] = parent.name
		end
		lines[#lines + 1] = { chunk("↑ " .. table.concat(names, ", ")) }
	end

	-- Subtasks (tree glyphs, truncated to card_max_subtasks).
	local max_subtasks = config.card_max_subtasks or 5
	local shown = math.min(#ctx.subtasks, max_subtasks)
	local truncated = #ctx.subtasks > shown
	for i = 1, shown do
		local subtask = ctx.subtasks[i]
		-- The closing glyph only goes on the last row when nothing is
		-- hidden behind the "+N more" line.
		local glyph = (i == shown and not truncated) and "└" or "├"
		local subtask_hl = color_hl("TaskNotesStatus", subtask.status, status_colors[subtask.status])
		lines[#lines + 1] = {
			chunk(glyph .. " "),
			chunk(ui.icon_for_status(subtask.status), subtask_hl),
			chunk(" " .. (subtask.name or "")),
		}
	end
	if truncated then
		lines[#lines + 1] = { chunk(string.format("  +%d more", #ctx.subtasks - shown)) }
	end

	-- Progress footer: omit the parts that are empty.
	local footer = {}
	if ctx.progress and ctx.progress.total > 0 then
		footer[#footer + 1] = string.format("subtasks %d/%d", ctx.progress.done, ctx.progress.total)
	end
	if ctx.checklist then
		local checklist_total = ctx.checklist.done + ctx.checklist.doing + ctx.checklist.open
		if checklist_total > 0 then
			footer[#footer + 1] = string.format("checklist %d/%d", ctx.checklist.done, checklist_total)
		end
	end
	if #footer > 0 then
		lines[#lines + 1] = { chunk(table.concat(footer, " · ")) }
	end

	return lines
end

-- ──────────────────────────────────────────────────────────────────────
-- Buffer helpers
-- ──────────────────────────────────────────────────────────────────────

-- True when a buffer is a markdown file inside the vault.
local function is_vault_markdown(buf)
	local name = vim.api.nvim_buf_get_name(buf)
	if name == "" or not name:match("%.md$") then
		return false
	end
	local vault = vim.fs.normalize(config.vault_path)
	local abs = vim.fs.normalize(name)
	return abs:sub(1, #vault + 1) == vault .. "/"
end

-- Every loaded buffer that can carry a card (a vault markdown note).
local function card_buffers()
	local out = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and is_vault_markdown(buf) then
			out[#out + 1] = buf
		end
	end
	return out
end

-- Builds the context of a buffer from the current cache and its lines.
-- Exported so the side panel renders the exact same context as the
-- inline card.
function M.context_for(buf)
	local raw = vim.api.nvim_buf_get_name(buf)
	if raw == "" then
		return nil
	end

	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	-- Completed statuses come from the cached filter-options; when the
	-- cache has no flags yet, context falls back to config.completed_statuses.
	local completed = ui.get_completed_statuses({ cached_only = true })
	if next(completed) == nil then
		completed = nil
	end

	local opts = {
		tasks = cache.data,
		lines = lines,
		completed = completed,
		generation = cache.generation,
		status_ranks = ui.get_rank_tables({ cached_only = true }),
	}

	local ctx = context.build(vim.fs.normalize(raw), opts)
	if not ctx then
		ctx = context.build(raw, opts)
	end
	return ctx
end

-- ──────────────────────────────────────────────────────────────────────
-- Public API
-- ──────────────────────────────────────────────────────────────────────

-- Draws the card for a context. The namespace is cleared first, so a
-- stale card never survives a redraw.
function M.render(buf, ctx)
	buf = buf or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)

	if not M.enabled or not ctx or ctx.fm_end_row == nil then
		return
	end

	vim.api.nvim_buf_set_extmark(buf, M.ns, ctx.fm_end_row, 0, {
		virt_lines = build_lines(ctx),
		virt_lines_above = false,
	})
end

-- Removes the card from a buffer.
function M.clear(buf)
	buf = buf or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
end

-- Redraws the card of a buffer from the current cache. Never blocks: when
-- the cache is stale an asynchronous refresh is started and the card is
-- redrawn when it lands (User TaskNotesCacheRefreshed).
function M.refresh(buf)
	buf = buf or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	M.render(buf, M.context_for(buf))

	if cache.is_stale() then
		cache.refresh_async()
	end
end

-- Global toggle: flips the card on/off for the whole session and
-- redraws (or clears) every loaded task buffer.
function M.toggle()
	M.enabled = not M.enabled

	for _, buf in ipairs(card_buffers()) do
		if M.enabled then
			M.render(buf, M.context_for(buf))
		else
			M.clear(buf)
		end
	end

	vim.notify(
		string.format("TaskNotes: inline card %s", M.enabled and "enabled" or "disabled"),
		vim.log.levels.INFO
	)
end

-- ──────────────────────────────────────────────────────────────────────
-- Autocmd wiring
--
-- The card follows the fence while the note is edited, is redrawn on
-- save and whenever the task cache is refreshed.
-- ──────────────────────────────────────────────────────────────────────
local DEBOUNCE_MS = 200

-- Debounce tokens, one per buffer.
local pending = {}

local function debounced_refresh(buf)
	pending[buf] = (pending[buf] or 0) + 1
	local token = pending[buf]
	vim.defer_fn(function()
		if pending[buf] == token then
			pending[buf] = nil
			M.refresh(buf)
		end
	end, DEBOUNCE_MS)
end

-- Registers the augroup that keeps the card in sync. Called once, after
-- the API health gate has passed.
function M.attach()
	local group = vim.api.nvim_create_augroup("TaskNotesViews", { clear = true })

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
		group = group,
		pattern = "*.md",
		callback = function(ev)
			if is_vault_markdown(ev.buf) then
				M.refresh(ev.buf)
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = group,
		pattern = "*.md",
		callback = function(ev)
			if is_vault_markdown(ev.buf) then
				debounced_refresh(ev.buf)
			end
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "TaskNotesCacheRefreshed",
		callback = function()
			for _, buf in ipairs(card_buffers()) do
				if vim.fn.bufwinid(buf) ~= -1 then
					M.render(buf, M.context_for(buf))
				end
			end
		end,
	})
end

return M
