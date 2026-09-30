-- TaskNotes — in-memory caches.
--   M.data / M.keys_index    — task index, API-sourced, TTL-gated (shortcuts).
--   M.global_data / global_keys_index — whole-vault index, FS-scanned
--                                       (used by <leader>ok drill-down).
--   M.notes                  — whole-vault notes index, FS-scanned, with
--                              the same frontmatter table as global_data
--                              (used by <leader>ot tag browser).
-- Module-level state is a singleton via require's module cache — same semantics
-- as the old single closure.

local config = require("tasknotes.config")
local api = require("tasknotes.api")

local M = {}

-- Task index (API-sourced). Used by the shortcut pickers (<leader>os status,
-- <leader>ow tags) that are documented as "task filters".
M.data = {} -- { [filepath] = { fm = table, mtime = number } }
M.keys_index = {} -- { [key] = { [value] = { filepath, ... } } }
M.last_full_scan = 0

-- Whole-vault index (FS-scanned). Used by <leader>ok drill-down. Includes
-- tasks too — the whole point is the search is global.
M.global_data = {} -- { [filepath] = { fm = table, mtime = number } }
M.global_keys_index = {} -- { [key] = { [value] = { filepath, ... } } }

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

-- Parses the YAML frontmatter of a note, extracting:
--   - `tags` (block list, inline [..], or scalar)
--   - `title` (from `task:` or `title:`)
--   - the full frontmatter as a flat { [key] = scalar_or_list } table, with
--     values normalized via the same parser used for the keys_index
-- Returns nil when the note has no frontmatter.
--
-- The parser is intentionally lightweight: scalar lines `key: value`,
-- block lists under the last `key:` with empty value, and inline `[a, b]`.
-- It is NOT a full YAML implementation — complex constructs (nested maps,
-- multi-line scalars, anchors) are NOT supported. Good enough for the
-- hand-written frontmatter in this vault.
function M.notes.parse(path)
	local fd = io.open(path, "r")
	if not fd then
		return nil
	end

	local in_fm = false
	local tags, title = {}, nil
	local fm = {} -- full frontmatter table
	local current_block_key = nil -- tracks the key whose block list we are inside
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

			-- Are we inside a block list continuation of the previous key?
			if current_block_key then
				local item = line:match("^%s*%-%s*(.+)$")
				if item then
					local t = M.notes.clean(item)
					if t ~= "" then
						if current_block_key == "tags" then
							tags[#tags + 1] = t
						end
						fm[current_block_key] = fm[current_block_key] or {}
						fm[current_block_key][#fm[current_block_key] + 1] = t
					end
					handled = true
				else
					current_block_key = nil
				end
			end

			if not handled then
				local k, v = line:match("^([%w_]+):%s*(.*)$")
				if k then
					if k == "tags" then
						if v == "" then
							current_block_key = "tags"
							fm.tags = fm.tags or {}
						else
							local inner = v:match("^%[(.*)%]$")
							if inner then
								fm.tags = {}
								for t in inner:gmatch("[^,]+") do
									t = M.notes.clean(t)
									if t ~= "" then
										tags[#tags + 1] = t
										fm.tags[#fm.tags + 1] = t
									end
								end
							else
								local t = M.notes.clean(v)
								if t ~= "" then
									tags[#tags + 1] = t
									fm.tags = t
								end
							end
						end
					elseif (k == "task" or k == "title") and not title then
						local t = M.notes.clean(v)
						if t ~= "" then
							title = t
						end
					else
						-- Generic key: scalar, inline list, or start of block list.
						if v == "" then
							current_block_key = k
							fm[k] = fm[k] or {}
						else
							current_block_key = nil
							local inner = v:match("^%[(.*)%]$")
							if inner then
								fm[k] = {}
								for t in inner:gmatch("[^,]+") do
									t = M.notes.clean(t)
									if t ~= "" then
										fm[k][#fm[k] + 1] = t
									end
								end
							else
								local t = M.notes.clean(v)
								fm[k] = (t ~= "") and t or nil
							end
						end
					end
				end
			end
		end
	end

	fd:close()

	-- A note without any frontmatter content is not indexable.
	if next(fm) == nil then
		return nil
	end

	title = title or vim.fn.fnamemodify(path, ":t:r")
	local display = (#tags > 0)
		and string.format("%s  #%s", title, table.concat(tags, " #"))
		or title
	return {
		path = path,
		title = title,
		tags = tags,
		fm = fm,
		display = display,
	}
end

-- Builds M.notes asynchronously (chunked). on_done() fires when ready.
-- Also populates M.global_data / M.global_keys_index — the whole-vault
-- frontmatter index used by the <leader>ok drill-down. Both views share
-- the same per-file parse (a single io.open + scan).
function M.notes.build(on_done)
	if M.notes.building then
		return
	end
	M.notes.building = true

	local files = vim.fs.find(function(name, dir)
		return name:match("%.md$") and not dir:find("/.obsidian", 1, true) and not dir:find("/Templates", 1, true)
	end, { path = config.vault_path, type = "file", limit = math.huge })

	local entries = {}
	local global_data = {}
	local global_keys_index = {}
	local i = 1
	local CHUNK = 80

	-- Inserts a parsed frontmatter key into the global inverted index.
	-- Mirrors the loop body of M.ensure (line ~37-55) so behaviour is
	-- identical: scalar values become single-element lists, list values
	-- iterate. Empty strings are skipped.
	local function index_fm(filepath, fm)
		for key, value in pairs(fm) do
			if not global_keys_index[key] then
				global_keys_index[key] = {}
			end
			local values = type(value) == "table" and value or { tostring(value) }
			for _, v in ipairs(values) do
				v = tostring(v)
				if v ~= "" then
					if not global_keys_index[key][v] then
						global_keys_index[key][v] = {}
					end
					table.insert(global_keys_index[key][v], filepath)
				end
			end
		end
	end

	local function step()
		local stop = math.min(i + CHUNK - 1, #files)
		for j = i, stop do
			local e = M.notes.parse(files[j])
			if e then
				entries[#entries + 1] = e
				global_data[e.path] = { fm = e.fm, mtime = 0 }
				index_fm(e.path, e.fm)
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
			M.global_data = global_data
			M.global_keys_index = global_keys_index
			if on_done then
				on_done()
			end
		end
	end

	step()
end

-- Forces a complete cache rebuild regardless of TTL.
-- Invalidates BOTH the local task index (used by <leader>os / <leader>ow
-- shortcuts) AND the API caches (filter-options + task paths) AND the
-- whole-vault notes index (used by <leader>ok drill-down and <leader>ot).
function M.force_refresh()
	M.data = {}
	M.keys_index = {}
	M.global_data = {}
	M.global_keys_index = {}
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
