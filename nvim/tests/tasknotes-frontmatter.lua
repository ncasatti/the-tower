-- TKT-104 — hidden frontmatter (conceal_lines extmark + toggle).
--
-- Headless contract test. plenary.curl is stubbed to error, so any
-- request that escapes the view path fails the test loudly.
--
-- Covered:
--   1. A task note's frontmatter rows are concealed with ONE
--      `conceal_lines` extmark that stops right above the closing
--      fence; the buffer text is untouched (`modified` stays false) and
--      'conceallevel' is not lowered.
--   2. The inline card keeps its virtual lines (the fence row is not
--      concealed, so the card's anchor survives).
--   3. A vault note that is not a task and a buffer outside the vault
--      get no extmark.
--   4. Toggling off clears the namespace in every loaded task buffer;
--      toggling on restores it; the toggle returns the new state.
--   5. The conceal follows the fence when lines are inserted above it
--      (the debounced TextChanged path).
--   6. The cache-refreshed event applies the conceal to a note that
--      became a task after it was opened.
--   7. Zero requests (require-set test): frontmatter.lua does not
--      require tasknotes.api, tasknotes.task_ops or plenary.curl.
--
-- Run: nvim --headless -u NONE --cmd 'set rtp^=.' -l tests/tasknotes-frontmatter.lua

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
	error("tasknotes-frontmatter: network access attempted")
end

package.loaded["plenary.curl"] = { get = no_network, post = no_network, put = no_network, delete = no_network }

local api = require("tasknotes.api")
local cache = require("tasknotes.cache")
local card = require("tasknotes.card")
local config = require("tasknotes.config")
local frontmatter = require("tasknotes.frontmatter")

-- The conceal only draws when 'conceallevel' >= 1 (the config sets 2).
vim.o.conceallevel = 2
vim.o.wrap = false

-- Notification capture.
local notifications = {}
vim.notify = function(msg, level)
	table.insert(notifications, { msg = msg, level = level })
end

-- ──────────────────────────────────────────────────────────────────────
-- Fixtures — a throwaway vault
-- ──────────────────────────────────────────────────────────────────────
local real_vault = config.vault_path
local vault = vim.fn.tempname()
vim.fn.mkdir(vault .. "/TaskNotes/Tasks", "p")
vim.fn.mkdir(vault .. "/Notes", "p")
config.vault_path = vault

local ALPHA = vim.fs.normalize(vault .. "/TaskNotes/Tasks/Alpha.md")
local GAMMA = vim.fs.normalize(vault .. "/TaskNotes/Tasks/Gamma.md")
local PLAIN = vim.fs.normalize(vault .. "/Notes/Plain.md")
local OUTSIDE = "/tmp/not-the-vault/Other.md"

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

-- 0-based row of the closing `---` in ALPHA_LINES.
local FENCE_ROW = 3

local GAMMA_LINES = {
	"---",
	"task: Gamma",
	"status: in-progress",
	"---",
	"",
	"- [ ] open",
}

local TASKS = {
	[ALPHA] = {
		fm = {
			path = "TaskNotes/Tasks/Alpha.md",
			title = "Alpha",
			status = "in-progress",
			priority = "high",
			scheduled = "2026-10-20",
			tags = { "work" },
			projects = { "[[Parent Note]]" },
		},
		mtime = 0,
	},
}

local function reset_cache()
	cache.data = vim.deepcopy(TASKS)
	cache.keys_index = {}
	cache.generation = (cache.generation or 0) + 1
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

-- Creates a scratch buffer that looks like a note in the vault.
--
-- The modified flag is cleared, so the buffer looks like a note that was
-- just opened from disk (the conceal must never set it).
local function make_buffer(path, lines)
	local buf = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_buf_set_name(buf, path)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modified = false
	return buf
end

-- The extmarks of the frontmatter namespace in a buffer.
local function fm_marks(buf)
	return vim.api.nvim_buf_get_extmarks(buf, frontmatter.ns, 0, -1, { details = true })
end

-- The height of the window showing `buf`.
--
-- The cursor is parked on the last row: entering a concealed row
-- reveals it, which would change the height.
local function win_height(buf)
	vim.api.nvim_set_current_buf(buf)
	vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(buf), 0 })
	return vim.api.nvim_win_text_height(0, {}).all
end

-- ──────────────────────────────────────────────────────────────────────
-- 1. The frontmatter rows are concealed, the fence stays visible
-- ──────────────────────────────────────────────────────────────────────
reset_cache()

local buf = make_buffer(ALPHA, ALPHA_LINES)
local before = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
local height_before = win_height(buf)

frontmatter.apply(buf)

local marks = fm_marks(buf)
assert_equal(#marks, 1, "the frontmatter is concealed with a single extmark")
assert_equal(marks[1][2], 0, "the mark starts on the first row")
assert_equal(marks[1][4].conceal_lines, "", "the mark is a conceal_lines mark")
assert_equal(marks[1][4].end_row, FENCE_ROW - 1, "the conceal stops right above the closing fence")

assert_equal(win_height(buf), height_before - FENCE_ROW, "the window drops the frontmatter rows")

-- The buffer itself is untouched.
assert_equal(vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), before), true, "the buffer text is unchanged")
assert_equal(vim.bo[buf].modified, false, "the buffer modified flag stays false")
assert_equal(vim.o.conceallevel, 2, "conceallevel is not lowered")
assert_equal(http.calls, 0, "the view performs no request")

-- ──────────────────────────────────────────────────────────────────────
-- 2. The inline card keeps its virtual lines
-- ──────────────────────────────────────────────────────────────────────
-- Reveal the frontmatter again to measure the card on its own.
vim.api.nvim_buf_clear_namespace(buf, frontmatter.ns, 0, -1)

card.render(buf, card.context_for(buf))
local card_marks = vim.api.nvim_buf_get_extmarks(buf, card.ns, 0, -1, { details = true })
assert_equal(#card_marks, 1, "the card is drawn as a single extmark")
assert_equal(card_marks[1][2], FENCE_ROW, "the card is anchored on the closing fence")
local card_lines = #card_marks[1][4].virt_lines
assert_true(card_lines >= 3, "the card has several virtual lines")

local height_with_card = win_height(buf)

frontmatter.apply(buf)
local height_with_card_and_conceal = win_height(buf)

assert_equal(
	height_with_card_and_conceal,
	height_with_card - FENCE_ROW,
	"the card's virtual lines still count in the window height (the fence is not concealed)"
)

-- ──────────────────────────────────────────────────────────────────────
-- 3. Notes that are not tasks get no extmark
-- ──────────────────────────────────────────────────────────────────────
local plain = make_buffer(PLAIN, { "---", "title: Plain", "---", "", "Just a note." })
frontmatter.apply(plain)
assert_equal(#fm_marks(plain), 0, "a vault note that is not a task gets no extmark")

local outside = make_buffer(OUTSIDE, { "---", "task: Other", "---", "", "Elsewhere." })
frontmatter.apply(outside)
assert_equal(#fm_marks(outside), 0, "a buffer outside the vault gets no extmark")

-- ──────────────────────────────────────────────────────────────────────
-- 4. Toggle off clears every loaded task buffer; toggle on restores it
-- ──────────────────────────────────────────────────────────────────────
frontmatter.hidden = true
frontmatter.apply(buf)
assert_equal(#fm_marks(buf), 1, "the task buffer is concealed")

local state = frontmatter.toggle()
assert_equal(state, false, "toggle returns the new state (hidden off)")
assert_equal(frontmatter.hidden, false, "the state flipped to shown")
assert_equal(#fm_marks(buf), 0, "toggle off clears the namespace in the task buffer")

state = frontmatter.toggle()
assert_equal(state, true, "toggle returns the new state (hidden on)")
assert_equal(frontmatter.hidden, true, "the state flipped back to hidden")
assert_equal(#fm_marks(buf), 1, "toggle on restores the conceal")
assert_true(#notifications > 0, "the toggle notifies")
assert_equal(notifications[#notifications].level, vim.log.levels.INFO, "the toggle notifies at INFO level")

-- ──────────────────────────────────────────────────────────────────────
-- 5. The conceal follows the fence when lines are inserted above it
-- ──────────────────────────────────────────────────────────────────────
frontmatter.attach()

vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "# Inserted heading", "" })
vim.api.nvim_exec_autocmds("TextChanged", { buffer = buf })
vim.wait(400)

marks = fm_marks(buf)
assert_equal(#marks, 1, "still a single extmark after the edit")
assert_equal(marks[1][4].end_row, FENCE_ROW + 1, "the conceal follows the fence down by two rows")

-- ──────────────────────────────────────────────────────────────────────
-- 6. The cache lands after the note was opened
-- ──────────────────────────────────────────────────────────────────────
local gamma = make_buffer(GAMMA, GAMMA_LINES)
frontmatter.apply(gamma)
assert_equal(#fm_marks(gamma), 0, "a note that is not in the cache yet gets no conceal")

cache.data[GAMMA] = {
	fm = {
		path = "TaskNotes/Tasks/Gamma.md",
		title = "Gamma",
		status = "in-progress",
		priority = "normal",
	},
	mtime = 0,
}
cache.generation = cache.generation + 1

vim.api.nvim_exec_autocmds("User", { pattern = "TaskNotesCacheRefreshed", modeline = false })
assert_equal(#fm_marks(gamma), 1, "the cache-refreshed event applies the conceal")

-- ──────────────────────────────────────────────────────────────────────
-- 7. Require-set guarantee
-- ──────────────────────────────────────────────────────────────────────
assert_equal(http.calls, 0, "no request happened during the whole run")

local forbidden = { ["tasknotes.api"] = true, ["tasknotes.task_ops"] = true, ["plenary.curl"] = true }

local source_path = vim.api.nvim_get_runtime_file("lua/tasknotes/frontmatter.lua", false)[1]
assert_true(source_path ~= nil, "lua/tasknotes/frontmatter.lua is on the runtimepath")

local source = table.concat(vim.fn.readfile(source_path), "\n")
for module in source:gmatch('require%s*%(%s*["\']?([%w_%.]+)') do
	assert_true(forbidden[module] ~= true, "frontmatter.lua must not require " .. module)
end

-- ──────────────────────────────────────────────────────────────────────
-- Teardown
-- ──────────────────────────────────────────────────────────────────────
config.vault_path = real_vault
vim.fn.delete(vault, "rf")

print("tasknotes frontmatter: ok")
