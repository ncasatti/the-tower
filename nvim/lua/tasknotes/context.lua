-- TaskNotes — task context builder (deep module).
--
-- Turns a buffer path + the in-memory task cache + the live buffer lines
-- into a Context object the views (inline card, side panel) render from.
--
-- Deliberately dependency-free: `tasknotes.config` only. It never requires
-- the HTTP client, the task writer or plenary, so a view can build a
-- context without touching the network (ADR-005) and without pulling in
-- the write path.
--
-- Context = {
--   task       = <API task record>,
--   path       = <absolute path>,
--   parents    = { Ref... },   -- from task.projects
--   subtasks   = { Ref... },   -- tasks whose projects resolve to this note
--   blocked_by = { Ref... },   -- from task.blockedBy
--   blocking   = { Ref... },   -- from task.blocking
--   progress   = { done = n, total = n },            -- over subtasks
--   checklist  = { done = n, doing = n, open = n },  -- body only
--   time       = { tracked_min = n, estimate_min = n|nil },
--   fm_end_row = n|nil,        -- 0-based row of the closing `---`
-- }
--
-- Ref = {
--   name, path|nil, status|nil, priority|nil, scheduled|nil, due|nil,
--   is_task = bool,
-- }

local config = require("tasknotes.config")

local M = {}

-- ──────────────────────────────────────────────────────────────────────
-- Link normalization
--
-- Observed shapes in the live vault:
--   [[Name]]  [[Name|Alias]]  [[folder/Name]]  "[[Name]]"  [[Name#Heading]]
-- Normalization strips quotes, brackets, alias, heading, folder prefix
-- and the .md extension, leaving the bare basename.
-- ──────────────────────────────────────────────────────────────────────
local function normalize_link(raw)
	if type(raw) ~= "string" then
		return nil
	end

	local s = vim.trim(raw)

	-- Surrounding quotes (single or double).
	s = s:gsub('^"(.*)"$', "%1")
	s = s:gsub("^'(.*)'$", "%1")
	s = vim.trim(s)

	-- Wiki brackets.
	s = s:gsub("^%[%[", "")
	s = s:gsub("%]%]$", "")
	s = vim.trim(s)

	-- Alias after `|`, then heading after `#`.
	s = s:match("^([^|]*)") or s
	s = s:match("^([^#]*)") or s
	s = vim.trim(s)

	-- Folder prefix.
	s = s:match("([^/]+)$") or s

	-- `.md` extension.
	s = s:gsub("%.md$", "")

	if s == "" then
		return nil
	end
	return s
end

-- Basename (filename without extension) of a task path.
local function basename_of(path)
	if type(path) ~= "string" then
		return nil
	end
	local base = path:match("([^/]+)$") or path
	base = base:gsub("%.md$", "")
	return base
end

-- ──────────────────────────────────────────────────────────────────────
-- Indexes over the task cache
--
--   by_basename — basename -> { path, record } (first match wins, in
--                  sorted-path order so the result is deterministic)
--   by_project  — normalized project basename -> { { path, record }... }
--
-- Memoized per cache generation: the cache swaps the whole table on every
-- refresh, so a generation bump invalidates the indexes.
-- ──────────────────────────────────────────────────────────────────────
local memo = nil

local function build_indexes(tasks)
	local by_basename = {}
	local by_project = {}

	local paths = {}
	for abs_path in pairs(tasks) do
		paths[#paths + 1] = abs_path
	end
	table.sort(paths)

	for _, abs_path in ipairs(paths) do
		local entry = tasks[abs_path]
		local record = entry.fm or entry
		if type(record) == "table" then
			local base = basename_of(record.path or abs_path)
			if base and base ~= "" and by_basename[base] == nil then
				by_basename[base] = { path = abs_path, record = record }
			end

			local projects = record.projects
			if type(projects) == "string" then
				projects = { projects }
			end
			if type(projects) == "table" then
				local seen = {}
				for _, link in ipairs(projects) do
					local target = normalize_link(link)
					if target and not seen[target] then
						seen[target] = true
						by_project[target] = by_project[target] or {}
						table.insert(by_project[target], { path = abs_path, record = record })
					end
				end
			end
		end
	end

	return by_basename, by_project
end

local function indexes_for(tasks, generation)
	if generation ~= nil and memo and memo.generation == generation and rawequal(memo.tasks, tasks) then
		return memo.by_basename, memo.by_project
	end

	local by_basename, by_project = build_indexes(tasks)

	if generation ~= nil then
		memo = {
			generation = generation,
			tasks = tasks,
			by_basename = by_basename,
			by_project = by_project,
		}
	end

	return by_basename, by_project
end

-- ──────────────────────────────────────────────────────────────────────
-- Refs
-- ──────────────────────────────────────────────────────────────────────
local function task_ref(name, path, record)
	return {
		name = name,
		path = path,
		status = record.status,
		priority = record.priority,
		scheduled = record.scheduled,
		due = record.due,
		is_task = true,
	}
end

-- Resolves a project link to a Ref. Links that point at a note which is
-- not a task resolve to a Ref with is_task = false and no status.
local function resolve_parent(link, by_basename)
	local name = normalize_link(link)
	if not name then
		return nil
	end

	local hit = by_basename[name]
	if hit then
		return task_ref(name, hit.path, hit.record)
	end

	return {
		name = name,
		path = nil,
		status = nil,
		priority = nil,
		scheduled = nil,
		due = nil,
		is_task = false,
	}
end

-- ──────────────────────────────────────────────────────────────────────
-- Dependencies
--
-- Two shapes, both observed live:
--
--   blockedBy = { { uid = "Hacer rutina de entrenamiento",
--                   reltype = "FINISHTOSTART" } }
--   blocking  = { "TaskNotes/Tasks/Empezar el gimnasio.md" }
--
-- The uid form carries a basename (sometimes a wikilink, sometimes a
-- path); the path form carries a vault-relative path. Both are
-- normalized to a basename and looked up in the basename index. A
-- dependency that is not in the cache resolves to a Ref with
-- is_task = false — the panel still shows the name, it just cannot
-- navigate to it.
-- ──────────────────────────────────────────────────────────────────────
local function resolve_dependency(raw, by_basename, tasks)
	-- The blockedBy form wraps the target in an object.
	local link = raw
	if type(raw) == "table" then
		link = raw.uid or raw.path or raw.id
	end
	if type(link) ~= "string" then
		return nil
	end

	local name = normalize_link(link)
	if not name then
		return nil
	end

	-- A vault-relative path can be resolved exactly, which avoids the
	-- basename ambiguity of two same-named notes in different folders.
	if link:find("/", 1, true) then
		local abs = config.vault_path .. "/" .. link:gsub("^/", "")
		local entry = tasks[abs]
		if entry then
			local record = entry.fm or entry
			if type(record) == "table" then
				return task_ref(name, abs, record)
			end
		end
	end

	local hit = by_basename[name]
	if hit then
		return task_ref(name, hit.path, hit.record)
	end

	return {
		name = name,
		path = nil,
		status = nil,
		priority = nil,
		scheduled = nil,
		due = nil,
		is_task = false,
	}
end

-- Resolves a list of dependency entries to Refs.
local function resolve_dependencies(list, by_basename, tasks)
	local refs = {}
	if type(list) ~= "table" then
		return refs
	end
	for _, raw in ipairs(list) do
		local ref = resolve_dependency(raw, by_basename, tasks)
		if ref then
			refs[#refs + 1] = ref
		end
	end
	return refs
end

-- ──────────────────────────────────────────────────────────────────────
-- Checklist parsing (body only — everything after the frontmatter fence)
-- ──────────────────────────────────────────────────────────────────────
local function count_checklist(lines, fm_end_row)
	local counts = { done = 0, doing = 0, open = 0 }
	if not lines then
		return counts
	end

	-- Row 0 is line 1; the frontmatter ends at `fm_end_row`. Without
	-- frontmatter the whole buffer is body.
	local first = fm_end_row and (fm_end_row + 1) or 0

	for row = first, #lines - 1 do
		local line = lines[row + 1]
		if type(line) == "string" then
			-- Strip indentation and callout markers (`> `, `>`).
			local body = line:gsub("^%s+", "")
			while true do
				local stripped = body:gsub("^>%s?", "")
				if stripped == body then
					break
				end
				body = stripped:gsub("^%s+", "")
			end

			local marker = body:match("^%-%s*%[(.)%]")
			if marker == " " then
				counts.open = counts.open + 1
			elseif marker == "x" or marker == "X" then
				counts.done = counts.done + 1
			elseif marker == "-" or marker == "~" then
				counts.doing = counts.doing + 1
			end
		end
	end

	return counts
end

-- ──────────────────────────────────────────────────────────────────────
-- Frontmatter fence
--
-- The frontmatter starts at line 1 with `---` and ends at the next `---`.
-- fm_end_row is the 0-based row of that closing fence, or nil when the
-- buffer has no frontmatter (nothing to anchor a card on).
--
-- When the user inserts lines above the frontmatter the fence is no
-- longer at line 1; the first `---` pair is then used instead, so the
-- card keeps following the fence while the note is edited.
-- ──────────────────────────────────────────────────────────────────────
local function find_fm_end_row(lines)
	if not lines or #lines == 0 then
		return nil
	end

	-- Opening fence: line 1 in the normal case, the first `---` line
	-- otherwise (displaced frontmatter).
	local open = nil
	for row = 0, #lines - 1 do
		if vim.trim(lines[row + 1]) == "---" then
			open = row
			break
		end
	end
	if open == nil then
		return nil
	end

	-- Closing fence: the next `---` line after the opening one.
	for row = open + 1, #lines - 1 do
		if vim.trim(lines[row + 1]) == "---" then
			return row
		end
	end
	return nil
end

-- ──────────────────────────────────────────────────────────────────────
-- Public API
--
-- context.build(abs_path, { tasks, lines, completed, generation }) -> Context|nil
--
--   tasks       — the task cache shape: { [abs_path] = { fm = record } }
--   lines       — the buffer lines (1-based array); optional
--   completed   — set of status values counted as done; optional
--   generation  — cache generation, used to memoize the indexes; optional
--   status_ranks — status value → rank, used to order the subtasks;
--                  optional (without it the subtasks are ordered by title)
-- ──────────────────────────────────────────────────────────────────────
function M.build(abs_path, opts)
	opts = opts or {}
	local tasks = opts.tasks or {}
	if type(abs_path) ~= "string" or abs_path == "" then
		return nil
	end

	local entry = tasks[abs_path]
	if not entry then
		return nil
	end
	local record = entry.fm or entry
	if type(record) ~= "table" then
		return nil
	end

	local by_basename, by_project = indexes_for(tasks, opts.generation)

	-- Parents: the projects this task declares.
	local parents = {}
	local projects = record.projects
	if type(projects) == "string" then
		projects = { projects }
	end
	if type(projects) == "table" then
		local seen = {}
		for _, link in ipairs(projects) do
			local ref = resolve_parent(link, by_basename)
			if ref and not seen[ref.name] then
				seen[ref.name] = true
				parents[#parents + 1] = ref
			end
		end
	end

	-- Subtasks: tasks whose projects resolve to this note's basename.
	-- Ordered by status rank then scheduled date when ranks are known,
	-- otherwise by title — always deterministic.
	local subtasks = {}
	local self_base = basename_of(record.path or abs_path)
	if self_base then
		for _, candidate in ipairs(by_project[self_base] or {}) do
			if candidate.path ~= abs_path then
				local name = candidate.record.title or basename_of(candidate.record.path or candidate.path)
				subtasks[#subtasks + 1] = task_ref(name, candidate.path, candidate.record)
			end
		end
	end

	local ranks = opts.status_ranks
	if type(ranks) == "table" and next(ranks) ~= nil then
		table.sort(subtasks, function(a, b)
			local ra = ranks[a.status]
			local rb = ranks[b.status]
			if ra ~= rb then
				-- Unranked statuses sort last.
				if ra == nil then
					return false
				end
				if rb == nil then
					return true
				end
				return ra < rb
			end
			local sa = a.scheduled or ""
			local sb = b.scheduled or ""
			if sa ~= sb then
				return sa < sb
			end
			return (a.name or "") < (b.name or "")
		end)
	else
		table.sort(subtasks, function(a, b)
			return (a.name or "") < (b.name or "")
		end)
	end

	-- Progress over the subtasks.
	local completed = opts.completed
	if type(completed) ~= "table" then
		completed = config.completed_statuses or {}
	end
	local done = 0
	for _, sub in ipairs(subtasks) do
		if sub.status and completed[sub.status] then
			done = done + 1
		end
	end

	local lines = opts.lines
	local fm_end_row = find_fm_end_row(lines)

	-- Dependencies: the tasks this one waits on, and the ones it blocks.
	local blocked_by = resolve_dependencies(record.blockedBy, by_basename, tasks)
	local blocking = resolve_dependencies(record.blocking, by_basename, tasks)

	-- Time: minutes already tracked, and the optional estimate.
	local tracked = tonumber(record.totalTrackedTime) or 0
	local estimate = tonumber(record.timeEstimate)

	return {
		task = record,
		path = abs_path,
		parents = parents,
		subtasks = subtasks,
		blocked_by = blocked_by,
		blocking = blocking,
		progress = { done = done, total = #subtasks },
		checklist = count_checklist(lines, fm_end_row),
		time = { tracked_min = tracked, estimate_min = estimate },
		fm_end_row = fm_end_row,
	}
end

return M
