-- TaskNotes — task CRUD: NLP create + multi-field editor (single PUT).

local config = require("tasknotes.config")
local api = require("tasknotes.api")
local cache = require("tasknotes.cache")
local ui = require("tasknotes.ui")
local util = require("tasknotes.util")

local M = {}

-- Returns the vault-relative id if the current buffer is a known task
-- (per /api/tasks). Notifies and returns nil otherwise. Tasks can live
-- anywhere in the vault as long as they carry `tag: task`.
local function require_task_buffer()
	local id, abs, vault = util.buffer_to_id()
	if not id then
		vim.notify(
			string.format("Buffer is outside the vault.\n  file:  %s\n  vault: %s", abs, vault),
			vim.log.levels.WARN
		)
		return nil
	end
	local task_paths = api.get_task_paths()
	if not task_paths or not task_paths[id] then
		vim.notify(
			string.format(
				"Buffer is not a recognized task: %s\n(Force cache refresh with <leader>or if recently added)",
				id
			),
			vim.log.levels.WARN
		)
		return nil
	end
	return id
end

-- Creates a new task via the NLP API.
M.create_task = function()
	vim.ui.input({ prompt = "Quick Add (NLP): " }, function(input)
		if not input or input == "" then
			return
		end

		-- /api/nlp/create both parses the NL string AND writes the task file
		-- server-side with the configured template. Replaces the prior
		-- /api/nlp/parse + write_frontmatter() pair (which bypassed the
		-- template and let the plugin drift from server formatting).
		local res = api.post("/nlp/create", { text = input })
		if not res or not res.success or not res.data or not res.data.task then
			return
		end

		local task = res.data.task
		local abs_path = config.vault_path .. "/" .. task.path
		vim.cmd("edit " .. vim.fn.fnameescape(abs_path))
		vim.notify("Created task: " .. (task.title or input), vim.log.levels.INFO)
		api.invalidate_caches()
		cache.invalidate_file(abs_path)
	end)
end

-- ──────────────────────────────────────────────────────────────────────
-- Shared save path.
--
-- The API rewrites the task file's frontmatter server-side, so the note
-- buffer and the file can drift apart. This helper keeps them in sync
-- without ever losing text the user has not saved:
--
--   1. write the note buffer first (its unsaved text must reach the
--      server before the file is rewritten);
--   2. PUT the patch;
--   3. reload the buffer from disk WITHOUT `edit!`, so the new
--      frontmatter shows up but no local text is discarded.
--
-- Used by the field editor (<leader>oe) and — later — by the side
-- panel, which may act on a buffer that is not the current one.
-- ──────────────────────────────────────────────────────────────────────

-- True when `buf` is a valid, loaded buffer.
local function usable_buffer(buf)
	return buf ~= nil and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf)
end

-- Finds the loaded buffer holding the task file for `id` (vault-relative
-- path). Returns nil when the note is not open.
local function find_task_buffer(id)
	local target = vim.fs.normalize(config.vault_path .. "/" .. id)
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if usable_buffer(buf) then
			local name = vim.api.nvim_buf_get_name(buf)
			if name ~= "" and vim.fs.normalize(name) == target then
				return buf
			end
		end
	end
	return nil
end

-- Applies a field patch to a task through the API.
--
-- @param id string: vault-relative path of the task (as used by the API)
-- @param patch table: the fields to update
-- @param opts table|nil: { buf = number } — the note buffer to keep in
--        sync. Defaults to the loaded buffer for that task, if any.
-- @return table|nil: the updated task, or nil when nothing was saved
M.apply_patch = function(id, patch, opts)
	opts = opts or {}
	patch = patch or {}

	local count = 0
	for _ in pairs(patch) do
		count = count + 1
	end
	if count == 0 then
		vim.notify("No changes to save", vim.log.levels.INFO)
		return nil
	end

	local buf = opts.buf
	if not buf then
		buf = find_task_buffer(id)
	end

	-- The note may hold unsaved text the server has never seen. Write it
	-- first: the PUT rewrites the file's frontmatter and the reload
	-- below would otherwise discard that text.
	if usable_buffer(buf) and vim.bo[buf].modified then
		local wrote = pcall(vim.api.nvim_buf_call, buf, function()
			vim.cmd("silent write")
		end)
		if not wrote then
			vim.notify(string.format("Could not save note: %s", id), vim.log.levels.ERROR)
			return nil
		end
	end

	local updated = api.update_task(id, patch)
	if not updated then
		vim.notify(string.format("Could not update task: %s", id), vim.log.levels.ERROR)
		return nil
	end

	-- Reload from disk WITHOUT a bang so the server's new frontmatter
	-- shows up — but only when the buffer carries no unsaved changes of
	-- its own (`:edit` would refuse them, and we must not lose them).
	if usable_buffer(buf) and not vim.bo[buf].modified then
		pcall(vim.api.nvim_buf_call, buf, function()
			vim.cmd("silent edit")
		end)
	end

	cache.invalidate_file(config.vault_path .. "/" .. id)
	cache.refresh_async()
	vim.notify(string.format("Saved %d field(s)", count), vim.log.levels.INFO)
	return updated
end

-- ──────────────────────────────────────────────────────────────────────
-- Field editor (Stage 1 = field selector, Stage 2 = value picker).
-- All changes accumulate in a patch table; Save fires a single PUT.
-- ──────────────────────────────────────────────────────────────────────

M.edit_fields = {}

M.edit_fields.open = function()
	-- Capture the buffer the editor was opened from BEFORE anything can
	-- block: the picker runs in its own window, and by the time Save
	-- fires the current buffer may be something else entirely. The save
	-- path must act on THIS note.
	local buf = vim.api.nvim_get_current_buf()
	local id = require_task_buffer()
	if not id then
		return
	end
	local task = api.get_task(id)
	if not task then
		vim.notify("Could not fetch task: " .. id, vim.log.levels.ERROR)
		return
	end
	local patch = {}
	M.edit_fields._show(id, task, patch, buf)
end

M.edit_fields._show = function(id, task, patch, buf)
	local items = {
		-- API maps `title` to the configured title-source frontmatter field
		-- (here `task:`); editing it via PUT does not rename the file.
		{
			idx = 1,
			text = string.format("Task:      %s", util.fmt_field(util.effective(task, patch, "title"))),
			action = "title",
		},
		{
			idx = 2,
			text = string.format("Status:    %s", util.fmt_field(util.effective(task, patch, "status"))),
			action = "status",
		},
		{
			idx = 3,
			text = string.format("Priority:  %s", util.fmt_field(util.effective(task, patch, "priority"))),
			action = "priority",
		},
		{
			idx = 4,
			text = string.format("Contexts:  %s", util.fmt_field(util.effective(task, patch, "contexts"))),
			action = "contexts",
		},
		{
			idx = 5,
			text = string.format("Projects:  %s", util.fmt_field(util.effective(task, patch, "projects"))),
			action = "projects",
		},
		{
			idx = 6,
			text = string.format("Tags:      %s", util.fmt_field(util.effective(task, patch, "tags"))),
			action = "tags",
		},
		{
			idx = 7,
			text = string.format("Scheduled: %s", util.fmt_field(util.effective(task, patch, "scheduled"))),
			action = "scheduled",
		},
		{
			idx = 8,
			text = string.format("Due:       %s", util.fmt_field(util.effective(task, patch, "due"))),
			action = "due",
		},
		{
			idx = 9,
			text = "─────────────────────────",
			action = "noop",
		},
		{ idx = 10, text = "✓ Save changes", action = "save" },
		{ idx = 11, text = "✗ Discard", action = "discard" },
	}

	local pending_count = 0
	for _ in pairs(patch) do
		pending_count = pending_count + 1
	end

	Snacks.picker.pick({
		source = "tasknotes_edit_fields",
		title = string.format(
			"Edit Task — %s%s",
			task.title or id,
			pending_count > 0 and string.format(" (%d unsaved)", pending_count) or ""
		),
		items = items,
		format = "text",
		preview = "none",
		layout = { hidden = { "preview" } },
		confirm = function(picker, item)
			picker:close()
			if not item or item.action == "noop" then
				vim.schedule(function()
					M.edit_fields._show(id, task, patch, buf)
				end)
				return
			end
			vim.schedule(function()
				if item.action == "save" then
					if pending_count == 0 then
						vim.notify("No changes to save", vim.log.levels.INFO)
						return
					end
					M.edit_fields._save(id, patch, buf)
				elseif item.action == "discard" then
					vim.notify("Changes discarded", vim.log.levels.INFO)
				elseif item.action == "status" or item.action == "priority" then
					M.edit_fields._pick_option(id, task, patch, item.action, buf)
				elseif item.action == "title" then
					M.edit_fields._pick_text(id, task, patch, item.action, buf)
				elseif item.action == "contexts" or item.action == "projects" or item.action == "tags" then
					M.edit_fields._pick_multi(id, task, patch, item.action, buf)
				elseif item.action == "scheduled" or item.action == "due" then
					M.edit_fields._pick_date(id, task, patch, item.action, buf)
				end
			end)
		end,
	})
end

-- Save action of the field editor. Extracted so the save path can be
-- exercised without driving the Snacks picker, and so the panel (T2)
-- can reuse the same helper.
-- @param buf number|nil: the note buffer the editor was opened from
M.edit_fields._save = function(id, patch, buf)
	return M.apply_patch(id, patch, { buf = buf })
end

-- Free-text editor for scalar string fields (e.g. `title`, which the API
-- routes to the configured title-source frontmatter field). Pre-fills the
-- current value so the user edits in place rather than retyping.
M.edit_fields._pick_text = function(id, task, patch, field, buf)
	local current = util.effective(task, patch, field)
	vim.ui.input({ prompt = field .. ": ", default = current or "" }, function(input)
		-- nil = cancelled (Esc) → leave patch untouched.
		if input ~= nil then
			patch[field] = input
		end
		M.edit_fields._show(id, task, patch, buf)
	end)
end

M.edit_fields._pick_option = function(id, task, patch, field, buf)
	local options = api.get_filter_options()
	local list = options and options[field .. "es"] or options and options[field .. "s"]
	-- statuses or priorities
	if field == "status" then
		list = options and options.statuses
	elseif field == "priority" then
		list = options and options.priorities
	end
	if not list then
		vim.notify("Could not fetch " .. field .. " options", vim.log.levels.ERROR)
		M.edit_fields._show(id, task, patch, buf)
		return
	end
	local current = util.effective(task, patch, field)
	local items = ui.build_option_items("TaskNotesEdit_" .. field, list, current)

	local confirmed = false
	Snacks.picker.pick({
		source = "tasknotes_edit_" .. field,
		title = string.format("%s (current: %s)", field, current or "none"),
		items = items,
		format = ui.color_format,
		preview = "none",
		layout = { hidden = { "preview" } },
		confirm = function(picker, item)
			confirmed = true
			picker:close()
			if item then
				patch[field] = item.value
			end
			vim.schedule(function()
				M.edit_fields._show(id, task, patch, buf)
			end)
		end,
		on_close = function()
			if not confirmed then
				vim.schedule(function()
					M.edit_fields._show(id, task, patch, buf)
				end)
			end
		end,
	})
end

M.edit_fields._pick_multi = function(id, task, patch, field, buf)
	local options = api.get_filter_options()
	local raw = options and options[field] or {}
	local current = util.effective(task, patch, field) or {}
	local current_set = {}
	for _, v in ipairs(current) do
		current_set[v] = true
	end

	-- Items are plain — Snacks renders its native selection dot for
	-- entries present in picker.list.selected (see `on_show` below).
	local items = {}
	local preselect_targets = {}
	for i, opt in ipairs(raw) do
		local item = { idx = i, text = opt, value = opt }
		table.insert(items, item)
		if current_set[opt] then
			table.insert(preselect_targets, item)
		end
	end
	table.insert(items, { idx = #items + 1, text = "+ New " .. field:sub(1, -2) .. "...", kind = "new" })

	-- Collects Tab-marked items (the FULL desired set, excluding "[+] New").
	local function collect_marks(picker)
		local values = {}
		for _, it in ipairs(picker.list.selected) do
			if it.kind ~= "new" then
				table.insert(values, it.value)
			end
		end
		return values
	end

	local confirmed = false
	Snacks.picker.pick({
		source = "tasknotes_edit_" .. field,
		title = string.format("%s — <Tab> toggle, <CR> apply", field),
		items = items,
		format = "text",
		preview = "none",
		layout = { hidden = { "preview" } },
		on_show = function(picker)
			-- Pre-mark items whose value is already in the effective set,
			-- so the user sees them with the native dot and can Tab them
			-- off (remove) or Tab additional items on (add) without
			-- losing the originals.
			picker.list:set_selected(preselect_targets)
		end,
		confirm = function(picker, single_item)
			confirmed = true
			-- "+ New ..." path: prompt for a new value and append to the
			-- currently-marked set (preserves originals + any toggles).
			if single_item and single_item.kind == "new" then
				local marks = collect_marks(picker)
				picker:close()
				vim.schedule(function()
					vim.ui.input({ prompt = "New " .. field:sub(1, -2) .. ": " }, function(input)
						if input and input ~= "" then
							table.insert(marks, input)
						end
						patch[field] = marks
						M.edit_fields._show(id, task, patch, buf)
					end)
				end)
				return
			end
			-- Regular path: apply the marked set as the new full value.
			-- An empty set is intentional (user cleared all marks).
			local values = collect_marks(picker)
			picker:close()
			patch[field] = values
			vim.schedule(function()
				M.edit_fields._show(id, task, patch, buf)
			end)
		end,
		on_close = function()
			if not confirmed then
				vim.schedule(function()
					M.edit_fields._show(id, task, patch, buf)
				end)
			end
		end,
	})
end

M.edit_fields._pick_date = function(id, task, patch, field, buf)
	local current = util.effective(task, patch, field)
	local items = util.build_calendar_items(current, true)

	local confirmed = false
	Snacks.picker.pick({
		source = "tasknotes_edit_" .. field,
		title = string.format("%s (current: %s)", field, current or "none"),
		items = items,
		format = "text",
		preview = "none",
		layout = { hidden = { "preview" } },
		confirm = function(picker, item)
			confirmed = true
			picker:close()
			if not item then
				vim.schedule(function()
					M.edit_fields._show(id, task, patch, buf)
				end)
				return
			end
			if item.kind == "clear" then
				patch[field] = ""
				vim.schedule(function()
					M.edit_fields._show(id, task, patch, buf)
				end)
			elseif item.kind == "custom" then
				vim.schedule(function()
					vim.ui.input({ prompt = "Date (YYYY-MM-DD[THH:MM]): " }, function(input)
						if input and input:match("^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d$") then
							-- Full date+time given inline → set directly, skip time stage.
							patch[field] = input
							M.edit_fields._show(id, task, patch, buf)
						elseif input and input:match("^%d%d%d%d%-%d%d%-%d%d$") then
							-- Date only → advance to the time-of-day picker.
							M.edit_fields._pick_time(id, task, patch, field, input, buf)
						elseif input and input ~= "" then
							vim.notify("Invalid format. Use YYYY-MM-DD or YYYY-MM-DDTHH:MM", vim.log.levels.ERROR)
							M.edit_fields._show(id, task, patch, buf)
						else
							M.edit_fields._show(id, task, patch, buf)
						end
					end)
				end)
			else
				-- A concrete calendar day → choose time (or all-day) in Stage 2.
				vim.schedule(function()
					M.edit_fields._pick_time(id, task, patch, field, item.value, buf)
				end)
			end
		end,
		on_close = function()
			if not confirmed then
				vim.schedule(function()
					M.edit_fields._show(id, task, patch, buf)
				end)
			end
		end,
	})
end

-- Stage 2 of date editing: pick the time-of-day for an already-chosen day.
-- "All-day" stores the bare YYYY-MM-DD; a time stores YYYY-MM-DDTHH:MM.
M.edit_fields._pick_time = function(id, task, patch, field, date_str, buf)
	local current = util.effective(task, patch, field)
	local cur_time = nil
	if current and current:sub(1, 10) == date_str then
		cur_time = current:match("T(%d%d:%d%d)")
	end
	local items = util.build_time_items(cur_time)

	local confirmed = false
	Snacks.picker.pick({
		source = "tasknotes_edit_" .. field .. "_time",
		title = string.format("%s @ %s — pick time", field, date_str),
		items = items,
		format = "text",
		preview = "none",
		layout = { hidden = { "preview" } },
		confirm = function(picker, item)
			confirmed = true
			picker:close()
			if not item or item.kind == "allday" then
				patch[field] = date_str
				vim.schedule(function()
					M.edit_fields._show(id, task, patch, buf)
				end)
			elseif item.kind == "custom" then
				vim.schedule(function()
					vim.ui.input({ prompt = "Time (HH:MM): " }, function(input)
						if input and input:match("^%d%d:%d%d$") then
							patch[field] = date_str .. "T" .. input
						elseif input and input ~= "" then
							vim.notify("Invalid time format. Use HH:MM", vim.log.levels.ERROR)
							patch[field] = date_str
						else
							patch[field] = date_str
						end
						M.edit_fields._show(id, task, patch, buf)
					end)
				end)
			else
				patch[field] = date_str .. "T" .. item.value
				vim.schedule(function()
					M.edit_fields._show(id, task, patch, buf)
				end)
			end
		end,
		on_close = function()
			if not confirmed then
				vim.schedule(function()
					M.edit_fields._show(id, task, patch, buf)
				end)
			end
		end,
	})
end

return M
