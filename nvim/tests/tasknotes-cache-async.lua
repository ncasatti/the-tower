-- TKT-101 — async cache refresh + cached-only color/rank lookups.
--
-- Headless contract test. plenary.curl is stubbed, so no request ever
-- leaves the process: the stub records every call and hands the callback
-- back to the test, which fires it to simulate async completion.
--
-- Covered:
--   1. refresh_async() returns immediately; on success the index is
--      replaced, `generation` increments and User TaskNotesCacheRefreshed
--      fires exactly once.
--   2. Two refresh_async() calls while a request is in flight → one
--      request, one event.
--   3. On failure the previous index is kept, no event fires, no ERROR
--      notification.
--   4. Filter options are refreshed asynchronously alongside the tasks.
--   5. ui cached-only lookups never touch the network; an empty cache
--      yields empty tables.
--   6. Sync ensure() and async refresh_async() produce identical
--      data/keys_index for the same payload.
--   7. A failing HTTP status or an unusable payload counts as a failure.
--   Plus: ensure() fires the event too (ADR-005 invariant), the default
--   (fetching) ui lookups still hit the API, and no scheduled callback
--   raises.

local function assert_equal(actual, expected, label)
	if actual ~= expected then
		error(string.format("%s: expected %s, got %s", label, vim.inspect(expected), vim.inspect(actual)))
	end
end

local api = require("tasknotes.api")
local cache = require("tasknotes.cache")
local ui = require("tasknotes.ui")
local config = require("tasknotes.config")

-- ──────────────────────────────────────────────────────────────────────
-- Fixture payloads
-- ──────────────────────────────────────────────────────────────────────
local TASKS = {
	{
		path = "TaskNotes/Tasks/alpha.md",
		id = "alpha",
		title = "Alpha",
		status = "in-progress",
		priority = "high",
		tags = { "work", "urgent" },
	},
	{
		path = "TaskNotes/Tasks/beta.md",
		id = "beta",
		title = "Beta",
		status = "done",
		priority = "low",
	},
}

local FILTER_OPTIONS = {
	statuses = {
		{ value = "inbox", label = "Inbox", color = "#336699", order = 1, isCompleted = false },
		{ value = "done", label = "Done", color = "#993366", order = 2, isCompleted = true },
	},
	priorities = {
		{ value = "high", label = "High", color = "#ff0000", order = 1 },
		{ value = "low", label = "Low", color = "#00ff00", order = 2 },
	},
}

local function json_for(url)
	if url:find("filter%-options") then
		return vim.fn.json_encode({ success = true, data = FILTER_OPTIONS })
	end
	return vim.fn.json_encode({ success = true, data = { tasks = TASKS } })
end

-- ──────────────────────────────────────────────────────────────────────
-- plenary.curl stub — no network, callbacks fire on demand
-- ──────────────────────────────────────────────────────────────────────
local http = { calls = {}, pending = {} }

package.loaded["plenary.curl"] = {
	get = function(url, opts)
		table.insert(http.calls, { url = url, opts = opts })
		if opts and opts.callback then
			table.insert(http.pending, { url = url, opts = opts })
			return nil -- plenary hands back the job handle
		end
		return { status = 200, body = json_for(url) }
	end,
}

-- Notification capture (levels matter: a failure must stay below ERROR).
local notifications = {}
vim.notify = function(msg, level)
	table.insert(notifications, { msg = msg, level = level })
end

-- Error capture. An exception thrown inside a vim.schedule callback is
-- written to stderr by Neovim but does NOT abort the script — it would
-- otherwise slip past every assertion below (and wedge the cache's
-- in-flight flag). Wrap vim.schedule so those errors land in `errors`
-- and the test can fail loudly on them.
local errors = {}
local real_schedule = vim.schedule
vim.schedule = function(fn)
	return real_schedule(function()
		local ok, err = pcall(fn)
		if not ok then
			table.insert(errors, { msg = tostring(err) })
		end
	end)
end

-- Event counter for User TaskNotesCacheRefreshed.
local events = 0
vim.api.nvim_create_autocmd("User", {
	pattern = "TaskNotesCacheRefreshed",
	callback = function()
		events = events + 1
	end,
})

local function reset()
	cache.data = {}
	cache.keys_index = {}
	cache.last_full_scan = 0
	cache.generation = 0
	cache.refresh_in_flight = false
	api._filter_options_cache = nil
	api._task_paths_cache = nil
	events = 0
	notifications = {}
	errors = {}
	http.calls = {}
	http.pending = {}
end

-- Asserts that no scheduled callback raised. Called at the end of each
-- section — a swallowed exception must not pass as success.
local function assert_no_errors(label)
	for _, e in ipairs(errors) do
		error(string.format("%s: unexpected error in scheduled callback: %s", label, e.msg))
	end
end

local function requests_to(fragment)
	local n = 0
	for _, call in ipairs(http.calls) do
		if call.url:find(fragment, 1, true) then
			n = n + 1
		end
	end
	return n
end

-- Fires the recorded callback of the first pending request matching
-- `fragment` (simulates the async response landing).
local function fire(fragment, res)
	for i, req in ipairs(http.pending) do
		if req.url:find(fragment, 1, true) then
			table.remove(http.pending, i)
			req.opts.callback(res)
			return true
		end
	end
	return false
end

local alpha = config.vault_path .. "/TaskNotes/Tasks/alpha.md"
local beta = config.vault_path .. "/TaskNotes/Tasks/beta.md"

-- ──────────────────────────────────────────────────────────────────────
-- 1. refresh_async() returns immediately; success swaps the index,
--    bumps `generation` and fires User TaskNotesCacheRefreshed once.
-- ──────────────────────────────────────────────────────────────────────
reset()
cache.refresh_async()

assert_equal(requests_to("/tasks"), 1, "refresh_async issues one task request")
assert_equal(requests_to("/filter-options"), 1, "refresh_async also refreshes filter options")
assert_equal(next(cache.data), nil, "index untouched before the response lands")
assert_equal(cache.generation, 0, "generation unchanged before the response lands")
assert_equal(events, 0, "no event before the response lands")
assert_equal(cache.refresh_in_flight, true, "refresh is marked in flight")

assert_equal(fire("/tasks", { status = 200, body = json_for("http://localhost:8080/api/tasks") }), true, "task response fired")
vim.wait(200, function()
	return events > 0
end)

assert_equal(events, 1, "exactly one TaskNotesCacheRefreshed event")
assert_equal(cache.generation, 1, "generation incremented")
assert_equal(cache.data[alpha] ~= nil, true, "index contains the refreshed task")
assert_equal(cache.data[beta] ~= nil, true, "index contains every refreshed task")
assert_equal(cache.keys_index.status["in-progress"][1], alpha, "keys_index indexes status")
assert_equal(cache.keys_index.tags.urgent[1], alpha, "keys_index indexes list values")
assert_equal(cache.keys_index.title, nil, "keys_index skips non-metadata fields")
assert_equal(cache.refresh_in_flight, false, "in-flight flag cleared after success")
assert_no_errors("async success")

-- ──────────────────────────────────────────────────────────────────────
-- 2. Two refresh_async() calls while in flight → one request, one event
-- ──────────────────────────────────────────────────────────────────────
reset()
cache.refresh_async()
cache.refresh_async()
assert_equal(requests_to("/tasks"), 1, "in-flight refresh is coalesced")
assert_equal(requests_to("/filter-options"), 1, "in-flight refresh coalesces the filter-options request too")

assert_equal(fire("/tasks", { status = 200, body = json_for("http://localhost:8080/api/tasks") }), true, "task response fired")
vim.wait(200, function()
	return events > 0
end)
assert_equal(events, 1, "coalesced refresh fires exactly one event")
assert_equal(cache.generation, 1, "coalesced refresh increments generation once")
assert_no_errors("coalesced refresh")

-- ──────────────────────────────────────────────────────────────────────
-- 3. Failure keeps the previous index, fires no event, notifies below
--    ERROR.
-- ──────────────────────────────────────────────────────────────────────
reset()
-- Snapshot the previous index by value: an in-place mutation of the old
-- index must be caught too, not just a wholesale replacement.
local stale_data = { ["/old.md"] = { fm = { title = "Old" }, mtime = 0 } }
local stale_index = { status = { done = { "/old.md" } } }
local expected_data = vim.deepcopy(stale_data)
local expected_index = vim.deepcopy(stale_index)
cache.data = stale_data
cache.keys_index = stale_index
cache.generation = 7

cache.refresh_async()
assert_equal(fire("/tasks", { status = 500, body = "" }), true, "failed task response fired")
vim.wait(200, function()
	return cache.refresh_in_flight == false
end)

assert_equal(vim.deep_equal(cache.data, expected_data), true, "previous index kept on failure")
assert_equal(vim.deep_equal(cache.keys_index, expected_index), true, "previous keys_index kept on failure")
assert_equal(cache.generation, 7, "generation unchanged on failure")
assert_equal(events, 0, "no event on failure")
assert_equal(cache.refresh_in_flight, false, "in-flight flag cleared after failure")
for _, n in ipairs(notifications) do
	assert(n.level ~= vim.log.levels.ERROR, "failure must not notify at ERROR level: " .. tostring(n.msg))
end

-- The failed refresh must not wedge the cache: a new attempt is allowed.
cache.refresh_async()
assert_equal(requests_to("/tasks"), 2, "a new refresh is possible after a failure")
assert_equal(fire("/tasks", { status = 200, body = json_for("http://localhost:8080/api/tasks") }), true, "retry response fired")
vim.wait(200, function()
	return events > 0
end)
assert_equal(events, 1, "the retry fires the event")
assert_no_errors("failure then retry")

-- ──────────────────────────────────────────────────────────────────────
-- 4. Filter options are refreshed asynchronously alongside the tasks
-- ──────────────────────────────────────────────────────────────────────
reset()
cache.refresh_async()
assert_equal(requests_to("/filter-options"), 1, "filter options are requested")
assert_equal(api._filter_options_cache, nil, "filter options cache still empty before the response lands")

assert_equal(fire("/filter-options", { status = 200, body = json_for("http://localhost:8080/api/filter-options") }), true, "filter-options response fired")
vim.wait(200, function()
	return api._filter_options_cache ~= nil
end)

assert_equal(api._filter_options_cache ~= nil, true, "filter options cache populated")
assert_equal(api._filter_options_cache.data.statuses[1].value, "inbox", "filter options payload stored")
assert_equal(type(api._filter_options_cache.fetched_at), "number", "filter options cache is timestamped")
assert_no_errors("filter options refresh")

-- ──────────────────────────────────────────────────────────────────────
-- 5. Cached-only lookups never hit the network
-- ──────────────────────────────────────────────────────────────────────
reset()
api._filter_options_cache = { data = FILTER_OPTIONS, fetched_at = os.time() }
local calls_before = #http.calls

local status_ranks, priority_ranks = ui.get_rank_tables({ cached_only = true })
assert_equal(#http.calls, calls_before, "cached-only rank lookup performs no request")
assert_equal(status_ranks.inbox, 1, "cached-only status rank")
assert_equal(status_ranks.done, 2, "cached-only status rank")
assert_equal(priority_ranks.high, 2, "cached-only priority rank is inverted")
assert_equal(priority_ranks.low, 1, "cached-only priority rank is inverted")

local status_colors, priority_colors = ui.get_color_tables({ cached_only = true })
assert_equal(#http.calls, calls_before, "cached-only color lookup performs no request")
assert_equal(status_colors.inbox, "#336699", "cached-only status color")
assert_equal(priority_colors.high, "#ff0000", "cached-only priority color")

-- Empty cache → empty tables, still no request.
api._filter_options_cache = nil
local empty_ranks, empty_priority_ranks = ui.get_rank_tables({ cached_only = true })
local empty_colors, empty_priority_colors = ui.get_color_tables({ cached_only = true })
assert_equal(#http.calls, calls_before, "empty cached-only lookup performs no request")
assert_equal(vim.tbl_count(empty_ranks), 0, "empty cache yields empty status ranks")
assert_equal(vim.tbl_count(empty_priority_ranks), 0, "empty cache yields empty priority ranks")
assert_equal(vim.tbl_count(empty_colors), 0, "empty cache yields empty status colors")
assert_equal(vim.tbl_count(empty_priority_colors), 0, "empty cache yields empty priority colors")

-- The default (fetching) lookups keep their old behavior.
local live_ranks = ui.get_rank_tables()
assert_equal(#http.calls, calls_before + 1, "default rank lookup still fetches")
assert_equal(live_ranks.inbox, 1, "default rank lookup still resolves ranks")
assert_no_errors("cached-only lookups")

-- ──────────────────────────────────────────────────────────────────────
-- 6. Sync ensure() and async refresh_async() index identically
-- ──────────────────────────────────────────────────────────────────────
reset()
cache.ensure()
local sync_data = vim.deepcopy(cache.data)
local sync_index = vim.deepcopy(cache.keys_index)
assert_equal(vim.tbl_count(sync_data), 2, "ensure() indexed both tasks")
-- ADR-005 invariant: every cache mutation path announces itself.
assert_equal(events, 1, "ensure() fires TaskNotesCacheRefreshed")
assert_equal(cache.generation, 1, "ensure() increments the generation")

reset()
cache.refresh_async()
assert_equal(fire("/tasks", { status = 200, body = json_for("http://localhost:8080/api/tasks") }), true, "task response fired")
vim.wait(200, function()
	return events > 0
end)

assert_equal(vim.deep_equal(sync_data, cache.data), true, "sync and async produce identical data")
assert_equal(vim.deep_equal(sync_index, cache.keys_index), true, "sync and async produce identical keys_index")
assert_no_errors("sync vs async")

-- ──────────────────────────────────────────────────────────────────────
-- 7. A failing HTTP status or an unusable payload counts as a failure
--    (keeps the old index, no event, no ERROR notification).
-- ──────────────────────────────────────────────────────────────────────
reset()
local keep_data = { ["/keep.md"] = { fm = { title = "Keep" }, mtime = 0 } }
local keep_index = { status = { done = { "/keep.md" } } }
cache.data = keep_data
cache.keys_index = keep_index
cache.generation = 3
-- Snapshot by value so an in-place mutation is caught too.
local expected_keep_data = vim.deepcopy(keep_data)
local expected_keep_index = vim.deepcopy(keep_index)

-- A 500 response whose body happens to be a valid tasks payload must
-- still be treated as a failure — the status code decides.
cache.refresh_async()
assert_equal(
	fire("/tasks", { status = 500, body = json_for("http://localhost:8080/api/tasks") }),
	true,
	"500 response fired"
)
vim.wait(200, function()
	return cache.refresh_in_flight == false
end)

assert_equal(vim.deep_equal(cache.data, expected_keep_data), true, "500 response keeps the previous index")
assert_equal(vim.deep_equal(cache.keys_index, expected_keep_index), true, "500 response keeps the previous keys_index")
assert_equal(cache.generation, 3, "500 response leaves the generation alone")
assert_equal(events, 0, "500 response fires no event")
assert_no_errors("500 response")

-- A 200 response carrying an unusable payload is a failure too.
reset()
cache.data = keep_data
cache.keys_index = keep_index
cache.generation = 3

cache.refresh_async()
assert_equal(
	fire("/tasks", { status = 200, body = vim.fn.json_encode({ success = false, error = "boom" }) }),
	true,
	"unusable payload fired"
)
vim.wait(200, function()
	return cache.refresh_in_flight == false
end)

assert_equal(vim.deep_equal(cache.data, expected_keep_data), true, "unusable payload keeps the previous index")
assert_equal(vim.deep_equal(cache.keys_index, expected_keep_index), true, "unusable payload keeps the previous keys_index")
assert_equal(cache.generation, 3, "unusable payload leaves the generation alone")
assert_equal(events, 0, "unusable payload fires no event")
for _, n in ipairs(notifications) do
	assert(n.level ~= vim.log.levels.ERROR, "unusable payload must not notify at ERROR level: " .. tostring(n.msg))
end
assert_no_errors("unusable payload")

print("tasknotes cache async: ok")
