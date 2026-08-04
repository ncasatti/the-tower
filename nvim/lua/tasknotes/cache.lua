-- TaskNotes — in-memory caches.
--   M.data / M.keys_index — task index, API-sourced, TTL-gated (drill-down).
--   M.notes               — whole-vault notes index, FS-scanned (ow tag browser).
-- Module-level state is a singleton via require's module cache — same semantics
-- as the old single closure.

local config = require("tasknotes.config")
local api = require("tasknotes.api")

local M = {}

-- Task index (API-sourced).
M.data = {} -- { [filepath] = { fm = table, mtime = number } }
M.keys_index = {} -- { [key] = { [value] = { filepath, ... } } }
M.last_full_scan = 0

-- Ensures the task index is fresh by fetching from the API.
function M.ensure()
	local now = os.time()
	if now - M.last_full_scan < config.cache_ttl then
		return
	end

	local t_start = vim.fn.reltime()

	local all_tasks = api.query_tasks(nil) or {}
	local index = {}
	local cache_data = {}

	for _, task in ipairs(all_tasks) do
		-- The API returns metadata flattened in the task object
		local fm = task
		-- Normalize to absolute path
		local filepath = config.vault_path .. "/" .. task.path
		cache_data[filepath] = { fm = fm, mtime = 0 }

		for key, value in pairs(fm) do
			-- Skip non-metadata fields to keep the index clean
			if key ~= "path" and key ~= "id" and key ~= "title" then
				if not index[key] then
					index[key] = {}
				end

				local values = type(value) == "table" and value or { tostring(value) }
				for _, v in ipairs(values) do
					v = tostring(v)
					if v ~= "" then
						if not index[key][v] then
							index[key][v] = {}
						end
						table.insert(index[key][v], filepath)
					end
				end
			end
		end
	end

	M.data = cache_data
	M.keys_index = index
	M.last_full_scan = now

	local elapsed = vim.fn.reltimestr(vim.fn.reltime(t_start))
	vim.notify(
		string.format("TaskNotes: cache refreshed from API (%d files, %ss)", #all_tasks, elapsed),
		vim.log.levels.DEBUG
	)
end

-- Invalidates the cache entry for a single file (after write operations).
function M.invalidate_file(filepath)
	M.data[filepath] = nil
	-- Force index rebuild on next invocation
	M.last_full_scan = 0
end

-- ──────────────────────────────────────────────────────────────────────
-- Whole-vault notes cache (for <leader>ow note-by-tag search).
-- Distinct from the task index (API-sourced). Scans the filesystem for
-- frontmatter `tags`; built lazily on first ow and rebuilt on or.
-- Async/chunked across event-loop ticks to avoid freezing on ~750 notes.
-- ──────────────────────────────────────────────────────────────────────
M.notes = {
	entries = {}, -- { { idx, path, title, tags = {..}, display } }
	built = false,
	building = false,
}

-- Strips surrounding whitespace and quotes from a YAML scalar token.
function M.notes.clean(s)
	s = (s:gsub("^%s+", ""):gsub("%s+$", ""))
	s = (s:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1"))
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Parses ONLY the YAML frontmatter of a note, extracting `tags` (block
-- list, inline [..], or scalar) plus a display title. Returns nil when the
-- note has no frontmatter or no tags.
function M.notes.parse(path)
	local fd = io.open(path, "r")
	if not fd then
		return nil
	end

	local in_fm, in_tags = false, false
	local tags, title = {}, nil
	local lineno = 0

	for line in fd:lines() do
		lineno = lineno + 1
		if lineno == 1 and line ~= "---" then
			break
		end

		if line == "---" then
			if in_fm then
				break
			end
			in_fm = true
		elseif in_fm then
			local handled = false
			if in_tags then
				local item = line:match("^%s*%-%s*(.+)$")
				if item then
					local t = M.notes.clean(item)
					if t ~= "" then
						tags[#tags + 1] = t
					end
					handled = true
				else
					in_tags = false
				end
			end

			if not handled then
				local k, v = line:match("^([%w_]+):%s*(.*)$")
				if k == "tags" then
					if v == "" then
						in_tags = true
					else
						local inner = v:match("^%[(.*)%]$")
						if inner then
							for t in inner:gmatch("[^,]+") do
								t = M.notes.clean(t)
								if t ~= "" then
									tags[#tags + 1] = t
								end
							end
						else
							local t = M.notes.clean(v)
							if t ~= "" then
								tags[#tags + 1] = t
							end
						end
					end
				elseif (k == "task" or k == "title") and not title then
					local t = M.notes.clean(v)
					if t ~= "" then
						title = t
					end
				end
			end
		end
	end

	fd:close()

	if #tags == 0 then
		return nil
	end

	title = title or vim.fn.fnamemodify(path, ":t:r")
	return {
		path = path,
		title = title,
		tags = tags,
		display = string.format("%s  #%s", title, table.concat(tags, " #")),
	}
end

-- Builds M.notes asynchronously (chunked). on_done() fires when ready.
function M.notes.build(on_done)
	if M.notes.building then
		return
	end
	M.notes.building = true

	local files = vim.fs.find(function(name, dir)
		return name:match("%.md$") and not dir:find("/.obsidian", 1, true) and not dir:find("/Templates", 1, true)
	end, { path = config.vault_path, type = "file", limit = math.huge })

	local entries = {}
	local i = 1
	local CHUNK = 80

	local function step()
		local stop = math.min(i + CHUNK - 1, #files)
		for j = i, stop do
			local e = M.notes.parse(files[j])
			if e then
				entries[#entries + 1] = e
			end
		end
		i = stop + 1
		if i <= #files then
			vim.schedule(step)
		else
			table.sort(entries, function(a, b)
				return a.title:lower() < b.title:lower()
			end)
			for idx, e in ipairs(entries) do
				e.idx = idx
			end
			M.notes.entries = entries
			M.notes.built = true
			M.notes.building = false
			if on_done then
				on_done()
			end
		end
	end

	step()
end

-- Forces a complete cache rebuild regardless of TTL.
-- Invalidates BOTH the local task index (used by <leader>ok drill-down)
-- AND the API caches (filter-options + task paths) AND the notes index (ow).
function M.force_refresh()
	M.data = {}
	M.keys_index = {}
	M.last_full_scan = 0
	M.ensure()
	api.invalidate_caches()
	M.notes.built = false
	M.notes.build(function()
		vim.notify(
			string.format("TaskNotes: vault notes index rebuilt (%d notes)", #M.notes.entries),
			vim.log.levels.INFO
		)
	end)
	vim.notify("TaskNotes: local + API caches refreshed", vim.log.levels.INFO)
end

return M
