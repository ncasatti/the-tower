-- TKT-103 — task info side panel.
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
--   8. Properties: one editable row per field, with the field name
--      the row edits and the current value rendered.
--   9. The footer hint shows for a task and not for the empty state.
--  10. <CR> on a property row and the s/p/d keys edit the followed
--      task through task_ops.edit_field.
--  11. Width fitting: every row fits the panel width, cut with "…";
--      the optional trailing segments go before the name is cut.
--  12. The Projects row shows link names, not raw wikilinks.
--  13. Resizing the panel window re-renders it.
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

-- The default panel width is a share of the editor (0.5); section 15
-- covers it. The fitting sections pin a fixed width of 48 columns so
-- their expectations do not depend on the headless screen size.
local DEFAULT_PANEL_WIDTH = config.panel_width
local DEFAULT_PANEL_HEIGHT = config.panel_height
config.panel_width = 48
local context = require("tasknotes.context")
local panel = require("tasknotes.panel")

-- The panel must not load the write path at load time (ADR-009 / S6a):
-- `task_ops` is required lazily, inside the edit handler. Nothing
-- else in the plugin pulls it in, so this proves the panel's own
-- require is lazy.
assert_true(
	package.loaded["tasknotes.task_ops"] == nil,
	"the panel does not load task_ops at load time"
)

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
local LONG = vault .. "/TaskNotes/Tasks/Long.md"
local LONG_SUB = vault .. "/TaskNotes/Tasks/LongSub.md"
local MEDIUM_SUB = vault .. "/TaskNotes/Tasks/MediumSub.md"

local ALPHA_LINES = {
	"---",
	"task: Alpha",
	"status: in-progress",
	"---",
	"",
	"- [ ] open item",
	"- [x] done item",
	"- [-] doing item",
	"- [~] on-hold item",
	"- [>] waiting item",
	"- [>] another waiting item",
	"",
	"Body prose.",
}

-- The notes exist on disk so <CR> can open them.
for _, path in ipairs({ ALPHA, BETA, GAMMA, DELTA, PARENT, LONG, LONG_SUB }) do
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
	-- A task whose subtasks are too wide for the panel: the priority
	-- and the date are dropped, and a very long name is cut with "…".
	[LONG] = {
		fm = {
			path = "TaskNotes/Tasks/Long.md",
			title = "Long",
			status = "in-progress",
			priority = "normal",
		},
		mtime = 0,
	},
	[LONG_SUB] = {
		fm = {
			path = "TaskNotes/Tasks/LongSub.md",
			title = "implementar el panel de tareas con soporte de edicion completa",
			status = "in-progress",
			priority = "normal",
			scheduled = "2026-11-07",
			projects = { "[[Long]]" },
		},
		mtime = 0,
	},
	[MEDIUM_SUB] = {
		fm = {
			path = "TaskNotes/Tasks/MediumSub.md",
			title = "tarea de longitud media",
			status = "in-progress",
			priority = "normal",
			scheduled = "2026-11-07",
			projects = { "[[Long]]" },
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

-- A scratch buffer that looks like a task note. Reuses the buffer of
-- that name when it already exists, so a later section can ask for
-- the same note without colliding.
local function make_buffer(path, lines)
	local buf
	for _, existing in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_name(existing) == path then
			buf = existing
			break
		end
	end
	if not buf then
		buf = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_buf_set_name(buf, path)
	end
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

-- The row (1-based) carrying `field` in the Properties section.
local function row_of_field(buf, field)
	for row = 1, vim.api.nvim_buf_line_count(buf) do
		if panel.field_at(buf, row) == field then
			return row
		end
	end
	return nil
end

-- The row (1-based) whose navigable path is `path`.
local function row_of_path(buf, path)
	for row = 1, vim.api.nvim_buf_line_count(buf) do
		if panel.path_at(buf, row) == path then
			return row
		end
	end
	return nil
end

-- The text of a single row.
local function row_text(buf, row)
	return vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
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

-- No created / modified dates: the panel shows what can be edited.
assert_not_contains(text, "Dates", "the Dates section is gone")
assert_not_contains(text, "2025-11-21", "the created date is not rendered")
assert_not_contains(text, "2026-08-26", "the modified date is not rendered")

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

-- Checklist: one row per state in use, with the task status icon.
assert_contains(text, "Checklist", "the Checklist section is rendered")
local function checklist_row(label)
	for _, line in ipairs(vim.api.nvim_buf_get_lines(panel_buf, 0, -1, false)) do
		if line:match("^%s+%S+%s+" .. vim.pesc(label) .. "%s+%d+$") then
			return line
		end
	end
	return nil
end
for label, n in pairs({ open = 1, doing = 1, ["on-hold"] = 1, waiting = 2, done = 1 }) do
	local line = checklist_row(label)
	assert_true(line ~= nil, "the checklist has a row for " .. label)
	assert_true(line:match("%s" .. n .. "$") ~= nil, "the " .. label .. " row counts " .. n .. ": " .. tostring(line))
end
assert_contains(checklist_row("on-hold") or "", config.status_icons["on-hold"], "the on-hold row uses the on-hold status icon")
assert_contains(checklist_row("waiting") or "", config.status_icons.waiting, "the waiting row uses the waiting status icon")

-- Time.
assert_contains(text, "Time", "the Time section is rendered")
assert_contains(text, "1h 26m / 1h", "the tracked/estimate time is rendered")

-- ──────────────────────────────────────────────────────────────────────
-- 8. Properties: one editable row per field
-- ──────────────────────────────────────────────────────────────────────
assert_contains(text, "Properties", "the Properties section is rendered")

-- Every editable field has its own row, and the row knows which field
-- it edits.
for _, field in ipairs({
	"title",
	"status",
	"priority",
	"scheduled",
	"due",
	"contexts",
	"projects",
	"tags",
	"timeEstimate",
}) do
	local row = row_of_field(panel_buf, field)
	assert_true(row ~= nil, "the Properties section has a row for " .. field)
	assert_equal(panel.field_at(panel_buf, row), field, "the " .. field .. " row maps to the " .. field .. " field")
end

-- The rows show the current values (labels for status/priority).
assert_contains(row_text(panel_buf, row_of_field(panel_buf, "title")), "Alpha", "the Task row shows the title")
assert_contains(row_text(panel_buf, row_of_field(panel_buf, "status")), "In Progress", "the Status row shows the live label")
assert_contains(row_text(panel_buf, row_of_field(panel_buf, "priority")), "High", "the Priority row shows the live label")
assert_contains(row_text(panel_buf, row_of_field(panel_buf, "scheduled")), "2026-10-20", "the Scheduled row shows the date")
assert_contains(row_text(panel_buf, row_of_field(panel_buf, "due")), "2026-10-25", "the Due row shows the date")
assert_contains(row_text(panel_buf, row_of_field(panel_buf, "contexts")), "—", "an empty field shows an em dash")
assert_contains(row_text(panel_buf, row_of_field(panel_buf, "projects")), "Parent Note", "the Projects row shows the project")
assert_contains(row_text(panel_buf, row_of_field(panel_buf, "tags")), "work", "the Tags row shows the tags")
assert_contains(row_text(panel_buf, row_of_field(panel_buf, "timeEstimate")), "60", "the Estimate row shows the minutes")

-- Scheduled and due live in Properties only.
assert_not_contains(row_text(panel_buf, row_of_field(panel_buf, "scheduled")), "2025-11-21", "the Scheduled row shows only scheduled")

-- ──────────────────────────────────────────────────────────────────────
-- 9. The footer hint
-- ──────────────────────────────────────────────────────────────────────
assert_contains(text, "<CR> edit/open", "the footer hint is rendered for a task")
assert_contains(text, "s status · p prio · c sched · d due", "the footer hint lists the field keys")
assert_contains(text, "q close", "the footer hint lists the close key")

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
assert_not_contains(buf_text(empty_buf), "<CR> edit/open", "the empty state has no footer hint")

cache.data = {}
local loading_buf = vim.api.nvim_create_buf(false, true)
panel.render_into(loading_buf, nil)
assert_contains(buf_text(loading_buf), "Loading tasks", "an empty cache shows the loading state")
assert_not_contains(buf_text(loading_buf), "<CR> edit/open", "the loading state has no footer hint")

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
	-- The Parents row is found by its path: the Properties section
	-- also mentions the project by name.
	local target_row = row_of_path(panel.buf, PARENT)
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
--
-- context/card never mention the HTTP layer at all. The panel may
-- require `task_ops` — but only lazily, from inside its edit
-- handler, never at module level: its own require must stay out of
-- the load path.
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

-- The panel: the API and curl are off limits everywhere; `task_ops`
-- is allowed only inside a function body (a lazy require).
local panel_source_path = vim.api.nvim_get_runtime_file("lua/tasknotes/panel.lua", false)[1]
assert_true(panel_source_path ~= nil, "lua/tasknotes/panel.lua is on the runtimepath")

local panel_source = table.concat(vim.fn.readfile(panel_source_path), "\n")
for module in panel_source:gmatch('require%s*%(%s*["\']?([%w_%.]+)') do
	assert_true(
		module ~= "tasknotes.api" and module ~= "plenary.curl",
		"the panel must not require " .. module
	)
end

-- A module-level require sits at the start of a line; a lazy one is
-- indented inside a function.
for line in panel_source:gmatch("[^\n]+") do
	if line:match("^local%s") then
		for module in line:gmatch('require%s*%(%s*["\']?([%w_%.]+)') do
			assert_true(
				forbidden[module] ~= true,
				"the panel must not require " .. module .. " at module level"
			)
		end
	end
end

-- ──────────────────────────────────────────────────────────────────────
-- 10. The edit keys reach task_ops.edit_field
--
-- The panel must not require task_ops at load time, so the stub is
-- installed HERE — after the require-set assertions above have run.
-- The panel's lazy `require("tasknotes.task_ops")` then picks the
-- stub up.
-- ──────────────────────────────────────────────────────────────────────
if snacks then
	reset_cache()

	-- The stub records what the panel asks to edit.
	local calls = {}
	local stub = {
		edit_field = function(id, field, opts)
			calls[#calls + 1] = { id = id, field = field, opts = opts }
		end,
	}
	local real_task_ops = package.loaded["tasknotes.task_ops"]
	package.loaded["tasknotes.task_ops"] = stub

	panel.attach()

	local alpha_buf = make_buffer(ALPHA, ALPHA_LINES)
	local plain_buf = make_buffer(vault .. "/Notes/Plain.md", { "# not a task" })

	local edit_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(edit_win, alpha_buf)
	panel.toggle()

	local panel_win = panel.window()
	assert_true(panel_win ~= nil, "the panel is open for the edit keys")

	-- <CR> on a property row edits THAT field of the followed task.
	local status_row = row_of_field(panel.buf, "status")
	assert_true(status_row ~= nil, "the panel shows a Status property row")
	vim.api.nvim_win_set_cursor(panel_win, { status_row, 0 })

	local function press(lhs)
		for _, map in ipairs(vim.api.nvim_buf_get_keymap(panel.buf, "n")) do
			if map.lhs == lhs then
				map.callback()
				return true
			end
		end
		return false
	end

	assert_true(press("<CR>"), "the panel buffer maps <CR>")
	assert_equal(#calls, 1, "<CR> on a property row edits one field")
	assert_equal(calls[1].id, "TaskNotes/Tasks/Alpha.md", "the edit targets the followed task by its vault-relative id")
	assert_equal(calls[1].field, "status", "<CR> edits the field of the row under the cursor")
	assert_equal(calls[1].opts.buf, alpha_buf, "the edit keeps the followed note buffer in sync")

	-- s / p / c / d edit status / priority / scheduled / due from any row.
	vim.api.nvim_win_set_cursor(panel_win, { 1, 0 })
	assert_true(press("s"), "the panel buffer maps s")
	assert_true(press("p"), "the panel buffer maps p")
	assert_true(press("d"), "the panel buffer maps d")
	assert_true(press("c"), "the panel buffer maps c")

	assert_equal(#calls, 5, "the s/p/d/c keys edit four more fields")
	assert_equal(calls[2].field, "status", "s edits the status")
	assert_equal(calls[3].field, "priority", "p edits the priority")
	assert_equal(calls[4].field, "due", "d edits the due date")
	assert_equal(calls[5].field, "scheduled", "c edits the scheduled date")
	for i = 2, 5 do
		assert_equal(calls[i].id, "TaskNotes/Tasks/Alpha.md", "the s/p/d/c keys act on the followed task")
		assert_equal(calls[i].opts.buf, alpha_buf, "the s/p/d/c keys keep the followed note buffer in sync")
	end

	-- A panel that follows a non-task buffer edits nothing.
	vim.api.nvim_win_set_buf(edit_win, plain_buf)
	vim.api.nvim_exec_autocmds("BufEnter", { buffer = plain_buf })
	press("s")
	press("c")
	assert_equal(#calls, 5, "a panel following a non-task buffer edits nothing")

	panel.toggle()
	package.loaded["tasknotes.task_ops"] = real_task_ops
end

-- ──────────────────────────────────────────────────────────────────────
-- 11. Width fitting: every row fits the panel width
-- ──────────────────────────────────────────────────────────────────────

-- The panel is closed here, so the rows are fitted to the configured
-- panel width (pinned to 48 at the top of this file).
local PANEL_WIDTH = config.panel_width
assert_equal(PANEL_WIDTH, 48, "the pinned panel width is 48")

-- The text of a segment list.
local function segments_text(segments)
	local parts = {}
	for _, segment in ipairs(segments) do
		parts[#parts + 1] = segment.text
	end
	return table.concat(parts)
end

-- True when `text` is valid UTF-8: re-encoding every character must
-- give the same bytes back.
local function is_valid_utf8(text)
	local parts = {}
	for _, cp in ipairs(vim.fn.str2list(text)) do
		parts[#parts + 1] = vim.fn.nr2char(cp)
	end
	return table.concat(parts) == text
end

local fit = panel._fit_segments
assert_true(fit ~= nil, "the panel exposes the row fitter")

-- A row that fits is returned unchanged.
local fits = {
	{ text = "  ○ task", hl = "Comment" },
	{ text = "  Normal", hl = "Comment", optional = true },
}
local fitted = fit(fits, PANEL_WIDTH)
assert_equal(#fitted, 2, "a row that fits keeps every segment")
assert_equal(fitted[1].text, "  ○ task", "a row that fits keeps its first text")
assert_equal(fitted[1].hl, "Comment", "a row that fits keeps its first highlight")
assert_equal(fitted[2].text, "  Normal", "a row that fits keeps its last text")
assert_equal(fitted[2].hl, "Comment", "a row that fits keeps its last highlight")
assert_not_contains(segments_text(fitted), "…", "a row that fits is not cut")

-- A row that is too wide is cut with an ellipsis and fits the width.
local wide = {
	{ text = "  " },
	{ text = "a name that is far too long for the panel width" },
}
fitted = fit(wide, PANEL_WIDTH)
assert_true(vim.endswith(segments_text(fitted), "…"), "a wide row ends with an ellipsis")
assert_true(
	vim.fn.strdisplaywidth(segments_text(fitted)) <= PANEL_WIDTH,
	"a wide row fits the panel width"
)

-- The cut is on a character boundary: a multibyte glyph is never cut
-- in half.
local multibyte = {
	{ text = "  " },
	{ text = string.rep("áéí", 30) },
}
fitted = fit(multibyte, PANEL_WIDTH)
assert_true(vim.endswith(segments_text(fitted), "…"), "a multibyte row ends with an ellipsis")
assert_true(is_valid_utf8(segments_text(fitted)), "a multibyte row is cut on a character boundary")
assert_true(
	vim.fn.strdisplaywidth(segments_text(fitted)) <= PANEL_WIDTH,
	"a multibyte row fits the panel width"
)

-- The cut is on a character boundary even when the cut falls INSIDE a
-- multibyte segment (the glyph is never split across two segments).
local split_multibyte = {
	{ text = string.rep("x", 40) },
	{ text = string.rep("é", 20) },
}
fitted = fit(split_multibyte, PANEL_WIDTH)
assert_true(vim.endswith(segments_text(fitted), "…"), "the cut multibyte row ends with an ellipsis")
assert_true(
	is_valid_utf8(segments_text(fitted)),
	"a cut multibyte segment keeps its character boundary"
)
assert_true(
	vim.fn.strdisplaywidth(segments_text(fitted)) <= PANEL_WIDTH,
	"the cut multibyte row fits the panel width"
)

-- A three-byte glyph whose byte budget would land in the middle of
-- it: the cut still falls on a character boundary.
local wide_glyph = {
	{ text = string.rep("x", 45) },
	{ text = string.rep("€", 10) },
}
fitted = fit(wide_glyph, PANEL_WIDTH)
assert_true(vim.endswith(segments_text(fitted), "…"), "the wide-glyph row ends with an ellipsis")
assert_true(
	is_valid_utf8(segments_text(fitted)),
	"a three-byte glyph is never cut in half"
)
assert_true(
	vim.fn.strdisplaywidth(segments_text(fitted)) <= PANEL_WIDTH,
	"the wide-glyph row fits the panel width"
)
-- The cut uses the whole width: a glyph is never dropped just to
-- save a byte.
assert_equal(
	vim.fn.strdisplaywidth(segments_text(fitted)),
	PANEL_WIDTH,
	"the wide-glyph row uses the whole panel width"
)

-- The highlights of the kept segments survive the cut.
local highlighted = {
	{ text = "  ", hl = "Comment" },
	{ text = "name", hl = "Title" },
	{ text = string.rep("x", 200), hl = "Comment" },
}
fitted = fit(highlighted, PANEL_WIDTH)
assert_equal(fitted[1].hl, "Comment", "the first kept segment keeps its highlight")
assert_equal(fitted[2].hl, "Title", "the cut segment keeps its highlight")

-- A subtask row: the priority and the date are optional, the name is
-- not. The optional segments go before the name is cut.
local subtask = {
	{ text = "  " },
	{ text = "○", hl = "Status" },
	{ text = " tarea de longitud media" },
	{ text = "  Normal", hl = "Comment", optional = true },
	{ text = "  sched 2026-11-07", hl = "Comment", optional = true },
}
fitted = fit(subtask, PANEL_WIDTH)
assert_contains(segments_text(fitted), "tarea de longitud media", "the subtask name survives")
assert_contains(segments_text(fitted), "Normal", "the priority survives")
assert_not_contains(segments_text(fitted), "sched", "the date is dropped before the name is cut")
assert_not_contains(segments_text(fitted), "…", "the subtask name is not cut")

-- A very long name: the optional segments go first, then the name is
-- cut with an ellipsis.
local long_subtask = {
	{ text = "  " },
	{ text = "○", hl = "Status" },
	{ text = " " .. string.rep("nombre larguisimo ", 8) },
	{ text = "  Normal", hl = "Comment", optional = true },
	{ text = "  sched 2026-11-07", hl = "Comment", optional = true },
}
fitted = fit(long_subtask, PANEL_WIDTH)
assert_true(vim.endswith(segments_text(fitted), "…"), "a long subtask name ends with an ellipsis")
assert_not_contains(segments_text(fitted), "sched", "the date is dropped before the name is cut")
assert_not_contains(segments_text(fitted), "Normal", "the priority is dropped before the name is cut")
assert_true(
	vim.fn.strdisplaywidth(segments_text(fitted)) <= PANEL_WIDTH,
	"the long subtask row fits the panel width"
)

-- The optional segments are removed from the END of the row only: an
-- optional segment in the middle survives while the row is cut.
local middle_optional = {
	{ text = "  " },
	{ text = "  Normal", hl = "Comment", optional = true },
	{ text = "  " .. string.rep("cola larguisima ", 8) },
}
fitted = fit(middle_optional, PANEL_WIDTH)
assert_true(
	vim.endswith(segments_text(fitted), "…"),
	"a row with a middle optional segment is cut"
)
assert_contains(
	segments_text(fitted),
	"Normal",
	"an optional segment that is not at the end survives"
)

-- ──────────────────────────────────────────────────────────────────────
-- 11b. The rendered panel: no line is wider than the panel
-- ──────────────────────────────────────────────────────────────────────

reset_cache()

local long_ctx = context.build(LONG, {
	tasks = cache.data,
	lines = { "---", "task: Long", "---" },
	completed = { done = true },
	generation = cache.generation,
})
assert_true(long_ctx ~= nil, "the long fixture yields a context")

local long_buf = vim.api.nvim_create_buf(false, true)
panel.render_into(long_buf, long_ctx)

for row, line in ipairs(vim.api.nvim_buf_get_lines(long_buf, 0, -1, false)) do
	assert_true(
		vim.fn.strdisplaywidth(line) <= PANEL_WIDTH,
		string.format("row %d fits the panel width (%d cells)", row, vim.fn.strdisplaywidth(line))
	)
end

-- The long subtask name is cut with an ellipsis; the medium one keeps
-- its priority and drops its date.
local long_sub_row = row_of(long_buf, "implementar el panel")
assert_true(long_sub_row ~= nil, "the long subtask row exists")
assert_true(vim.endswith(row_text(long_buf, long_sub_row), "…"), "the long subtask name ends with an ellipsis")

local medium_sub_row = row_of(long_buf, "tarea de longitud media")
assert_true(medium_sub_row ~= nil, "the medium subtask row exists")
assert_contains(row_text(long_buf, medium_sub_row), "Normal", "the medium subtask keeps its priority")
assert_not_contains(row_text(long_buf, medium_sub_row), "sched", "the medium subtask drops its date")

-- The footer fits the panel width on its own: the fitter does not
-- shorten it.
local footer_row = row_of(panel_buf, "<CR> edit/open")
assert_true(footer_row ~= nil, "the footer row exists")
assert_not_contains(row_text(panel_buf, footer_row), "…", "the footer is not cut")
assert_true(
	vim.fn.strdisplaywidth(row_text(panel_buf, footer_row)) <= PANEL_WIDTH,
	"the footer fits the panel width"
)

-- ──────────────────────────────────────────────────────────────────────
-- 12. The Projects row shows link names, not raw wikilinks
-- ──────────────────────────────────────────────────────────────────────

local projects_row = row_text(panel_buf, row_of_field(panel_buf, "projects"))
assert_contains(projects_row, "Parent Note", "the Projects row shows the project name")
assert_not_contains(projects_row, "[[", "the Projects row hides the wiki brackets")
assert_not_contains(projects_row, "]]", "the Projects row hides the wiki brackets")

-- ──────────────────────────────────────────────────────────────────────
-- 13. Resizing the panel re-renders it for the new width
-- ──────────────────────────────────────────────────────────────────────

if snacks then
	reset_cache()

	local alpha_buf = make_buffer(ALPHA, ALPHA_LINES)

	local edit_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(edit_win, alpha_buf)

	-- The fit only applies without wrap (section 14 covers wrap).
	local global_wrap = vim.go.wrap
	vim.go.wrap = false

	panel.toggle()
	assert_true(panel.is_open(), "the panel opens for the resize check")

	local panel_win = panel.window()
	local panel_width = vim.api.nvim_win_get_width(panel_win)
	assert_true(panel_width > 0, "the panel window has a width")

	-- Every row fits the panel window.
	for row, line in ipairs(vim.api.nvim_buf_get_lines(panel.buf, 0, -1, false)) do
		assert_true(
			vim.fn.strdisplaywidth(line) <= panel_width,
			string.format("row %d fits the panel window", row)
		)
	end

	-- A narrower panel: the rows are cut for the new width.
	local renders_before = panel.render_count
	vim.api.nvim_win_set_width(panel_win, 30)
	vim.api.nvim_exec_autocmds("WinResized", { pattern = tostring(panel_win) })
	vim.cmd("sleep 50m")

	assert_true(panel.render_count > renders_before, "a resize re-renders the panel")
	for row, line in ipairs(vim.api.nvim_buf_get_lines(panel.buf, 0, -1, false)) do
		assert_true(
			vim.fn.strdisplaywidth(line) <= 30,
			string.format("row %d fits the narrowed panel", row)
		)
	end

	panel.toggle()
	vim.go.wrap = global_wrap
end

-- ──────────────────────────────────────────────────────────────────────
-- 14. Wrap: the panel inherits the global 'wrap' (and 'linebreak') and
--     follows a per-window toggle (<leader>W). With wrap on, rows are
--     not cut: the window wraps them.
-- ──────────────────────────────────────────────────────────────────────

if snacks then
	reset_cache()
	local long_buf = make_buffer(LONG, { "---", "task: Long", "---" })
	local edit_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(edit_win, long_buf)

	local global_wrap, global_lbr = vim.go.wrap, vim.go.linebreak
	vim.go.wrap = true
	vim.go.linebreak = true

	panel.toggle()
	local panel_win = panel.window()
	assert_equal(vim.wo[panel_win].wrap, true, "the panel inherits wrap = true")
	assert_equal(vim.wo[panel_win].linebreak, true, "the panel inherits linebreak = true")
	assert_not_contains(buf_text(panel.buf), "…", "with wrap on, no row is cut")

	-- The per-window toggle, as <leader>W does it.
	local renders = panel.render_count
	vim.api.nvim_win_call(panel_win, function()
		vim.api.nvim_set_option_value("wrap", false, { scope = "local", win = 0 })
	end)
	assert_true(panel.render_count > renders, "turning wrap off re-renders the panel")
	assert_contains(buf_text(panel.buf), "…", "with wrap off, long rows are cut again")
	panel.toggle()

	vim.go.wrap = false
	panel.toggle()
	assert_equal(vim.wo[panel.window()].wrap, false, "the panel inherits wrap = false")
	panel.toggle()

	vim.go.wrap, vim.go.linebreak = global_wrap, global_lbr
end

-- ──────────────────────────────────────────────────────────────────────
-- 15. Width as a share of the editor: the default is half of the
--     columns (the top panel: a quarter of the lines), and a fraction
--     follows the editor when it is resized (checked with 0.4).
-- ──────────────────────────────────────────────────────────────────────

assert_equal(DEFAULT_PANEL_WIDTH, 0.5, "the default panel width is 50% of the editor")
assert_equal(DEFAULT_PANEL_HEIGHT, 0.25, "the default top panel height is 25% of the editor")

local columns = vim.o.columns
config.panel_width = 0.4

-- Closed panel: the rows are fitted to 40% of the editor.
local share_buf = vim.api.nvim_create_buf(false, true)
panel.render_into(share_buf, long_ctx)
local share_width = math.floor(columns * 0.4)
for row, line in ipairs(vim.api.nvim_buf_get_lines(share_buf, 0, -1, false)) do
	assert_true(
		vim.fn.strdisplaywidth(line) <= share_width,
		string.format("closed panel: row %d fits 40%% of the editor (%d)", row, share_width)
	)
end

if snacks then
	reset_cache()
	local alpha_buf = make_buffer(ALPHA, ALPHA_LINES)
	vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), alpha_buf)

	panel.toggle()
	assert_equal(
		vim.api.nvim_win_get_width(panel.window()),
		math.floor(vim.o.columns * 0.4),
		"the open panel is 40% of the editor"
	)

	-- The editor gets wider: the panel keeps its share.
	vim.o.columns = columns + 50
	vim.api.nvim_exec_autocmds("VimResized", {})
	vim.cmd("sleep 50m")
	assert_equal(
		vim.api.nvim_win_get_width(panel.window()),
		math.floor(vim.o.columns * 0.4),
		"after a resize the panel is still 40% of the editor"
	)

	panel.toggle()
	vim.o.columns = columns
end

config.panel_width = 48

-- ──────────────────────────────────────────────────────────────────────
-- 16. Opening moves the cursor into the panel; `toggle_top`
--     (<leader>oI) opens it as a top split with the note below.
-- ──────────────────────────────────────────────────────────────────────

if snacks then
	reset_cache()
	vim.cmd("silent! only")
	local alpha_buf = make_buffer(ALPHA, ALPHA_LINES)
	local note_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(note_win, alpha_buf)

	-- Right panel: the cursor lands in it, and it shows the note.
	panel.toggle()
	assert_equal(vim.api.nvim_get_current_win(), panel.window(), "opening the panel moves the cursor into it")
	assert_equal(panel.followed, alpha_buf, "the panel follows the note it was opened from")
	assert_contains(buf_text(panel.buf), "Alpha", "the panel shows the note's task")
	panel.toggle()
	assert_true(not panel.is_open(), "the toggle closes the right panel")

	-- Top panel: full width above the note, cursor in the panel.
	vim.api.nvim_set_current_win(note_win)
	local opened = panel.toggle_top()
	assert_true(opened, "toggle_top opens the panel")
	local top_win = panel.window()
	assert_equal(vim.api.nvim_get_current_win(), top_win, "the top panel takes the cursor")
	assert_equal(vim.api.nvim_win_get_position(top_win)[1], 0, "the top panel sits at the top")
	assert_true(vim.api.nvim_win_get_position(note_win)[1] > 0, "the note window is below the panel")
	assert_equal(vim.api.nvim_win_get_width(top_win), vim.o.columns, "the top panel spans the editor width")
	assert_equal(
		vim.api.nvim_win_get_height(top_win),
		math.floor(vim.o.lines * config.panel_height),
		"the top panel takes its share of the editor height"
	)
	assert_equal(panel.followed, alpha_buf, "the top panel follows the note")
	assert_true(vim.wo[top_win].winfixheight, "the top panel keeps its height")

	-- <leader>oi closes an open panel whatever its position.
	panel.toggle()
	assert_true(not panel.is_open(), "<leader>oi closes the top panel")
	vim.api.nvim_set_current_win(note_win)
	panel.toggle_top()
	panel.toggle_top()
	assert_true(not panel.is_open(), "toggle_top twice leaves no panel")

	-- The right toggle after a top one opens on the right again.
	vim.api.nvim_set_current_win(note_win)
	panel.toggle()
	assert_true(vim.api.nvim_win_get_position(panel.window())[2] > 0, "<leader>oi opens on the right")
	panel.toggle()
end

print("tasknotes panel: ok")
