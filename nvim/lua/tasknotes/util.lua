-- TaskNotes — pure helpers (no Snacks / API at load time).
-- Depends only on config (for the vault path in buffer_to_id).

local config = require("tasknotes.config")

local M = {}

-- Calculates days remaining until a YYYY-MM-DD date.
function M.get_days_until(date_str)
	if not date_str or date_str == "" then
		return nil
	end
	-- Support both YYYY-MM-DD and full ISO strings
	local y, m, d = date_str:match("(%d+)-(%d+)-(%d+)")
	if not y or not m or not d then
		return nil
	end

	local target_time =
		os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0, min = 0, sec = 0 })
	local now = os.time()
	local diff = os.difftime(target_time, now)
	local days = math.ceil(diff / 86400)
	return days
end

-- Renders the due/scheduled suffix for a task row plus the highlight to use.
-- Faithful to the legacy strings; adds an emphasis hl for urgent dates.
-- @return string suffix (leading space, or ""), string highlight group
function M.due_info(due, scheduled)
	local days_due = M.get_days_until(due)
	local days_sched = M.get_days_until(scheduled)
	if days_due then
		if days_due == 0 then
			return " (DUE TODAY)", "DiagnosticError"
		elseif days_due < 0 then
			return string.format(" (%dd OVERDUE)", math.abs(days_due)), "DiagnosticError"
		end
		return string.format(" (%dd until due)", days_due), "Comment"
	elseif days_sched then
		if days_sched == 0 then
			return " (Sched: Today)", "DiagnosticWarn"
		elseif days_sched < 0 then
			return string.format(" (%dd ago)", math.abs(days_sched)), "Comment"
		end
		return string.format(" (%dd until sched)", days_sched), "Comment"
	end
	return "", "Comment"
end

-- Converts the current buffer's absolute path to a vault-relative id.
-- Returns (id, abs, vault) on success, (nil, abs, vault) when outside.
function M.buffer_to_id()
	local abs = vim.fs.normalize(vim.fn.expand("%:p"))
	local vault = vim.fs.normalize(config.vault_path)
	-- Plain prefix check (no vim.pesc — that breaks with paths containing . or -)
	local prefix = vault .. "/"
	if abs:sub(1, #prefix) ~= prefix then
		return nil, abs, vault
	end
	return abs:sub(#prefix + 1), abs, vault
end

-- Returns the effective value for a field (patch wins over original).
function M.effective(task, patch, field)
	if patch[field] ~= nil then
		return patch[field]
	end
	return task[field]
end

-- Renders a frontmatter value (scalar / list / nil) for display.
function M.fmt_field(value)
	if value == nil or value == "" then
		return "none"
	end
	if type(value) == "table" then
		if #value == 0 then
			return "none"
		end
		return table.concat(value, ", ")
	end
	return tostring(value)
end

-- Renders a list value for the query builder ("none" when empty).
function M.fmt_list(t)
	if not t or #t == 0 then
		return "none"
	end
	return table.concat(t, ", ")
end

-- Builds the item list for a 60-day calendar picker.
-- @param current string|nil: currently selected date (renders a marker)
-- @param include_clear boolean: prepend a "Clear" option
function M.build_calendar_items(current, include_clear)
	local day_names = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
	local items = {}
	if include_clear then
		table.insert(items, { text = "  [x] Clear", kind = "clear" })
	end
	table.insert(items, { text = "  [+] Custom date (YYYY-MM-DD)...", kind = "custom" })

	local today_ts = os.time()
	for offset = 0, 60 do
		local ts = today_ts + offset * 86400
		local date_str = os.date("%Y-%m-%d", ts)
		local day_name = day_names[tonumber(os.date("%w", ts)) + 1]
		local label
		if offset == 0 then
			label = "Today"
		elseif offset == 1 then
			label = "Tomorrow"
		elseif offset < 7 then
			label = string.format("In %d days", offset)
		elseif offset == 7 then
			label = "Next week"
		elseif offset % 7 == 0 then
			label = string.format("In %d weeks", math.floor(offset / 7))
		else
			label = string.format("+%dd", offset)
		end
		-- current may carry a THH:MM suffix (edit_fields); match on the
		-- date prefix so the day marker still renders.
		local cur_date = current and current:sub(1, 10)
		local marker = (date_str == cur_date) and "● " or "  "
		table.insert(items, {
			text = string.format("%s%s %s — %s", marker, day_name, date_str, label),
			value = date_str,
			kind = "date",
		})
	end
	for i, item in ipairs(items) do
		item.idx = i
	end
	return items
end

-- Builds the item list for the time-of-day picker (Stage 2 of date edit).
-- @param current_time string|nil: currently selected "HH:MM" (renders a marker)
function M.build_time_items(current_time)
	local items = {
		{ text = "  [x] All-day (no time)", kind = "allday" },
		{ text = "  [+] Custom time (HH:MM)...", kind = "custom" },
	}
	-- Full 24h grid in 15-minute steps (00:00 → 23:45); filter by typing.
	for h = 0, 23 do
		for _, m in ipairs({ 0, 15, 30, 45 }) do
			local t = string.format("%02d:%02d", h, m)
			local marker = (t == current_time) and "● " or "  "
			table.insert(items, { text = marker .. t, value = t, kind = "time" })
		end
	end
	for i, item in ipairs(items) do
		item.idx = i
	end
	return items
end

return M
