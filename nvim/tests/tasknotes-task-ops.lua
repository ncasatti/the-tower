-- TKT-104 — shared save path for task field edits (ODD tasknotes-panel-edit, T1).
--
-- Headless contract test. plenary.curl is stubbed: the PUT records every
-- call, reads the file from disk (to prove the note buffer was written
-- BEFORE the request) and simulates the server rewriting the frontmatter.
--
-- Covered:
--   1. apply_patch writes an unsaved buffer before the PUT, reloads it
--      afterwards WITHOUT `edit!` and shows the server's frontmatter.
--   2. A failed PUT leaves the buffer alone (no reload) and returns nil.
--   3. An empty patch sends no request.
--   4. apply_patch acts on the buffer it is given, even when that buffer
--      is not the current one.
--   5. The <leader>oe Save path goes through apply_patch with the buffer
--      the editor was opened from.
--   6. Without opts.buf the note buffer is found by its path.
--   7. A failing write aborts the save before any request.
--   8. edit_field edits a single field and saves it through apply_patch.
--   9. A cancelled edit sends no request and notifies nothing.
--  10. An invalid time estimate sends no request.
--  11. The estimate is saved in minutes; an empty one clears it.
--  12. _pick_text without a continuation still returns to the editor.
--
-- Run: cd nvim && nvim --headless -u NONE --cmd 'set rtp^=.' -l tests/tasknotes-task-ops.lua

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

local function assert_nil(value, label)
	if value ~= nil then
		error(string.format("%s: expected nil, got %s", label, vim.inspect(value)))
	end
end

local function assert_contains(haystack, needle, label)
	if type(haystack) ~= "string" or not haystack:find(needle, 1, true) then
		error(string.format("%s: expected %s to contain %s", label, vim.inspect(haystack), vim.inspect(needle)))
	end
end

-- Runs one case and remembers its failure, so a single run reports every
-- broken case instead of only the first one. The script still fails
-- (non-zero exit) when any case failed.
local failures = {}

local function section(title, fn)
	local ok, err = pcall(fn)
	if not ok then
		table.insert(failures, string.format("%s: %s", title, tostring(err)))
	end
end

-- ──────────────────────────────────────────────────────────────────────
-- Fixture — a throwaway vault so the test writes real files
-- ──────────────────────────────────────────────────────────────────────
local vault = vim.fn.tempname() .. "/vault"
vim.fn.mkdir(vault .. "/TaskNotes/Tasks", "p")

local TASK_ID = "TaskNotes/Tasks/Task.md"
local TASK_FILE = vault .. "/" .. TASK_ID
local UNSAVED = "unsaved note line"

local function reset_task_file()
	vim.fn.writefile({ "---", "task: Task", "status: inbox", "---", "", "body line" }, TASK_FILE)
end

reset_task_file()

-- ──────────────────────────────────────────────────────────────────────
-- plenary.curl stub — no network, the PUT simulates the server
-- ──────────────────────────────────────────────────────────────────────
-- get_tasks — the task list GET /tasks answers with
-- put_task  — the task the PUT answers with (nil = a minimal default)
-- defer_get — when true, async GET callbacks are queued in `deferred`
--             instead of answered at once (a request still in flight)
local http = { puts = {}, gets = 0, unsaved_at_put = false, fail = false, get_tasks = {}, deferred = {} }

local function reset_http()
	http.puts = {}
	http.gets = 0
	http.unsaved_at_put = false
	http.fail = false
	http.get_tasks = {}
	http.put_task = nil
	http.defer_get = false
	http.deferred = {}
end

local function tasks_response(tasks)
	return { status = 200, body = vim.fn.json_encode({ success = true, data = { tasks = tasks } }) }
end

-- Splits a note into its frontmatter lines and its body lines.
local function split_frontmatter(lines)
	local fences = 0
	for i, line in ipairs(lines) do
		if line == "---" then
			fences = fences + 1
			if fences == 2 then
				return vim.list_slice(lines, 1, i), vim.list_slice(lines, i + 1, #lines)
			end
		end
	end
	return lines, {}
end

-- The server rewrites the frontmatter and keeps the body it read.
local function server_rewrite(lines)
	local _, body = split_frontmatter(lines)
	vim.fn.writefile(vim.list_extend({ "---", "task: Task", "status: done", "---", "" }, body), TASK_FILE)
end

package.loaded["plenary.curl"] = {
	get = function(url, opts)
		http.gets = http.gets + 1
		-- The answer is taken when the request is SENT: a deferred
		-- request answers with what the server held at that moment.
		local res = tasks_response(vim.deepcopy(http.get_tasks))
		if opts and opts.callback then
			if http.defer_get then
				table.insert(http.deferred, function()
					opts.callback(res)
				end)
			else
				opts.callback(res)
			end
		end
		return res
	end,
	post = function()
		error("tasknotes-task-ops: unexpected POST")
	end,
	put = function(url, opts)
		table.insert(http.puts, { url = url, body = opts and opts.body })

		-- The plugin must have written the buffer BEFORE the request.
		local disk = vim.fn.readfile(TASK_FILE)
		http.unsaved_at_put = table.concat(disk, "\n"):find(UNSAVED, 1, true) ~= nil
		server_rewrite(disk)

		if http.fail then
			return { status = 500, body = "" }
		end
		return {
			status = 200,
			body = vim.fn.json_encode({
				success = true,
				data = http.put_task or { path = TASK_ID, title = "Task", status = "done" },
			}),
		}
	end,
	delete = function()
		error("tasknotes-task-ops: unexpected DELETE")
	end,
}

local api = require("tasknotes.api")
local config = require("tasknotes.config")
local task_ops = require("tasknotes.task_ops")

config.vault_path = vault

-- Notification capture (the texts are part of the contract).
local notifications = {}
vim.notify = function(msg, level)
	table.insert(notifications, { msg = msg, level = level })
end

local function notified(needle)
	for _, n in ipairs(notifications) do
		if type(n.msg) == "string" and n.msg:find(needle, 1, true) then
			return n
		end
	end
	return nil
end

local function buf_text(buf)
	return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
end

-- Opens the task file in the current window and appends an unsaved line.
local function open_dirty_task()
	vim.cmd("edit! " .. vim.fn.fnameescape(TASK_FILE))
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_lines(buf, -1, -1, false, { UNSAVED })
	vim.bo[buf].modified = true
	return buf
end

local win = vim.api.nvim_get_current_win()

-- ──────────────────────────────────────────────────────────────────────
-- 1. Unsaved text is written before the PUT; the buffer is reloaded
--    afterwards without `edit!`
-- ──────────────────────────────────────────────────────────────────────
section("1 unsaved text is written before the PUT", function()
	reset_http()
	reset_task_file()

	local task_buf = open_dirty_task()

	local updated = task_ops.apply_patch(TASK_ID, { status = "done" }, { buf = task_buf })

	assert_true(updated ~= nil, "apply_patch returns the updated task")
	assert_equal(#http.puts, 1, "exactly one PUT is sent")
	local sent = vim.fn.json_decode(http.puts[1].body)
	assert_equal(sent.status, "done", "the PUT carries the patch")
	assert_true(http.unsaved_at_put, "the unsaved text was written to disk BEFORE the PUT")

	local text = buf_text(task_buf)
	assert_contains(text, UNSAVED, "the unsaved text survives the save")
	assert_contains(text, "status: done", "the server's frontmatter shows up in the buffer")
	assert_equal(vim.bo[task_buf].modified, false, "the reloaded buffer is clean")
	assert_true(notified("Saved 1 field(s)") ~= nil, "the save is reported")
end)

-- ──────────────────────────────────────────────────────────────────────
-- 2. A failed PUT keeps the buffer as it was after the pre-write
-- ──────────────────────────────────────────────────────────────────────
section("2 a failed PUT keeps the buffer", function()
	reset_http()
	reset_task_file()
	http.fail = true

	local fail_buf = open_dirty_task()
	local fail_result = task_ops.apply_patch(TASK_ID, { status = "done" }, { buf = fail_buf })

	assert_nil(fail_result, "a failed PUT returns nil")
	assert_equal(#http.puts, 1, "the PUT was attempted once")
	local fail_text = buf_text(fail_buf)
	assert_contains(fail_text, UNSAVED, "the buffer text is unchanged after a failed PUT")
	assert_equal(vim.bo[fail_buf].modified, false, "the pre-write already cleared the modified flag")
	assert_true(fail_text:find("status: done", 1, true) == nil, "the buffer is NOT reloaded after a failed PUT")
	assert_true(notified("Could not update task: " .. TASK_ID) ~= nil, "the failure is reported")
end)

-- ──────────────────────────────────────────────────────────────────────
-- 3. An empty patch sends no request
-- ──────────────────────────────────────────────────────────────────────
section("3 an empty patch sends no request", function()
	reset_http()

	local empty_result = task_ops.apply_patch(TASK_ID, {}, { buf = 0 })

	assert_nil(empty_result, "an empty patch returns nil")
	assert_equal(#http.puts, 0, "an empty patch sends no request")
	assert_true(notified("No changes to save") ~= nil, "the empty patch is reported")
end)

-- ──────────────────────────────────────────────────────────────────────
-- 4. apply_patch acts on the buffer it is given, not on the current one
-- ──────────────────────────────────────────────────────────────────────
section("4 apply_patch acts on the given buffer", function()
	reset_http()
	reset_task_file()

	local target_buf = open_dirty_task()

	local other_buf = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_buf_set_name(other_buf, vault .. "/Other.md")
	vim.api.nvim_buf_set_lines(other_buf, 0, -1, false, { "other content" })
	vim.bo[other_buf].modified = false
	vim.api.nvim_win_set_buf(win, other_buf)

	local other_updated = task_ops.apply_patch(TASK_ID, { status = "done" }, { buf = target_buf })

	assert_true(other_updated ~= nil, "apply_patch updates the given buffer")
	assert_true(http.unsaved_at_put, "the given buffer was written to disk")
	local target_text = buf_text(target_buf)
	assert_contains(target_text, UNSAVED, "the given buffer keeps its unsaved text")
	assert_contains(target_text, "status: done", "the given buffer was reloaded from disk")
	assert_equal(vim.bo[target_buf].modified, false, "the given buffer is clean after the reload")
	assert_equal(vim.api.nvim_get_current_buf(), other_buf, "the current buffer is untouched")
	assert_equal(buf_text(other_buf), "other content", "the current buffer's content is untouched")
end)

-- ──────────────────────────────────────────────────────────────────────
-- 5. The <leader>oe Save path goes through apply_patch with the buffer
--    the editor was opened from
-- ──────────────────────────────────────────────────────────────────────
section("5 the oe Save path goes through apply_patch", function()
	reset_http()
	reset_task_file()

	local open_buf = open_dirty_task()

	-- Spy on apply_patch.
	local original_apply_patch = task_ops.apply_patch
	local seen = nil
	task_ops.apply_patch = function(id, patch, opts)
		seen = { id = id, patch = patch, opts = opts }
		return original_apply_patch(id, patch, opts)
	end

	task_ops.edit_fields._save(TASK_ID, { status = "done" }, open_buf)

	assert_true(seen ~= nil, "the Save action goes through apply_patch")
	assert_equal(seen.id, TASK_ID, "apply_patch receives the task id")
	assert_equal(seen.opts.buf, open_buf, "apply_patch receives the buffer the editor was opened from")
	assert_equal(#http.puts, 1, "the Save action fires a single PUT")
	assert_true(http.unsaved_at_put, "the Save action writes the buffer before the PUT")

	task_ops.apply_patch = original_apply_patch

	-- `open()` must capture the buffer the editor was opened from and
	-- thread it through to the editor.
	local original_show = task_ops.edit_fields._show
	local original_get_task_paths = api.get_task_paths
	local original_get_task = api.get_task
	local captured = nil

	task_ops.edit_fields._show = function(id, task, patch, buf)
		captured = { id = id, task = task, patch = patch, buf = buf }
	end
	api.get_task_paths = function()
		return { [TASK_ID] = true }
	end
	api.get_task = function()
		return { title = "Task", status = "inbox" }
	end

	vim.api.nvim_win_set_buf(win, open_buf)
	task_ops.edit_fields.open()

	assert_true(captured ~= nil, "open() shows the field editor")
	assert_equal(captured.id, TASK_ID, "open() resolves the task id from the current buffer")
	assert_equal(captured.buf, open_buf, "open() captures the buffer the editor was opened from")

	task_ops.edit_fields._show = original_show
	api.get_task_paths = original_get_task_paths
	api.get_task = original_get_task
end)

-- ──────────────────────────────────────────────────────────────────────
-- 6. Without opts.buf the note buffer is found by its path
-- ──────────────────────────────────────────────────────────────────────
section("6 the note buffer is found by path when opts.buf is absent", function()
	reset_http()
	reset_task_file()

	local found_buf = open_dirty_task()

	-- The note is NOT the current buffer: the path lookup must find it
	-- on its own.
	local other_buf = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_buf_set_name(other_buf, vault .. "/Other2.md")
	vim.api.nvim_buf_set_lines(other_buf, 0, -1, false, { "other content" })
	vim.api.nvim_win_set_buf(win, other_buf)

	local found = task_ops.apply_patch(TASK_ID, { status = "done" })

	assert_true(found ~= nil, "apply_patch without opts.buf still saves")
	assert_true(http.unsaved_at_put, "the discovered buffer was written to disk")
	local found_text = buf_text(found_buf)
	assert_contains(found_text, UNSAVED, "the discovered buffer keeps its unsaved text")
	assert_contains(found_text, "status: done", "the discovered buffer was reloaded from disk")
	assert_equal(vim.bo[found_buf].modified, false, "the discovered buffer is clean after the reload")
	assert_equal(vim.api.nvim_get_current_buf(), other_buf, "the current buffer is untouched")
end)

-- ──────────────────────────────────────────────────────────────────────
-- 7. A failing write aborts the save before any request
-- ──────────────────────────────────────────────────────────────────────
section("7 a failing write sends no PUT", function()
	reset_http()
	reset_task_file()

	local ro_buf = open_dirty_task()
	-- A read-only buffer cannot be written: the save must abort BEFORE
	-- the PUT, so the server never sees a half-applied change.
	vim.bo[ro_buf].readonly = true

	local ro_result = task_ops.apply_patch(TASK_ID, { status = "done" }, { buf = ro_buf })

	assert_nil(ro_result, "a failed write returns nil")
	assert_equal(#http.puts, 0, "a failed write sends no PUT")
	assert_true(notified("Could not save note: " .. TASK_ID) ~= nil, "the failed write is reported")
	assert_equal(vim.bo[ro_buf].modified, true, "the buffer keeps its unsaved changes after a failed write")

	vim.bo[ro_buf].readonly = false
end)

-- ──────────────────────────────────────────────────────────────────────
-- 8. edit_field edits a single field and saves it through apply_patch
-- ──────────────────────────────────────────────────────────────────────
section("8 edit_field saves a single field", function()
	reset_http()
	reset_task_file()

	local task_buf = open_dirty_task()

	-- The task is fetched from the API (one GET), the new value is
	-- typed in (no picker UI), the result is saved with one PUT.
	local original_get_task = api.get_task
	local original_input = vim.ui.input
	api.get_task = function()
		return { title = "Task", status = "inbox" }
	end
	vim.ui.input = function(_, on_confirm)
		on_confirm("Renamed")
	end

	task_ops.edit_field(TASK_ID, "title", { buf = task_buf })

	api.get_task = original_get_task
	vim.ui.input = original_input

	assert_equal(#http.puts, 1, "exactly one PUT is sent")
	local sent = vim.fn.json_decode(http.puts[1].body)
	assert_equal(sent.title, "Renamed", "the PUT carries the new title")
	assert_equal(sent.status, nil, "the PUT carries only the edited field")
	assert_true(http.unsaved_at_put, "the note buffer was written before the PUT")
	assert_true(
		http.puts[1].url:find("TaskNotes%2FTasks%2FTask.md", 1, true) ~= nil,
		"the PUT targets the task id"
	)
end)

-- ──────────────────────────────────────────────────────────────────────
-- 9. A cancelled edit sends no request and notifies nothing
-- ──────────────────────────────────────────────────────────────────────
section("9 a cancelled edit sends no request", function()
	reset_http()
	reset_task_file()

	local task_buf = open_dirty_task()

	local original_get_task = api.get_task
	local original_input = vim.ui.input
	api.get_task = function()
		return { title = "Task", status = "inbox" }
	end
	vim.ui.input = function(_, on_confirm)
		on_confirm(nil) -- Esc
	end

	local before = #notifications
	task_ops.edit_field(TASK_ID, "title", { buf = task_buf })

	api.get_task = original_get_task
	vim.ui.input = original_input

	assert_equal(#http.puts, 0, "a cancelled edit sends no PUT")
	assert_equal(#notifications, before, "a cancelled edit notifies nothing")
end)

-- ──────────────────────────────────────────────────────────────────────
-- 10. An invalid time estimate sends no request
-- ──────────────────────────────────────────────────────────────────────
section("10 an invalid estimate sends no request", function()
	reset_http()
	reset_task_file()

	local task_buf = open_dirty_task()

	local original_get_task = api.get_task
	local original_input = vim.ui.input
	api.get_task = function()
		return { title = "Task", timeEstimate = 30 }
	end
	vim.ui.input = function(_, on_confirm)
		on_confirm("not a number")
	end

	local before = #notifications
	task_ops.edit_field(TASK_ID, "timeEstimate", { buf = task_buf })

	api.get_task = original_get_task
	vim.ui.input = original_input

	assert_equal(#http.puts, 0, "an invalid estimate sends no PUT")
	assert_true(#notifications > before, "the invalid estimate is reported")
end)

-- ──────────────────────────────────────────────────────────────────────
-- 11. The estimate is saved in minutes and an empty one clears it
-- ──────────────────────────────────────────────────────────────────────
section("11 the estimate is saved in minutes", function()
	reset_http()
	reset_task_file()

	local task_buf = open_dirty_task()

	local original_get_task = api.get_task
	local original_input = vim.ui.input
	api.get_task = function()
		return { title = "Task", timeEstimate = 30 }
	end

	vim.ui.input = function(_, on_confirm)
		on_confirm("90")
	end
	task_ops.edit_field(TASK_ID, "timeEstimate", { buf = task_buf })

	assert_equal(#http.puts, 1, "the estimate is saved with one PUT")
	local sent = vim.fn.json_decode(http.puts[1].body)
	assert_equal(sent.timeEstimate, 90, "the estimate is saved in minutes")

	reset_http()
	vim.ui.input = function(_, on_confirm)
		on_confirm("") -- empty input clears the estimate
	end
	task_ops.edit_field(TASK_ID, "timeEstimate", { buf = task_buf })

	assert_equal(#http.puts, 1, "the cleared estimate is saved with one PUT")
	local cleared = vim.fn.json_decode(http.puts[1].body)
	assert_equal(cleared.timeEstimate, "", "an empty estimate clears the field")

	api.get_task = original_get_task
	vim.ui.input = original_input
end)

-- ──────────────────────────────────────────────────────────────────────
-- 12. A picker without a continuation still returns to the editor
-- ──────────────────────────────────────────────────────────────────────
section("12 a picker without a continuation returns to the editor", function()
	local original_show = task_ops.edit_fields._show
	local original_input = vim.ui.input
	local captured = nil

	task_ops.edit_fields._show = function(id, task, patch, buf)
		captured = { id = id, task = task, patch = patch, buf = buf }
	end
	vim.ui.input = function(_, on_confirm)
		on_confirm("Renamed")
	end

	local patch = {}
	local buf = vim.api.nvim_get_current_buf()
	task_ops.edit_fields._pick_text(TASK_ID, { title = "Task" }, patch, "title", buf)

	task_ops.edit_fields._show = original_show
	vim.ui.input = original_input

	assert_true(captured ~= nil, "the picker returns to the field editor")
	assert_equal(captured.id, TASK_ID, "the editor keeps the task id")
	assert_equal(captured.buf, buf, "the editor keeps the buffer")
	assert_equal(patch.title, "Renamed", "the patch carries the new value")
end)

-- ──────────────────────────────────────────────────────────────────────
-- 13. A saved field shows up in the cache (and so in the panel and the
--     card) even when the task list still answers with the old task:
--     a refresh already in flight when the PUT is sent, or a server
--     index that lags behind its own write.
-- ──────────────────────────────────────────────────────────────────────
local cache = require("tasknotes.cache")
local ABS = vault .. "/" .. TASK_ID
local OLD = { path = TASK_ID, title = "Task", status = "inbox", scheduled = "2026-11-09", dateModified = "2026-11-09T10:00:00.000-03:00" }
local NEW = { path = TASK_ID, title = "Task", status = "inbox", scheduled = "2026-11-20", dateModified = "2026-11-19T10:00:00.000-03:00" }

local function scheduled_in_cache()
	local entry = cache.data[ABS]
	return entry and entry.fm and entry.fm.scheduled
end

local function drain()
	vim.wait(50, function()
		return false
	end)
end

local function seed_cache(task)
	-- Earlier sections leave async answers scheduled; let them land now
	-- so they cannot rewrite the cache in the middle of this case.
	drain()
	cache.data = { [ABS] = { fm = vim.deepcopy(task), mtime = 0 } }
	cache.pending = {}
	cache.last_full_scan = os.time()
	cache.refresh_in_flight = false
end

section("13a a refresh answered with the old task does not undo the saved field", function()
	reset_http()
	reset_task_file()
	seed_cache(OLD)
	http.get_tasks = { OLD }
	http.put_task = NEW

	local refreshed = 0
	local au = vim.api.nvim_create_autocmd("User", {
		pattern = "TaskNotesCacheRefreshed",
		callback = function()
			refreshed = refreshed + 1
		end,
	})

	task_ops.apply_patch(TASK_ID, { scheduled = "2026-11-20" })
	drain()
	vim.api.nvim_del_autocmd(au)

	assert_equal(scheduled_in_cache(), "2026-11-20", "the cache holds the saved value")
	assert_true(refreshed >= 1, "the views are told to re-render")
end)

section("13b a refresh in flight before the PUT does not undo the saved field", function()
	reset_http()
	reset_task_file()
	seed_cache(OLD)
	http.get_tasks = { OLD }
	http.defer_get = true

	cache.refresh_async() -- sent before the PUT: answers with OLD
	http.put_task = NEW
	http.get_tasks = { NEW }
	task_ops.apply_patch(TASK_ID, { scheduled = "2026-11-20" })

	for _, answer in ipairs(http.deferred) do
		answer()
	end
	drain()

	assert_equal(scheduled_in_cache(), "2026-11-20", "the late answer does not overwrite the saved value")
end)

section("13c a later change made elsewhere still reaches the cache", function()
	reset_http()
	reset_task_file()
	seed_cache(OLD)
	http.get_tasks = { OLD }
	http.put_task = NEW
	task_ops.apply_patch(TASK_ID, { scheduled = "2026-11-20" })
	drain()

	-- Obsidian changes the task afterwards: newer dateModified.
	local LATER = vim.tbl_extend("force", NEW, { scheduled = "2026-12-01", dateModified = "2026-11-20T09:00:00.000-03:00" })
	http.get_tasks = { LATER }
	cache.refresh_async()
	drain()

	assert_equal(scheduled_in_cache(), "2026-12-01", "the newer server value wins")
end)

section("13d a saved task missing from the server list is forgotten", function()
	reset_http()
	reset_task_file()
	seed_cache(OLD)
	http.get_tasks = { OLD }
	http.put_task = NEW
	-- The refresh that apply_patch starts answers while the server is
	-- still behind, so the saved task stays in the overlay.
	http.defer_get = true
	task_ops.apply_patch(TASK_ID, { scheduled = "2026-11-20" })
	for _, answer in ipairs(http.deferred) do
		answer()
	end
	drain()
	assert_true(cache.pending[ABS] ~= nil, "the saved task waits in the overlay while the server is behind")

	-- The task is renamed or deleted: the list no longer has it.
	http.defer_get = false
	http.get_tasks = {}
	cache.refresh_async()
	drain()
	assert_equal(cache.pending[ABS], nil, "the overlay forgets a task the server no longer lists")

	-- A file shows up again at that path with older data: the stale
	-- saved value is not brought back.
	http.get_tasks = { OLD }
	cache.refresh_async()
	drain()
	assert_equal(scheduled_in_cache(), "2026-11-09", "the server value is shown, not the forgotten save")
end)

-- ──────────────────────────────────────────────────────────────────────
-- Teardown + verdict
-- ──────────────────────────────────────────────────────────────────────
vim.fn.delete(vault, "rf")

if #failures > 0 then
	error(string.format("tasknotes task ops: %d case(s) failed\n  - %s", #failures, table.concat(failures, "\n  - ")))
end

print("tasknotes task ops: ok")
