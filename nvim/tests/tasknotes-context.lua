-- TKT-102 — task context builder (deep module).
--
-- Headless contract test. No HTTP: plenary.curl is stubbed to error, so
-- any accidental network call fails the test loudly.
--
-- Covered:
--   1. build() returns nil for a path that is not in the task cache.
--   2. Parents resolve from `projects` in every observed link shape:
--      [[Name]], [[Name|Alias]], [[folder/Name]] and the quoted form.
--      A parent that is not a task yields is_task = false and no status.
--   3. Subtasks are exactly the tasks whose `projects` resolve to this
--      note's basename; progress counts completed statuses.
--   4. Checklist counts come from the live buffer body only (frontmatter
--      excluded): [ ] open, [x]/[X] done, [-]/[~] doing — including
--      indented items and items inside callouts.
--   5. The module requires nothing but `tasknotes.config`.
--
-- Run: cd nvim && nvim --headless -u NONE --cmd 'set rtp^=.' -l tests/tasknotes-context.lua

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
local function no_network()
	error("tasknotes-context: network access attempted")
end

package.loaded["plenary.curl"] = { get = no_network, post = no_network, put = no_network, delete = no_network }

local context = require("tasknotes.context")
local config = require("tasknotes.config")

local vault = config.vault_path

local function abs(rel)
	return vault .. "/" .. rel
end

-- ──────────────────────────────────────────────────────────────────────
-- Fixtures
-- ──────────────────────────────────────────────────────────────────────
local ALPHA = abs("TaskNotes/Tasks/Alpha.md")
local BETA = abs("TaskNotes/Tasks/Beta.md")
local GAMMA = abs("TaskNotes/Tasks/Gamma.md")
local PARENT = abs("Areas/Parent Note.md")

local TASKS = {
	[ALPHA] = {
		fm = {
			path = "TaskNotes/Tasks/Alpha.md",
			title = "Alpha",
			status = "in-progress",
			priority = "high",
			scheduled = "2026-10-20",
			due = "2026-10-25",
			tags = { "work", "urgent" },
			projects = {
				"[[Parent Note]]",
				"[[Aliased Parent|Alias]]",
				"[[folder/Nested Parent]]",
				'"[[Quoted Parent]]"',
			},
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
			projects = { "[[Alpha]]", "[[folder/Alpha]]" },
		},
		mtime = 0,
	},
	-- A task that also acts as a parent (its own basename is linkable).
	[PARENT] = {
		fm = {
			path = "Areas/Parent Note.md",
			title = "Parent Note",
			status = "done",
			priority = "normal",
			scheduled = "2026-09-01",
			due = "2026-09-30",
		},
		mtime = 0,
	},
}

local ALPHA_LINES = {
	"---",
	"task: Alpha",
	"status: in-progress",
	"---",
	"",
	"- [ ] open item",
	"  - [x] nested done item",
	"> - [-] doing item inside a callout",
	"  - [~] doing item, two-space indent",
	"- [X] done item, uppercase",
	"",
	"Some prose that is not a checklist.",
}

local ALPHA_CTX = {
	tasks = TASKS,
	lines = ALPHA_LINES,
	completed = { done = true },
	generation = 1,
}

-- ──────────────────────────────────────────────────────────────────────
-- 1. Unknown path → nil
-- ──────────────────────────────────────────────────────────────────────
assert_equal(context.build(abs("TaskNotes/Tasks/Nope.md"), ALPHA_CTX), nil, "unknown path yields no context")
assert_equal(context.build("", ALPHA_CTX), nil, "empty path yields no context")

local ctx = context.build(ALPHA, ALPHA_CTX)
assert_true(ctx ~= nil, "known task yields a context")
assert_equal(ctx.path, ALPHA, "context carries the absolute path")
assert_equal(ctx.task.title, "Alpha", "context carries the task record")

-- ──────────────────────────────────────────────────────────────────────
-- 2. Parents resolve in every observed link shape
-- ──────────────────────────────────────────────────────────────────────
local function parent_named(name)
	for _, p in ipairs(ctx.parents) do
		if p.name == name then
			return p
		end
	end
	return nil
end

assert_equal(#ctx.parents, 4, "every project link becomes a parent ref")

local plain = parent_named("Parent Note")
assert_true(plain ~= nil, "parent [[Parent Note]] resolves")
assert_true(plain.is_task, "a parent that is a task is flagged is_task")
assert_equal(plain.path, PARENT, "parent resolves to the task's absolute path")
assert_equal(plain.status, "done", "parent carries the task status")
assert_equal(plain.priority, "normal", "parent carries the task priority")

local aliased = parent_named("Aliased Parent")
assert_true(aliased ~= nil, "parent [[Aliased Parent|Alias]] resolves by target")
assert_equal(aliased.status, nil, "a non-task parent has no status")

local nested = parent_named("Nested Parent")
assert_true(nested ~= nil, "parent [[folder/Nested Parent]] resolves by basename")
assert_equal(nested.is_task, false, "a non-task parent is not a task")
assert_equal(nested.path, nil, "a non-task parent has no path")
assert_equal(nested.status, nil, "a non-task parent has no status")

local quoted = parent_named("Quoted Parent")
assert_true(quoted ~= nil, "parent \"[[Quoted Parent]]\" resolves")
assert_equal(quoted.is_task, false, "quoted non-task parent is not a task")

-- A task that IS a parent keeps its live fields.
local parent_ctx = context.build(PARENT, ALPHA_CTX)
assert_true(parent_ctx ~= nil, "parent note is a task too")
assert_equal(#parent_ctx.parents, 0, "a task without projects has no parents")

-- ──────────────────────────────────────────────────────────────────────
-- 3. Subtasks + progress
-- ──────────────────────────────────────────────────────────────────────
assert_equal(#ctx.subtasks, 2, "subtasks are exactly the tasks projecting onto Alpha")
local names = {}
for _, s in ipairs(ctx.subtasks) do
	names[s.name] = true
end
assert_true(names["Beta"], "Beta is a subtask of Alpha")
assert_true(names["Gamma"], "Gamma is a subtask of Alpha (folder link)")
assert_equal(names["Alpha"], nil, "a task is not its own subtask")

assert_equal(ctx.progress.total, 2, "progress counts every subtask")
assert_equal(ctx.progress.done, 1, "progress counts completed subtasks")

-- Ordering: by title when no ranks are supplied.
assert_equal(ctx.subtasks[1].name, "Beta", "subtasks are ordered by title without ranks")
assert_equal(ctx.subtasks[2].name, "Gamma", "subtasks are ordered by title without ranks")

-- Ordering: by status rank when ranks are supplied (in-progress before
-- done), then by scheduled date.
local ranked_ctx = context.build(ALPHA, {
	tasks = TASKS,
	lines = ALPHA_LINES,
	completed = { done = true },
	generation = 1,
	status_ranks = { ["in-progress"] = 2, done = 3 },
})
assert_equal(ranked_ctx.subtasks[1].name, "Gamma", "ranked subtasks: in-progress comes first")
assert_equal(ranked_ctx.subtasks[2].name, "Beta", "ranked subtasks: done comes last")

-- Completion semantics follow the injected set: without it, the config
-- fallback (done) applies.
local ctx_no_completed = context.build(ALPHA, {
	tasks = TASKS,
	lines = ALPHA_LINES,
	generation = 1,
})
assert_equal(ctx_no_completed.progress.done, 1, "config fallback marks done as completed")

-- ──────────────────────────────────────────────────────────────────────
-- 4. Checklist counts (body only)
-- ──────────────────────────────────────────────────────────────────────
assert_equal(ctx.fm_end_row, 3, "fm_end_row is the 0-based row of the closing fence")
assert_equal(ctx.checklist.done, 2, "[x] and [X] count as done")
assert_equal(ctx.checklist.doing, 2, "[-] and [~] count as doing")
assert_equal(ctx.checklist.open, 1, "[ ] counts as open")

-- Frontmatter must never contribute: a checkbox-looking frontmatter line
-- is ignored.
local fm_checklist_lines = {
	"---",
	"task: \"- [x] not a checklist item\"",
	"---",
	"- [ ] real open item",
}
local fm_ctx = context.build(ALPHA, {
	tasks = TASKS,
	lines = fm_checklist_lines,
	generation = 1,
})
assert_equal(fm_ctx.checklist.done, 0, "frontmatter lines are not checklist items")
assert_equal(fm_ctx.checklist.open, 1, "body checklist still counted")
assert_equal(fm_ctx.fm_end_row, 2, "fm_end_row points at the closing fence")

-- A buffer without frontmatter yields no anchor (nothing to draw on).
local no_fm = context.build(ALPHA, { tasks = TASKS, lines = { "# Just a heading" }, generation = 1 })
assert_equal(no_fm.fm_end_row, nil, "no frontmatter → no fm_end_row")
assert_equal(no_fm.checklist.done, 0, "no frontmatter → no checklist items")
assert_equal(no_fm.checklist.open, 0, "no frontmatter → no checklist items")

-- ──────────────────────────────────────────────────────────────────────
-- 5. Require-set guarantee: context only depends on config
-- ──────────────────────────────────────────────────────────────────────
local source_path = vim.api.nvim_get_runtime_file("lua/tasknotes/context.lua", false)[1]
assert_true(source_path ~= nil, "context.lua is on the runtimepath")

local source = table.concat(vim.fn.readfile(source_path), "\n")
local required = {}
for module in source:gmatch('require%s*%(%s*["\']?([%w_%.]+)') do
	required[module] = true
end

local allowed = { ["tasknotes.config"] = true }
for module in pairs(required) do
	assert_true(allowed[module] == true, "context.lua must not require " .. module)
end
assert_true(required["tasknotes.config"] == true, "context.lua requires tasknotes.config")

print("tasknotes context: ok")
