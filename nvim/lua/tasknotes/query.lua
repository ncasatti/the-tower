-- TaskNotes — query system: filter builder, task finder, interactive builder.

local config = require("tasknotes.config")
local api = require("tasknotes.api")
local cache = require("tasknotes.cache")
local ui = require("tasknotes.ui")
local util = require("tasknotes.util")

local M = {}

-- Builds a filter function from a query parameter table.
-- Query params: { status, priority, contexts, scheduled_before, scheduled_after }
M.build_query_filter = function(query)
	return function(metadata)
		if query.status and #query.status > 0 then
			local status_val = metadata.status
			if type(status_val) == "table" then
				status_val = status_val[1]
			end
			local match = false
			for _, s in ipairs(query.status) do
				if status_val == s then
					match = true
					break
				end
			end
			if not match then
				return false
			end
		end

		if query.priority and #query.priority > 0 then
			local priority_val = metadata.priority
			if type(priority_val) == "table" then
				priority_val = priority_val[1]
			end
			local match = false
			for _, p in ipairs(query.priority) do
				if priority_val == p then
					match = true
					break
				end
			end
			if not match then
				return false
			end
		end

		if query.contexts and #query.contexts > 0 then
			if not metadata.contexts then
				return false
			end
			local ctx_list = metadata.contexts
			if type(ctx_list) == "string" then
				ctx_list = { ctx_list }
			end
			local match = false
			for _, qc in ipairs(query.contexts) do
				for _, mc in ipairs(ctx_list) do
					if mc == qc then
						match = true
						break
					end
				end
				if match then
					break
				end
			end
			if not match then
				return false
			end
		end

		-- Date range filters: a missing `scheduled` field is treated as
		-- unknown (SQL NULL semantics) and excluded when a bound is set.
		-- Bounds are inclusive: scheduled_after = "on or after",
		-- scheduled_before = "on or before". Comparison is lexicographic
		-- on ISO YYYY-MM-DD prefixes, which is order-preserving for dates.
		if query.scheduled_after or query.scheduled_before then
			if not metadata.scheduled then
				return false
			end
			local sched = tostring(metadata.scheduled):sub(1, 10)
			if query.scheduled_after and sched < query.scheduled_after then
				return false
			end
			if query.scheduled_before and sched > query.scheduled_before then
				return false
			end
		end

		return true
	end
end

-- Finds tasks using the API and opens a Snacks picker.
-- @param query_or_filter table|function|nil: API FilterQuery OR legacy filter function
-- @param filter_fn function|nil: Legacy filter function (if first arg is api_query)
M.find_tasks = function(query_or_filter, filter_fn)
	local api_query, final_filter
	if type(query_or_filter) == "function" then
		final_filter = query_or_filter
	else
		api_query = query_or_filter
		final_filter = filter_fn
	end

	local tasks = {}
	if api_query then
		tasks = api.query_tasks(api_query) or {}
	else
		local all_tasks = api.query_tasks(nil) or {}
		if final_filter then
			-- API returns flat objects (status/priority/etc. at top level), not nested under frontmatter.
			for _, t in ipairs(all_tasks) do
				if final_filter(t) then
					table.insert(tasks, t)
				end
			end
		else
			tasks = all_tasks
		end
	end

	local status_ranks, priority_ranks = ui.get_rank_tables()
	local status_colors, priority_colors = ui.get_color_tables()

	local items = {}
	for _, task in ipairs(tasks) do
		local fm = task
		local status_val = fm.status
		if type(status_val) == "table" then
			status_val = status_val[1]
		end
		local priority_val = fm.priority
		if type(priority_val) == "table" then
			priority_val = priority_val[1]
		end

		local abs_path = config.vault_path .. "/" .. task.path
		local title = util.task_title(fm, abs_path)

		local time_info, time_hl = util.due_info(fm.due, fm.scheduled)

		table.insert(items, {
			-- `text` drives fuzzy matching; the visible row is ui.task_row_format.
			text = string.format("%s %s %s", title, status_val or "", priority_val or ""),
			file = abs_path,
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

	if #items == 0 then
		vim.notify("No tasks found", vim.log.levels.INFO)
		return
	end

	table.sort(items, util.compare_task_items)
	for i, item in ipairs(items) do
		item.idx = i
	end

	Snacks.picker.pick({
		source = "tasknotes_find",
		title = "TaskNotes",
		items = items,
		format = ui.task_row_format,
		preview = "file",
		confirm = function(picker, item)
			picker:close()
			if item then
				vim.cmd("edit " .. vim.fn.fnameescape(item.file))
			end
		end,
	})
end

-- ──────────────────────────────────────────────────────────────────────
-- Interactive query builder (field-selector pattern)
--
-- UX: Stage 1 = field selector (status, priority, contexts, dates, apply, reset)
--     Stage 2 = picker for that field's values (multi-select via <Tab> for list fields,
--               calendar picker for date fields). On close → back to Stage 1.
--     Apply  = builds filter and calls M.find_tasks.
-- ──────────────────────────────────────────────────────────────────────
M.query_builder = {}

M.query_builder.open = function()
	cache.ensure()
	local query = { status = {}, priority = {}, contexts = {} }
	M.query_builder._show_fields(query)
end

M.query_builder._show_fields = function(query)
	local items = {
		{ idx = 1, text = string.format("Status:           %s", util.fmt_list(query.status)), action = "status" },
		{ idx = 2, text = string.format("Priority:         %s", util.fmt_list(query.priority)), action = "priority" },
		{ idx = 3, text = string.format("Contexts:         %s", util.fmt_list(query.contexts)), action = "contexts" },
		{
			idx = 4,
			text = string.format("Scheduled on/after:  %s", query.scheduled_after or "none"),
			action = "scheduled_after",
		},
		{
			idx = 5,
			text = string.format("Scheduled on/before: %s", query.scheduled_before or "none"),
			action = "scheduled_before",
		},
		{
			idx = 6,
			text = "─────────────────────────",
			action = "noop",
		},
		{ idx = 7, text = "✓ Apply query", action = "apply" },
		{ idx = 8, text = "✗ Reset filters", action = "reset" },
	}

	Snacks.picker.pick({
		source = "tasknotes_query_builder",
		title = "Query Builder",
		items = items,
		format = "text",
		preview = "none",
		layout = { hidden = { "preview" } },
		confirm = function(picker, item)
			picker:close()
			if not item or item.action == "noop" then
				vim.schedule(function()
					M.query_builder._show_fields(query)
				end)
				return
			end
			vim.schedule(function()
				if item.action == "apply" then
					local filter = M.build_query_filter(query)
					M.find_tasks(filter)
				elseif item.action == "reset" then
					M.query_builder._show_fields({ status = {}, priority = {}, contexts = {} })
				elseif item.action == "status" then
					local opts = api.get_filter_options()
					local statuses = (opts and opts.statuses) or {}
					M.query_builder._pick_multi(query, "status", statuses, "Status")
				elseif item.action == "priority" then
					local opts = api.get_filter_options()
					local priorities = (opts and opts.priorities) or {}
					M.query_builder._pick_multi(query, "priority", priorities, "Priority")
				elseif item.action == "contexts" then
					local opts = api.get_filter_options()
					local raw = (opts and opts.contexts) or {}
					-- /api/filter-options returns contexts as plain strings.
					local ctx_opts = {}
					for _, c in ipairs(raw) do
						table.insert(ctx_opts, { value = c, label = c })
					end
					M.query_builder._pick_multi(query, "contexts", ctx_opts, "Contexts")
				elseif item.action == "scheduled_after" or item.action == "scheduled_before" then
					M.query_builder._pick_date(query, item.action)
				end
			end)
		end,
	})
end

-- @param options table: list of either strings or {value, label, color, order} objects
M.query_builder._pick_multi = function(query, field, options, label)
	if #options == 0 then
		vim.notify("No options available for " .. field, vim.log.levels.WARN)
		vim.schedule(function()
			M.query_builder._show_fields(query)
		end)
		return
	end

	local current_set = {}
	for _, v in ipairs(query[field] or {}) do
		current_set[v] = true
	end

	local items = {}
	for i, opt in ipairs(options) do
		-- Support both string options and {value, label, color, order} option objects.
		local value, display, color, order
		if type(opt) == "string" then
			value, display = opt, opt
		else
			value = opt.value
			display = opt.label or opt.value
			color = opt.color
			order = opt.order
		end
		local marker = current_set[value] and "[x] " or "[ ] "
		local hl = ui.ensure_color_hl("TaskNotesQuery_" .. field, value, color)
		table.insert(items, {
			idx = i,
			text = marker .. display,
			value = value,
			hl = hl,
			order = order or i,
		})
	end
	table.sort(items, function(a, b)
		return (a.order or 99) < (b.order or 99)
	end)
	for i, item in ipairs(items) do
		item.idx = i
	end

	local confirmed = false
	Snacks.picker.pick({
		source = "tasknotes_query_multi",
		title = string.format("%s — <Tab> select, <CR> apply", label),
		items = items,
		format = ui.color_format,
		preview = "none",
		layout = { hidden = { "preview" } },
		confirm = function(picker)
			confirmed = true
			local selected = picker:selected({ fallback = true })
			local values = {}
			for _, item in ipairs(selected) do
				table.insert(values, item.value)
			end
			query[field] = values
			picker:close()
			vim.schedule(function()
				M.query_builder._show_fields(query)
			end)
		end,
		on_close = function()
			if not confirmed then
				vim.schedule(function()
					M.query_builder._show_fields(query)
				end)
			end
		end,
	})
end

M.query_builder._pick_date = function(query, field)
	local current = query[field]
	local items = util.build_calendar_items(current, true)

	local confirmed = false
	Snacks.picker.pick({
		source = "tasknotes_query_date",
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
					M.query_builder._show_fields(query)
				end)
				return
			end
			if item.kind == "clear" then
				query[field] = nil
				vim.schedule(function()
					M.query_builder._show_fields(query)
				end)
			elseif item.kind == "custom" then
				vim.schedule(function()
					vim.ui.input({ prompt = "Date (YYYY-MM-DD): " }, function(input)
						if input and input:match("^%d%d%d%d%-%d%d%-%d%d$") then
							query[field] = input
						elseif input and input ~= "" then
							vim.notify("Invalid date format. Use YYYY-MM-DD", vim.log.levels.ERROR)
						end
						M.query_builder._show_fields(query)
					end)
				end)
			else
				query[field] = item.value
				vim.schedule(function()
					M.query_builder._show_fields(query)
				end)
			end
		end,
		on_close = function()
			if not confirmed then
				vim.schedule(function()
					M.query_builder._show_fields(query)
				end)
			end
		end,
	})
end

return M
