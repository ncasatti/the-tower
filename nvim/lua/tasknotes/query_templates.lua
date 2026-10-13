-- TaskNotes — query templates: pre-canned filters with a Snacks picker submenu.
--
-- Each template is a { name, desc, filter } record. The filter is a closure
-- over a snapshot of today's date (calculated at invocation time) that takes
-- a task metadata table and returns a boolean. We pass it directly to
-- query.find_tasks, which accepts either an API query table or a filter fn.
--
-- Date semantics: ISO YYYY-MM-DD strings are lexicographically order-preserving
-- for dates, so `<=` / `<` on the first 10 chars is a valid comparison. Tasks
-- without a `scheduled` AND without a `due` field are excluded from every
-- template (no date = no anchor for the predicate).
--
-- All date arithmetic goes through M._add_days / M._month_bounds so we don't
-- drag the standard library's os.time()/os.date() parsing edge cases (locale,
-- DST) into per-template closures. A single, well-tested helper beats four
-- near-duplicate ones.

local query = require("tasknotes.query")

local M = {}

-- Returns today's date as YYYY-MM-DD. Snapshotted at call time so
-- pickers held open across midnight don't silently shift results.
local function today_iso()
	return os.date("%Y-%m-%d")
end

-- Extracts a YYYY-MM-DD prefix from an ISO string (handles "T" timestamps).
local function date_prefix(value)
	if type(value) ~= "string" then
		return nil
	end
	return value:sub(1, 10)
end

-- Adds `days` (integer, may be negative) to a YYYY-MM-DD string and returns
-- the result as YYYY-MM-DD. Goes through os.time so DST/locale handling
-- follows whatever the system thinks "add 1 day to March 14" means (which
-- is what users actually expect when the time component of the input is
-- 00:00:00 local).
M._add_days = function(iso_date, days)
	local y, m, d = iso_date:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
	if not y then
		return iso_date
	end
	local t = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 })
	return os.date("%Y-%m-%d", t + days * 86400)
end

-- Returns the {first, last} YYYY-MM-DD bounds of the calendar month
-- containing `iso_date`. E.g. 2026-03-15 → {"2026-03-01", "2026-03-31"}.
-- We add 32 days and re-derive the first day of THAT month, then subtract
-- one day — cleaner than the 12-element leap-year table and works for
-- any year without a lookup.
M._month_bounds = function(iso_date)
	local y, m = iso_date:match("^(%d%d%d%d)-(%d%d)")
	if not y then
		return iso_date, iso_date
	end
	local year, month = tonumber(y), tonumber(m)
	-- First day of the month containing iso_date.
	local first = string.format("%04d-%02d-01", year, month)
	-- First day of the NEXT month.
	local next_first
	if month == 12 then
		next_first = string.format("%04d-01-01", year + 1)
	else
		next_first = string.format("%04d-%02d-01", year, month + 1)
	end
	-- Last day of the current month = day before next month.
	local last = M._add_days(next_first, -1)
	return first, last
end

-- Returns the effective date of a task as a YYYY-MM-DD string. Prefer
-- `scheduled` (when you plan to do it) over `due` (hard deadline) — the
-- existing query builder uses the same precedence in util.effective_date,
-- but we don't import that here to keep query_templates free of util's
-- requirement that the rest of the plugin be set up. Tasks with neither
-- field return nil and the predicate below filters them out.
local function effective_date(metadata)
	local s = date_prefix(metadata.scheduled)
	if s then
		return s
	end
	return date_prefix(metadata.due)
end

-- True when the task's effective date is exactly today. Past-dated tasks
-- belong in Overdue; future-dated tasks belong in Week/Month. Day-boundary
-- semantics: a task due "2026-10-05" is Today on 2026-10-05 only.
local function today_filter(metadata)
	local d = effective_date(metadata)
	return d ~= nil and d == today_iso()
end

-- True when the task's effective date is strictly before today.
local function overdue_filter(metadata)
	local d = effective_date(metadata)
	return d ~= nil and d < today_iso()
end

-- True when the task's effective date is in the next 7 days, inclusive of
-- today. Endpoints: [today, today + 6] — the same window most calendar
-- apps call "this week" when you open them mid-week. Tasks with a date in
-- the past (overdue) are EXCLUDED — they belong in the Overdue template.
local function week_filter(metadata)
	local d = effective_date(metadata)
	if not d then
		return false
	end
	local today = today_iso()
	if d < today then
		return false
	end
	local week_end = M._add_days(today, 6)
	return d <= week_end
end

-- True when the task's effective date falls within the calendar month
-- containing today. Month boundaries are inclusive on both ends. Like
-- week_filter, past-dated tasks (overdue from previous months) are
-- excluded — Overdue already covers them.
local function month_filter(metadata)
	local d = effective_date(metadata)
	if not d then
		return false
	end
	local today = today_iso()
	if d < today then
		return false
	end
	local first, last = M._month_bounds(today)
	return d >= first and d <= last
end

M.templates = {
	{
		name = "Today",
		desc = "Effective date equal to today",
		filter = today_filter,
	},
	{
		name = "Overdue",
		desc = "Effective date strictly before today",
		filter = overdue_filter,
	},
	{
		name = "Week",
		desc = "Effective date in the next 7 days, inclusive (today through today+6)",
		filter = week_filter,
	},
	{
		name = "Month",
		desc = "Effective date within the current calendar month, inclusive",
		filter = month_filter,
	},
}

-- Open the templates submenu (Snacks picker). On confirm, hands the chosen
-- filter to query.find_tasks, which renders the results with the standard
-- task row format. find_tasks queries the API directly, so no cache warm-up
-- is needed here.
function M.open()
	local items = {}
	for i, template in ipairs(M.templates) do
		items[i] = {
			idx = i,
			text = string.format("%s — %s", template.name, template.desc),
			template = template,
		}
	end

	Snacks.picker.pick({
		source = "tasknotes_query_templates",
		title = "Query Templates",
		items = items,
		format = "text",
		preview = "none",
		layout = { hidden = { "preview" } },
		confirm = function(picker, item)
			picker:close()
			if item and item.template then
				query.find_tasks(item.template.filter)
			end
		end,
	})
end

return M
