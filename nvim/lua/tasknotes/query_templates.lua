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

-- True when scheduled OR due is on or before today (inclusive).
local function today_filter(metadata)
	local today = today_iso()
	local sched = date_prefix(metadata.scheduled)
	local due = date_prefix(metadata.due)
	if sched and sched <= today then
		return true
	end
	if due and due <= today then
		return true
	end
	return false
end

-- True when scheduled OR due is strictly before today.
local function overdue_filter(metadata)
	local today = today_iso()
	local sched = date_prefix(metadata.scheduled)
	local due = date_prefix(metadata.due)
	if sched and sched < today then
		return true
	end
	if due and due < today then
		return true
	end
	return false
end

M.templates = {
	{
		name = "Today",
		desc = "Scheduled or due on/before today",
		filter = today_filter,
	},
	{
		name = "Overdue",
		desc = "Scheduled or due strictly before today",
		filter = overdue_filter,
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
