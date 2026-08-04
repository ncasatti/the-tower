-- TaskNotes — Pomodoro & time-tracking panel (<leader>op).
--
-- A single state-aware Snacks picker. The title reflects live pomodoro
-- state; the item list mutates with state. State machine empirically
-- verified against GET /api/pomodoro/status:
--   idle    = no currentSession (isRunning=false)
--   running = currentSession present + isRunning=true
--   paused  = currentSession present + isRunning=false
-- Phase = currentSession.type ("work" | "short-break" | "long-break");
-- timeRemaining is seconds. Breaks are server-auto-managed, so we never
-- start a break manually — Start is only offered for a task buffer.

local config = require("tasknotes.config")
local api = require("tasknotes.api")
local util = require("tasknotes.util")

local M = {}

M.phase_label = {
	work = "Focus",
	["short-break"] = "Short break",
	["long-break"] = "Long break",
}

-- seconds -> "m:ss"
function M.fmt_mmss(secs)
	secs = tonumber(secs) or 0
	if secs < 0 then
		secs = 0
	end
	return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

-- minutes -> "Hh Mm" / "Mm"
function M.fmt_minutes(mins)
	mins = math.floor(tonumber(mins) or 0)
	local h = math.floor(mins / 60)
	local m = mins % 60
	if h > 0 then
		return string.format("%dh %dm", h, m)
	end
	return string.format("%dm", m)
end

-- Resolves the buffer's task id without notifying (panel is also usable
-- from non-task buffers for the read-only views).
function M.buffer_task_id()
	local id = util.buffer_to_id()
	if not id then
		return nil
	end
	local paths = api.get_task_paths()
	if paths and paths[id] then
		return id
	end
	return nil
end

-- GET /api/pomodoro/status -> { state, phase, data } or nil
function M.status()
	local res = api.get("/pomodoro/status")
	if not (res and res.success) then
		return nil
	end
	local d = res.data or {}
	local state, phase
	if d.currentSession then
		state = d.isRunning and "running" or "paused"
		phase = d.currentSession.type or "work"
	else
		state = "idle"
	end
	return { state = state, phase = phase, data = d }
end

function M.panel()
	local st = M.status()
	if not st then
		vim.notify("Could not fetch pomodoro status", vim.log.levels.ERROR)
		return
	end
	local task_id = M.buffer_task_id()
	local d = st.data

	local title
	if st.state == "idle" then
		title = "Pomodoro — idle"
	else
		title = string.format(
			"Pomodoro — %s %s (%s)",
			M.phase_label[st.phase] or st.phase,
			M.fmt_mmss(d.timeRemaining),
			st.state
		)
	end

	local items = {}

	-- Pomodoro controls (state-dependent).
	if st.state == "idle" then
		if task_id then
			table.insert(items, { text = "Start focus on buffer task", action = "pomo_start" })
		else
			table.insert(items, { text = "Start focus  (open a task buffer first)", action = "noop" })
		end
	elseif st.state == "running" then
		table.insert(items, { text = "Pause", action = "pomo_pause" })
		table.insert(items, { text = "Stop pomodoro", action = "pomo_stop" })
	elseif st.state == "paused" then
		table.insert(items, { text = "Resume", action = "pomo_resume" })
		table.insert(items, { text = "Stop pomodoro", action = "pomo_stop" })
	end

	table.insert(
		items,
		{ text = "─────────────────────────", action = "noop" }
	)

	-- Time tracking (buffer task only).
	if task_id then
		table.insert(items, { text = "Start time tracking", action = "time_start" })
		table.insert(items, { text = "Start time tracking (description)…", action = "time_start_desc" })
		table.insert(items, { text = "Stop time tracking", action = "time_stop" })
	else
		table.insert(items, { text = "Time tracking  (open a task buffer first)", action = "noop" })
	end

	table.insert(
		items,
		{ text = "─────────────────────────", action = "noop" }
	)

	-- Read-only views.
	table.insert(items, { text = "Pomodoro stats", action = "view_stats" })
	table.insert(items, { text = "Time summary (today)", action = "view_summary" })
	table.insert(items, { text = "Active sessions…", action = "view_active" })

	Snacks.picker.pick({
		source = "tasknotes_pomodoro",
		title = title,
		items = items,
		format = "text",
		preview = "none",
		layout = { hidden = { "preview" } },
		confirm = function(picker, item)
			picker:close()
			if not item or item.action == "noop" then
				vim.schedule(function()
					M.panel()
				end)
				return
			end
			vim.schedule(function()
				M.dispatch(item.action, task_id)
			end)
		end,
	})
end

-- Reloads the on-disk task file into its buffer after a server-side write
-- (time tracking mutates `timeEntries` in the frontmatter). SAFE: if the
-- buffer has unsaved changes it is NOT clobbered — we warn instead. The
-- workflow assumes you saved before starting (User-confirmed protocol).
function M.reload_task_buffer(task_id)
	if not task_id then
		return
	end
	local target = vim.fn.fnamemodify(config.vault_path .. "/" .. task_id, ":p")
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":p") == target then
			if vim.bo[buf].modified then
				vim.notify(
					string.format(
						"TaskNotes: %s changed on disk (time tracking) but the buffer has unsaved changes — not reloading. Save (:w), then :e to sync.",
						vim.fn.fnamemodify(target, ":t")
					),
					vim.log.levels.WARN
				)
			else
				vim.api.nvim_buf_call(buf, function()
					vim.cmd("silent! edit")
				end)
			end
			return
		end
	end
end

function M.dispatch(action, task_id)
	local function enc()
		return api._encode_id(task_id)
	end
	if action == "pomo_start" then
		if not task_id then
			return
		end
		local body = { taskId = task_id }
		if config.pomodoro_minutes then
			body.duration = config.pomodoro_minutes
		end
		local res = api.post("/pomodoro/start", body)
		if res and res.success then
			vim.notify("Pomodoro started", vim.log.levels.INFO)
		end
		M.panel()
	elseif action == "pomo_pause" then
		local res = api.post("/pomodoro/pause", {})
		if res and res.success then
			vim.notify("Pomodoro paused", vim.log.levels.INFO)
		end
		M.panel()
	elseif action == "pomo_resume" then
		local res = api.post("/pomodoro/resume", {})
		if res and res.success then
			vim.notify("Pomodoro resumed", vim.log.levels.INFO)
		end
		M.panel()
	elseif action == "pomo_stop" then
		local res = api.post("/pomodoro/stop", {})
		if res and res.success then
			vim.notify("Pomodoro stopped", vim.log.levels.INFO)
		end
		M.panel()
	elseif action == "time_start" then
		if not task_id then
			return
		end
		local res = api.post("/tasks/" .. enc() .. "/time/start", {})
		if res and res.success then
			vim.notify("Time tracking started", vim.log.levels.INFO)
			M.reload_task_buffer(task_id)
		end
		M.panel()
	elseif action == "time_start_desc" then
		if not task_id then
			return
		end
		vim.ui.input({ prompt = "Description: " }, function(input)
			-- nil = Esc → re-open panel, no mutation.
			if input == nil then
				M.panel()
				return
			end
			local res = api.post("/tasks/" .. enc() .. "/time/start-with-description", { description = input })
			if res and res.success then
				vim.notify("Time tracking started", vim.log.levels.INFO)
				M.reload_task_buffer(task_id)
			end
			M.panel()
		end)
	elseif action == "time_stop" then
		if not task_id then
			return
		end
		local res = api.post("/tasks/" .. enc() .. "/time/stop", {})
		if res and res.success then
			vim.notify("Time tracking stopped", vim.log.levels.INFO)
			M.reload_task_buffer(task_id)
		end
		M.panel()
	elseif action == "view_stats" then
		M.show_stats()
	elseif action == "view_summary" then
		M.show_summary()
	elseif action == "view_active" then
		M.show_active()
	end
end

function M.show_stats()
	local res = api.get("/pomodoro/stats")
	if not (res and res.success) then
		vim.notify("Could not fetch pomodoro stats", vim.log.levels.ERROR)
		return
	end
	local s = res.data or {}
	local msg = string.format(
		"Pomodoro stats (today)\n  Completed:   %s\n  Streak:      %s\n  Total time:  %s\n  Avg length:  %s min\n  Completion:  %s%%",
		tostring(s.pomodorosCompleted or 0),
		tostring(s.currentStreak or 0),
		M.fmt_minutes(s.totalMinutes or 0),
		tostring(s.averageSessionLength or 0),
		tostring(s.completionRate or 0)
	)
	vim.notify(msg, vim.log.levels.INFO)
end

function M.show_summary()
	local res = api.get("/time/summary", { period = "today" })
	if not (res and res.success) then
		vim.notify("Could not fetch time summary", vim.log.levels.ERROR)
		return
	end
	local d = res.data or {}
	local sm = d.summary or {}
	local lines = {
		"Time summary (today)",
		string.format("  Total:   %s", M.fmt_minutes(sm.totalMinutes or 0)),
		string.format(
			"  Tasks:   %s (active %s, done %s)",
			tostring(sm.tasksWithTime or 0),
			tostring(sm.activeTasks or 0),
			tostring(sm.completedTasks or 0)
		),
	}
	local top = d.topTasks or {}
	if #top > 0 then
		table.insert(lines, "  Top tasks:")
		for i = 1, math.min(5, #top) do
			local t = top[i]
			table.insert(
				lines,
				string.format("    • %s — %s", t.title or t.task or "?", M.fmt_minutes(t.minutes or 0))
			)
		end
	end
	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

function M.show_active()
	local res = api.get("/time/active")
	if not (res and res.success) then
		vim.notify("Could not fetch active sessions", vim.log.levels.ERROR)
		return
	end
	local sessions = (res.data and res.data.activeSessions) or {}
	if #sessions == 0 then
		vim.notify("No active time-tracking sessions", vim.log.levels.INFO)
		vim.schedule(function()
			M.panel()
		end)
		return
	end
	local items = {}
	for _, s in ipairs(sessions) do
		local task = s.task or {}
		local mins = s.elapsedMinutes or (s.session and s.session.elapsedMinutes)
		table.insert(items, {
			text = string.format(
				"%s%s",
				task.title or task.id or "?",
				mins and string.format("  (%s)", M.fmt_minutes(mins)) or ""
			),
			task_id = task.id,
		})
	end
	Snacks.picker.pick({
		source = "tasknotes_active_sessions",
		title = string.format("Active sessions (%d)", #sessions),
		items = items,
		format = "text",
		preview = "none",
		layout = { hidden = { "preview" } },
		confirm = function(picker, item)
			picker:close()
			if item and item.task_id then
				vim.schedule(function()
					vim.cmd("edit " .. vim.fn.fnameescape(config.vault_path .. "/" .. item.task_id))
				end)
			else
				vim.schedule(function()
					M.panel()
				end)
			end
		end,
	})
end

return M
