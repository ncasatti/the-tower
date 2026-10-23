-- TKT-103 — task info side panel (read-only).
--
-- Headless contract test. plenary.curl is stubbed to error, so any
-- request that escapes the render path fails the test loudly.
--
-- Covered:
--   1. The panel renders every section of a full fixture and omits the
--      empty ones.
--   2. Empty state for a non-task buffer; loading state while the task
--      cache is still empty.
--   3. Following: switching buffers re-renders the panel, entering the
--      panel window itself does not.
--   4. <CR> on a Ref row opens that file in the editing window; on a
--      non-Ref row nothing happens.
--   5. The panel buffer is not modifiable; toggling twice leaves no
--      panel window behind.
--   6. Rendering the card AND the panel performs zero requests.
--   7. Require-set: context/card/panel never require the HTTP layer.
--
-- Run: cd nvim && nvim --headless -u NONE --cmd 'set rtp^=.' -l tests/tasknotes-panel.lua

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

local function assert_contains(haystack, needle, label)
	if type(haystack) ~= "string" or not haystack:find(needle, 1, true) then
		error(string.format("%s: expected %s to contain %s", label, vim.inspect(haystack), vim.inspect(needle)))
	end
end

local function assert_not_contains(haystack, needle, label)
	if type(haystack) == "string" and haystack:find(needle, 1, true) then
		error(string.format("%s: expected %s NOT to contain %s", label, vim.inspect(haystack), vim.inspect(needle)))
	end
end

-- ──────────────────────────────────────────────────────────────────────
-- plenary.curl stub — any request is a test failure
-- ──────────────────────────────────────────────────────────────────────
local http = { calls = 0 }

local function no_network()
	http.calls = http.calls + 1
	error("tasknotes-panel: network access attempted")
end

package.loaded["plenary.curl"] = { get = no_network, post = no_network, put = no_network, delete = no_network }

local api = require("tasknotes.api")
local cache = require("tasknotes.cache")
local card = require("tasknotes.card")
local config = require("tasknotes.config")
local context = require("tasknotes.context")
local panel = require("tasknotes.panel")

-- The panel edits real files on <CR>; point the vault at a throwaway
-- directory so the test never touches the real one.
local vault = vim.fn.tempname() .. "/vault"
vim.fn.mkdir(vault .. "/TaskNotes/Tasks", "p")
vim.fn.mkdir(vault .. "/Areas", "p")
config.vault_path = vault

-- ──────────────────────────────────────────────────────────────────────
-- Snacks (the window layer)
--
-- The panel renders into a plain buffer, so the buffer-level assertions
-- run everywhere. The window assertions need Snacks; when it is not on
-- the runtimepath they are skipped with a notice.
-- ──────────────────────────────────────────────────────────────────────
local function load_snacks()
	local ok, mod = pcall(require, "snacks")
	if ok then
		return mod
	end
	local candidates = {
		vim.fn.expand("~/.local/share/nvim/lazy/snacks.nvim"),
		vim.fn.expand("~/.local/share/nvim/site/pack/lazy/opt/snacks.nvim"),
	}
	for _, dir in ipairs(candidates) do
		if vim.fn.isdirectory(dir) == 1 then
			vim.opt.rtp:append(dir)
			local ok2, mod2 = pcall(require, "snacks")
			if ok2 then
				return mod2
			end
		end
	end
	return nil
end

local snacks = load_snacks()

-- ──────────────────────────────────────────────────────────────────────
-- Fixtures
-- ──────────────────────────────────────────────────────────────────────
local ALPHA = vault .. "/TaskNotes/Tasks/Alpha.md"
local BETA = vault .. "/TaskNotes/Tasks/Beta.md"
local GAMMA = vault .. "/TaskNotes/Tasks/Gamma.md"
local DELTA = vault .. "/TaskNotes/Tasks/Delta.md"
local PARENT = vault .. "/Areas/Parent Note.md"

local ALPHA_LINES = {
	"---",
	"task: Alpha",
	"status: in-progress",
	"---",
	"",
	"- [ ] open item",
	"- [x] done item",
	"- [-] doing item",
	"",
	"Body prose.",
}

-- The notes exist on disk so <CR> can open them.
for _, path in ipairs({ ALPHA, BETA, GAMMA, DELTA, PARENT }) do
	vim.fn.writefile({ "---", "---" }, path)
end

local TASKS = {
	[ALPHA] = {
		fm = {
			path = "TaskNotes/Tasks/Alpha.md",
			title = "Alpha",
			status = "in-progress",
			priority = "high",
			scheduled = "2026-10-20",
			due = "2026-10-25",
			dateCreated = "2025-11-21T15:54:32.631-03:00",
			dateModified = "2026-08-26T15:02:56.595-03:00",
			tags = { "work" },
			projects = { "[[Parent Note]]" },
			blockedBy = { { uid = "Beta", reltype = "FINISHTOSTART" } },
			blocking = { "TaskNotes/Tasks/Gamma.md" },
			totalTrackedTime = 86,
			timeEstimate = 60,
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
			blockedBy = { { uid = "Ghost Task", reltype = "FINISHTOSTART" } },
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
	[DELTA] = {
		fm = {
			path = "TaskNotes/Tasks/Delta.md",
			title = "Delta",
			status = "inbox",
			priority = "normal",
		},
		mtime = 0,
	},
	[PARENT] = {
		fm = {
			path = "Areas/Parent Note.md",
			title = "Parent Note",
			status = "done",
			priority = "normal",
		},
		mtime = 0,
	},
}

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
	http.calls = 0
end

-- A scratch buffer that looks like a task note.
local function make_buffer(path, lines)
	local buf = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_buf_set_name(buf, path)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modified = false
	return buf
end

local function buf_text(buf)
	return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
end

-- The row (1-based) of the first line containing `needle`.
local function row_of(buf, needle)
	for row, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
		if line:find(needle, 1, true) then
			return row
		end
	end
	return nil
end

-- ──────────────────────────────────────────────────────────────────────
-- 1. The full fixture renders every section
-- ──────────────────────────────────────────────────────────────────────
reset_cache()

local ctx = context.build(ALPHA, {
	tasks = cache.data,
	lines = ALPHA_LINES,
	completed = { done = true },
	generation = cache.generation,
})
assert_true(ctx ~= nil, "the fixture task yields a context")

local panel_buf = vim.api.nvim_create_buf(false, true)
panel.render_into(panel_buf, ctx)

local text = buf_text(panel_buf)

-- Header: title, status label, priority label.
assert_contains(text, "Alpha", "the header shows the title")
assert_contains(text, "In Progress", "the header shows the status label")
assert_contains(text, "High", "the header shows the priority label")

-- Dates.
assert_contains(text, "Dates", "the Dates section is rendered")
assert_contains(text, "2026-10-20", "the scheduled date is rendered")
assert_contains(text, "2026-10-25", "the due date is rendered")
assert_contains(text, "2025-11-21", "the created date is rendered")
assert_contains(text, "2026-08-26", "the modified date is rendered")

-- Parents.
assert_contains(text, "Parents", "the Parents section is rendered")
assert_contains(text, "Parent Note", "the parent name is rendered")

-- Subtasks + progress bar.
assert_contains(text, "Subtasks", "the Subtasks section is rendered")
assert_contains(text, "Beta", "the subtask name is rendered")
assert_contains(text, "Gamma", "the subtask name is rendered")
assert_contains(text, "1/2", "the subtask progress is rendered")
assert_contains(text, "█", "the progress bar uses filled blocks")
assert_contains(text, "░", "the progress bar uses empty blocks")

-- Dependencies.
assert_contains(text, "Dependencies", "the Dependencies section is rendered")
assert_contains(text, "Blocked by", "the blocked-by group is rendered")
assert_contains(text, "Blocking", "the blocking group is rendered")

-- Checklist.
assert_contains(text, "Checklist", "the Checklist section is rendered")
assert_contains(text, "done 1", "the checklist counts are rendered")
assert_contains(text, "open 1", "the checklist counts are rendered")

-- Time.
assert_contains(text, "Time", "the Time section is rendered")
assert_contains(text, "1h 26m / 1h", "the tracked/estimate time is rendered")

-- The panel highlights the status icon in the live color.
local marks = vim.api.nvim_buf_get_extmarks(panel_buf, panel.ns, 0, -1, { details = true })
assert_true(#marks > 0, "the panel paints its own highlights")
local groups = {}
for _, mark in ipairs(marks) do
	groups[mark[4].hl_group] = true
end
assert_true(groups["TaskNotesStatus_in_progress"] == true, "the status icon uses the live status color")

-- The row → path map: every Ref row carries the absolute path.
local beta_row = row_of(panel_buf, "Beta")
assert_true(beta_row ~= nil, "the Beta row exists")
assert_equal(panel.path_at(panel_buf, beta_row), BETA, "the Beta row maps to the Beta file")

-- Rendering must not touch the network.
assert_equal(http.calls, 0, "rendering the panel performs no request")

-- ──────────────────────────────────────────────────────────────────────
-- 2. Empty sections are omitted
-- ──────────────────────────────────────────────────────────────────────
reset_cache()

local minimal_ctx = context.build(DELTA, {
	tasks = cache.data,
	lines = { "---", "task: Delta", "---" },
	completed = { done = true },
	generation = cache.generation,
})
assert_true(minimal_ctx ~= nil, "the minimal fixture yields a context")

local minimal_buf = vim.api.nvim_create_buf(false, true)
panel.render_into(minimal_buf, minimal_ctx)
local minimal_text = buf_text(minimal_buf)

assert_contains(minimal_text, "Delta", "the minimal panel still shows the title")
for _, section in ipairs({ "Dates", "Parents", "Subtasks", "Dependencies", "Checklist", "Time" }) do
	assert_not_contains(minimal_text, section, "the empty section " .. section .. " is omitted")
end

-- ──────────────────────────────────────────────────────────────────────
-- 3. Empty state / loading state
-- ──────────────────────────────────────────────────────────────────────
reset_cache()

local empty_buf = vim.api.nvim_create_buf(false, true)
panel.render_into(empty_buf, nil)
assert_contains(buf_text(empty_buf), "Not a TaskNotes task", "a non-task buffer shows the empty state")

cache.data = {}
local loading_buf = vim.api.nvim_create_buf(false, true)
panel.render_into(loading_buf, nil)
assert_contains(buf_text(loading_buf), "Loading tasks", "an empty cache shows the loading state")

-- ──────────────────────────────────────────────────────────────────────
-- 4. Following + <CR> navigation (window layer)
-- ──────────────────────────────────────────────────────────────────────
if not snacks then
	print("tasknotes panel: ok (snacks unavailable — window assertions skipped)")
else
	reset_cache()

	panel.attach()

	local alpha_buf = make_buffer(ALPHA, ALPHA_LINES)
	local beta_buf = make_buffer(BETA, { "---", "task: Beta", "---" })
	local plain_buf = make_buffer(vault .. "/Notes/Plain.md", { "# not a task" })

	local edit_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(edit_win, alpha_buf)

	panel.toggle()

	assert_true(panel.is_open(), "the panel opens")
	local panel_win = panel.window()
	assert_true(panel_win ~= nil, "the panel has a window")
	assert_equal(vim.api.nvim_win_get_buf(panel_win), panel.buf, "the panel window shows the panel buffer")

	-- The panel buffer is read-only.
	assert_equal(vim.bo[panel.buf].modifiable, false, "the panel buffer is not modifiable")

	-- The panel shows the context of the buffer it was opened on.
	assert_contains(buf_text(panel.buf), "Alpha", "the panel shows the task it was opened on")

	-- Switching buffers re-renders the panel.
	vim.api.nvim_win_set_buf(edit_win, beta_buf)
	vim.api.nvim_exec_autocmds("BufEnter", { buffer = beta_buf })
	assert_contains(buf_text(panel.buf), "Beta", "switching buffers re-renders the panel")
	assert_contains(buf_text(panel.buf), "Done", "the panel shows the new buffer's status")
	assert_not_contains(buf_text(panel.buf), "In Progress", "the panel no longer shows the old buffer's status")

	-- A non-task buffer shows the empty state.
	vim.api.nvim_win_set_buf(edit_win, plain_buf)
	vim.api.nvim_exec_autocmds("BufEnter", { buffer = plain_buf })
	assert_contains(buf_text(panel.buf), "Not a TaskNotes task", "a non-task buffer shows the empty state")

	-- Entering the panel window itself must NOT re-render.
	vim.api.nvim_win_set_buf(edit_win, alpha_buf)
	vim.api.nvim_exec_autocmds("BufEnter", { buffer = alpha_buf })
	local renders_before = panel.render_count
	vim.api.nvim_exec_autocmds("BufEnter", { buffer = panel.buf })
	assert_equal(panel.render_count, renders_before, "entering the panel does not re-render it")

	-- Entering a special buffer (picker/terminal/noice: buftype ~= "")
	-- must NOT re-render: the panel keeps the last file it followed.
	local special_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[special_buf].buftype = "nofile"
	vim.api.nvim_exec_autocmds("BufEnter", { buffer = special_buf })
	assert_equal(panel.render_count, renders_before, "entering a special buffer does not re-render")
	assert_contains(buf_text(panel.buf), "Alpha", "the panel keeps the followed task after a special buffer")

	-- <CR> on a Ref row opens that file in the editing window.
	local target_row = row_of(panel.buf, "Parent Note")
	assert_true(target_row ~= nil, "the parent row exists in the panel")
	vim.api.nvim_win_set_cursor(panel_win, { target_row, 0 })

	-- The <CR> mapping lives on the panel buffer (the panel window owns
	-- it exclusively).
	local enter_map
	for _, map in ipairs(vim.api.nvim_buf_get_keymap(panel.buf, "n")) do
		if map.lhs == "<CR>" then
			enter_map = map
			break
		end
	end
	assert_true(enter_map ~= nil, "the panel buffer maps <CR>")
	assert_true(enter_map.callback ~= nil, "the <CR> mapping is a Lua callback")

	enter_map.callback()
	assert_equal(
		vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(edit_win)),
		PARENT,
		"<CR> opens the Ref file in the editing window"
	)

	-- <CR> on a non-Ref row does nothing.
	vim.api.nvim_win_set_buf(edit_win, alpha_buf)
	vim.api.nvim_exec_autocmds("BufEnter", { buffer = alpha_buf })
	local header_row = row_of(panel.buf, "Alpha")
	assert_true(header_row ~= nil, "the header row exists in the panel")
	vim.api.nvim_win_set_cursor(panel_win, { header_row, 0 })
	local buf_before = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(edit_win))
	for _, map in ipairs(vim.api.nvim_buf_get_keymap(panel.buf, "n")) do
		if map.lhs == "<CR>" then
			map.callback()
			break
		end
	end
	assert_equal(
		vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(edit_win)),
		buf_before,
		"<CR> on a non-Ref row does nothing"
	)

	-- Toggling twice leaves no panel window.
	panel.toggle()
	assert_equal(panel.is_open(), false, "the panel closes")
	local panel_windows = 0
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.api.nvim_win_get_buf(win) == panel.buf then
			panel_windows = panel_windows + 1
		end
	end
	assert_equal(panel_windows, 0, "no panel window is left behind")
end

-- ──────────────────────────────────────────────────────────────────────
-- 5. The card and the panel perform zero requests together
-- ──────────────────────────────────────────────────────────────────────
reset_cache()

local card_buf = make_buffer(vault .. "/TaskNotes/Tasks/Card.md", ALPHA_LINES)
card.refresh(card_buf)
panel.render_into(panel_buf, ctx)
assert_equal(http.calls, 0, "card + panel rendering performs no request")

-- ──────────────────────────────────────────────────────────────────────
-- 6. Require-set guarantee
-- ──────────────────────────────────────────────────────────────────────
local forbidden = { ["tasknotes.api"] = true, ["tasknotes.task_ops"] = true, ["plenary.curl"] = true }

for _, module_path in ipairs({ "lua/tasknotes/context.lua", "lua/tasknotes/card.lua", "lua/tasknotes/panel.lua" }) do
	local source_path = vim.api.nvim_get_runtime_file(module_path, false)[1]
	assert_true(source_path ~= nil, module_path .. " is on the runtimepath")

	local source = table.concat(vim.fn.readfile(source_path), "\n")
	for module in source:gmatch('require%s*%(%s*["\']?([%w_%.]+)') do
		assert_true(forbidden[module] ~= true, module_path .. " must not require " .. module)
	end
end

print("tasknotes panel: ok")
