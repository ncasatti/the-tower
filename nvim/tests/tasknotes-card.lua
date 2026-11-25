-- TKT-102 — inline task card (renderer + toggle).
--
-- Headless contract test. plenary.curl is stubbed to error, so any
-- request that escapes the render path fails the test loudly.
--
-- Covered:
--   1. The card is drawn as virt_lines in its own namespace, anchored on
--      the closing `---`; the buffer text is untouched (`modified` stays
--      false).
--   2. The card follows the fence when lines are inserted above it.
--   3. Toggling off clears the namespace in every loaded task buffer;
--      toggling on redraws it.
--   4. A stale cache triggers cache.refresh_async (spied) but never
--      blocks: the card is drawn from the current cache and no request
--      happens synchronously.
--   5. Neither context.lua nor card.lua requires tasknotes.api,
--      tasknotes.task_ops or plenary.curl (require-set test).

local function assert_equal(actual, expected, label)
	if actual ~= expected then
		error(string.format("%s: expected %s, got %s", label, vim.inspect(expected), vim.inspect(actual)))
	end
end

local function assert_true(value, label)
	if not value then
		error(string.format("%s: expected true, got %s", label, vim.inspect(value)))
	end
end

-- ──────────────────────────────────────────────────────────────────────
-- plenary.curl stub — any request is a test failure
-- ──────────────────────────────────────────────────────────────────────
local http = { calls = 0 }

local function no_network()
	http.calls = http.calls + 1
	error("tasknotes-card: network access attempted")
end

package.loaded["plenary.curl"] = { get = no_network, post = no_network, put = no_network, delete = no_network }

local api = require("tasknotes.api")
local cache = require("tasknotes.cache")
local card = require("tasknotes.card")
local config = require("tasknotes.config")
local context = require("tasknotes.context")

-- Notification capture.
local notifications = {}
vim.notify = function(msg, level)
	table.insert(notifications, { msg = msg, level = level })
end

-- ──────────────────────────────────────────────────────────────────────
-- Fixtures
-- ──────────────────────────────────────────────────────────────────────
local vault = config.vault_path

local ALPHA = vault .. "/TaskNotes/Tasks/Alpha.md"
local BETA = vault .. "/TaskNotes/Tasks/Beta.md"
local GAMMA = vault .. "/TaskNotes/Tasks/Gamma.md"

local ALPHA_LINES = {
	"---",
	"task: Alpha",
	"status: in-progress",
	"---",
	"",
	"- [ ] open item",
	"- [x] done item",
	"- [-] doing item",
	"- [>] waiting item",
	"",
	"Body prose.",
}

local TASKS = {
	[ALPHA] = {
		fm = {
			path = "TaskNotes/Tasks/Alpha.md",
			title = "Alpha",
			status = "in-progress",
			priority = "high",
			scheduled = "2026-10-20",
			due = "2026-10-25",
			tags = { "work" },
			projects = { "[[Parent Note]]" },
		},
		mtime = 0,
	},
	[BETA] = {
		fm = {
			path = "TaskNotes/Tasks/Beta.md",
			title = "Beta",
			status = "done",
			priority = "low",
			projects = { "[[Alpha]]" },
		},
		mtime = 0,
	},
	[GAMMA] = {
		fm = {
			path = "TaskNotes/Tasks/Gamma.md",
			title = "Gamma",
			status = "in-progress",
			priority = "normal",
			projects = { "[[Alpha]]" },
		},
		mtime = 0,
	},
	[vault .. "/TaskNotes/Tasks/Delta.md"] = {
		fm = {
			path = "TaskNotes/Tasks/Delta.md",
			title = "Delta",
			status = "inbox",
			priority = "normal",
		},
		mtime = 0,
	},
}

-- Reset the module state between sections.
local function reset_cache()
	cache.data = vim.deepcopy(TASKS)
	cache.keys_index = {}
	cache.generation = 1
	cache.last_full_scan = os.time()
	api._filter_options_cache = {
		data = {
			statuses = {
				{ value = "inbox", label = "Inbox", color = "#336699", order = 1, isCompleted = false },
				{ value = "in-progress", label = "In Progress", color = "#0090FF", order = 2, isCompleted = false },
				{ value = "done", label = "Done", color = "#00aa00", order = 3, isCompleted = true },
			},
			priorities = {
				{ value = "high", label = "High", color = "#ff0000", order = 1 },
				{ value = "normal", label = "Normal", color = "#cccccc", order = 2 },
				{ value = "low", label = "Low", color = "#00ff00", order = 3 },
			},
		},
		fetched_at = os.time(),
	}
	notifications = {}
	http.calls = 0
end

-- Creates a scratch buffer that looks like a task note.
local function make_buffer(path, lines)
	local buf = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_buf_set_name(buf, path)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	return buf
end

-- The extmarks of the card namespace in a buffer.
local function card_marks(buf)
	return vim.api.nvim_buf_get_extmarks(buf, card.ns, 0, -1, { details = true })
end

-- The rendered text of the card (one string per virtual line).
local function card_text(buf)
	local out = {}
	for _, mark in ipairs(card_marks(buf)) do
		local details = mark[4]
		for _, line in ipairs(details.virt_lines or {}) do
			local parts = {}
			for _, chunk in ipairs(line) do
				parts[#parts + 1] = chunk[1]
			end
			out[#out + 1] = table.concat(parts)
		end
	end
	return out
end

-- ──────────────────────────────────────────────────────────────────────
-- 1. The card is drawn as virt_lines anchored on the closing fence
-- ──────────────────────────────────────────────────────────────────────
reset_cache()

local buf = make_buffer(ALPHA, ALPHA_LINES)
local before = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
local modified_before = vim.bo[buf].modified

card.refresh(buf)

local marks = card_marks(buf)
assert_equal(#marks, 1, "the card is a single extmark")
assert_equal(marks[1][2], 3, "the card is anchored on the closing `---` (0-based row)")
assert_true(marks[1][4].virt_lines ~= nil, "the card is drawn as virt_lines")
assert_equal(marks[1][4].virt_lines_above, false, "the card renders below the fence")

local text = card_text(buf)
assert_true(#text >= 3, "the card has several lines")
assert_true(text[1]:find("Alpha", 1, true) ~= nil, "the header shows the title: " .. text[1])
assert_true(text[1]:find("#work", 1, true) == nil, "the title stands alone, without the tags: " .. text[1])
assert_true(text[1]:find("2026-10-20", 1, true) == nil, "the title stands alone, without the dates: " .. text[1])
-- The dates and the tags sit on their own line, right above the
-- progress footer.
local dates_line = text[#text - 1]
assert_true(dates_line:find("sched 2026-10-20", 1, true) ~= nil, "the dates line shows scheduled: " .. dates_line)
assert_true(dates_line:find("due 2026-10-25", 1, true) ~= nil, "the dates line shows due: " .. dates_line)
assert_true(dates_line:find("#work", 1, true) ~= nil, "the dates line shows the tags: " .. dates_line)
assert_true(text[2]:find("Parent Note", 1, true) ~= nil, "the parents line shows the parent: " .. (text[2] or ""))
assert_true(text[3]:find("Gamma", 1, true) ~= nil, "the first subtask row is drawn: " .. (text[3] or ""))
assert_true(text[4]:find("Beta", 1, true) ~= nil, "the second subtask row is drawn: " .. (text[4] or ""))
assert_true(text[#text]:find("subtasks 1/2", 1, true) ~= nil, "the footer shows subtask progress: " .. text[#text])
assert_true(text[#text]:find("checklist 1/4", 1, true) ~= nil, "the footer counts every checklist state: " .. text[#text])

-- The buffer itself is untouched.
assert_equal(vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), before), true, "the buffer text is unchanged")
assert_equal(vim.bo[buf].modified, modified_before, "the buffer modified flag is unchanged")
assert_equal(http.calls, 0, "rendering performs no request")

-- The status icon and the priority dot carry their own highlight groups.
local header_chunks = marks[1][4].virt_lines[1]
local groups = {}
for _, chunk in ipairs(header_chunks) do
	groups[chunk[2]] = true
end
assert_true(groups["TaskNotesStatus_in_progress"] == true, "the status icon uses the live status color")
assert_true(groups["TaskNotesPriority_high"] == true, "the priority dot uses the live priority color")

-- ──────────────────────────────────────────────────────────────────────
-- 2. The card follows the fence when lines are inserted above it
-- ──────────────────────────────────────────────────────────────────────
vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "# Inserted heading", "" })
card.refresh(buf)

marks = card_marks(buf)
assert_equal(#marks, 1, "still a single extmark after the edit")
assert_equal(marks[1][2], 5, "the card follows the fence down by two rows")

-- ──────────────────────────────────────────────────────────────────────
-- 3. Toggle off clears the namespace; toggle on redraws
-- ──────────────────────────────────────────────────────────────────────
local buf2 = make_buffer(BETA, {
	"---",
	"task: Beta",
	"---",
	"",
	"- [ ] todo",
})
card.refresh(buf2)
assert_equal(#card_marks(buf2), 1, "the second buffer has a card")

card.enabled = true
card.toggle()
assert_equal(card.enabled, false, "toggle flips the switch off")
assert_equal(#card_marks(buf), 0, "toggle off clears the namespace in the first buffer")
assert_equal(#card_marks(buf2), 0, "toggle off clears the namespace in the second buffer")
assert_true(#notifications > 0, "toggle notifies")
assert_equal(notifications[#notifications].level, vim.log.levels.INFO, "toggle notifies at INFO level")

card.toggle()
assert_equal(card.enabled, true, "toggle flips the switch back on")
assert_equal(#card_marks(buf), 1, "toggle on redraws the first buffer")
assert_equal(#card_marks(buf2), 1, "toggle on redraws the second buffer")

-- ──────────────────────────────────────────────────────────────────────
-- 4. A stale cache refreshes asynchronously, never blocking
-- ──────────────────────────────────────────────────────────────────────
reset_cache()
cache.last_full_scan = 0 -- stale

local refresh_calls = 0
local real_refresh_async = cache.refresh_async
cache.refresh_async = function()
	refresh_calls = refresh_calls + 1
end

local buf3 = make_buffer(GAMMA, {
	"---",
	"task: Gamma",
	"---",
	"",
	"- [ ] open",
})
card.refresh(buf3)

assert_equal(refresh_calls, 1, "a stale cache triggers one async refresh")
assert_equal(#card_marks(buf3), 1, "the card is drawn from the current cache anyway")
assert_equal(http.calls, 0, "no request happens synchronously on the render path")

-- The spied refresh must not have been replaced by a blocking call: the
-- card drew even though the cache was stale.
assert_true(card_text(buf3)[1]:find("Gamma", 1, true) ~= nil, "the card shows the stale-cache title")

cache.refresh_async = real_refresh_async

-- ──────────────────────────────────────────────────────────────────────
-- 5. Autocmd wiring: BufEnter draws the card, the cache-refreshed event
--    redraws it, and a non-vault buffer is left alone.
-- ──────────────────────────────────────────────────────────────────────
reset_cache()
card.attach()

-- The augroup exists and owns the expected events.
local group = vim.api.nvim_get_autocmds({ group = "TaskNotesViews" })
assert_true(#group > 0, "the TaskNotesViews augroup is registered")
local events = {}
for _, au in ipairs(group) do
	events[au.event] = true
end
assert_true(events["BufEnter"] == true, "BufEnter is wired")
assert_true(events["BufWritePost"] == true, "BufWritePost is wired")
assert_true(events["TextChanged"] == true, "TextChanged is wired")
assert_true(events["TextChangedI"] == true, "TextChangedI is wired")
assert_true(events["User"] == true, "User TaskNotesCacheRefreshed is wired")

-- A vault markdown buffer gets its card on BufEnter.
local DELTA = vault .. "/TaskNotes/Tasks/Delta.md"
local buf4 = make_buffer(DELTA, ALPHA_LINES)
vim.api.nvim_set_current_buf(buf4)
vim.api.nvim_exec_autocmds("BufEnter", { buffer = buf4 })
assert_equal(#card_marks(buf4), 1, "BufEnter draws the card")

-- A buffer outside the vault is ignored.
local outside = make_buffer("/tmp/not-the-vault/Other.md", { "---", "task: Other", "---" })
vim.api.nvim_set_current_buf(outside)
vim.api.nvim_exec_autocmds("BufEnter", { buffer = outside })
assert_equal(#card_marks(outside), 0, "a non-vault buffer gets no card")

-- The cache-refreshed event redraws the visible vault buffers.
vim.api.nvim_set_current_buf(buf4)
vim.api.nvim_exec_autocmds("User", { pattern = "TaskNotesCacheRefreshed", modeline = false })
assert_equal(#card_marks(buf4), 1, "TaskNotesCacheRefreshed redraws the card")

-- ──────────────────────────────────────────────────────────────────────
-- 5b. Dates carry the days left, worded as in the pickers and menus
-- ──────────────────────────────────────────────────────────────────────
do
	local util = require("tasknotes.util")
	local function day(offset)
		return os.date("%Y-%m-%d", os.time() + offset * 86400)
	end
	local today, in21, ago3, in6 = day(0), day(21), day(-3), day(6)

	-- The menus keep their wording (one suffix: due first, then sched).
	assert_equal(util.due_info(today, nil), " (DUE TODAY)", "menus: due today")
	assert_equal(util.due_info(ago3, nil), " (3d OVERDUE)", "menus: overdue")
	assert_equal(util.due_info(in21, nil), " (21d until due)", "menus: due ahead")
	assert_equal(util.due_info(nil, today), " (Sched: Today)", "menus: scheduled today")
	assert_equal(util.due_info(nil, ago3), " (3d ago)", "menus: scheduled in the past")
	assert_equal(util.due_info(nil, in6), " (6d until sched)", "menus: scheduled ahead")
	assert_equal(util.due_info(in21, today), " (21d until due)", "menus: due wins over scheduled")

	local dated_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(dated_buf, 0, -1, false, { "---", "title: Informe", "---", "body" })
	card.render(dated_buf, {
		path = ALPHA,
		fm_end_row = 2,
		task = {
			title = "Informe",
			status = "in-progress",
			priority = "high",
			scheduled = today,
			due = in21,
			tags = { "task" },
		},
		parents = {},
		subtasks = {},
		checklist = { open = 1, doing = 0, on_hold = 0, waiting = 0, done = 0, total = 1 },
	})
	local dated = card_text(dated_buf)
	assert_equal(#dated, 3, "title, dates line, checklist")
	assert_true(dated[1]:find("Informe", 1, true) ~= nil and dated[1]:find("sched", 1, true) == nil, "the title is alone")
	assert_equal(
		dated[2],
		string.format("sched %s (Sched: Today) · due %s (21d until due)   #task", today, in21),
		"each date shows the days left, then the tags"
	)
	assert_equal(dated[3], "checklist 0/1", "the checklist comes after the dates")

	-- The days left take the menus' highlight (today warns).
	local groups = {}
	for _, chunk in ipairs(card_marks(dated_buf)[1][4].virt_lines[2]) do
		groups[chunk[1]] = chunk[2]
	end
	assert_equal(groups[" (Sched: Today)"], "DiagnosticWarn", "scheduled today is highlighted as in the menus")
	assert_equal(groups[" (21d until due)"], "Comment", "a date ahead stays dim")

	-- A task with neither dates nor tags has no dates line.
	card.render(dated_buf, {
		path = ALPHA,
		fm_end_row = 2,
		task = { title = "Bare", status = "inbox" },
		parents = {},
		subtasks = {},
	})
	assert_equal(#card_text(dated_buf), 1, "no dates and no tags: only the title")
end

-- ──────────────────────────────────────────────────────────────────────
-- 6. Require-set guarantee
-- ──────────────────────────────────────────────────────────────────────
local forbidden = { ["tasknotes.api"] = true, ["tasknotes.task_ops"] = true, ["plenary.curl"] = true }

for _, module_path in ipairs({ "lua/tasknotes/context.lua", "lua/tasknotes/card.lua" }) do
	local source_path = vim.api.nvim_get_runtime_file(module_path, false)[1]
	assert_true(source_path ~= nil, module_path .. " is on the runtimepath")

	local source = table.concat(vim.fn.readfile(source_path), "\n")
	for module in source:gmatch('require%s*%(%s*["\']?([%w_%.]+)') do
		assert_true(forbidden[module] ~= true, module_path .. " must not require " .. module)
	end
end

print("tasknotes card: ok")
