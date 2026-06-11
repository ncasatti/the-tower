-- TaskNotes v2 — Multi-stage Snacks.picker search + task management
-- Provides frontmatter-indexed search across the entire Zettelkasten vault
-- and preserves all legacy task management operations.
--
-- Architecture:
--   M.config         — Configuration table
--   M.cache          — In-memory frontmatter cache with TTL + mtime invalidation
--   parse_frontmatter() — YAML state-machine parser
--   scan_vault()     — Full/incremental vault scan
--   build_index()    — Inverted index: key → value → [filepaths]
--   ensure_cache()   — TTL-gated cache refresh
--   M.picker.*       — 3-stage Snacks pickers (Key → Value → File)
--   M.task_ops.*     — Task CRUD: create_task + edit_fields (multi-field PUT)
--   M.query_builder.* — Interactive field-selector query builder
--   M.find_tasks()   — Snacks picker over API-queried tasks
--   Keybindings      — <leader>ow* (search + task management)

return {
	dir = vim.fn.stdpath("config") .. "/lua/plugins/writing",
	name = "tasknotes",
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"folke/snacks.nvim",
	},

	config = function()
		-- ─────────────────────────────────────────────────────────────────
		-- MODULE TABLE
		-- ─────────────────────────────────────────────────────────────────
		local M = {}

		-- ─────────────────────────────────────────────────────────────────
		-- STEP 2: Configuration table
		-- ─────────────────────────────────────────────────────────────────
		M.config = {
			vault_path = vim.fn.expand("~/.the-grid/zettelkasten"),
			tasks_folder = "TaskNotes/Tasks",
			api_url = "http://localhost:8080/api",
			cache_ttl = 30, -- seconds, applies to local frontmatter cache only
			-- Defaults for NLP-driven create_task when parser doesn't provide them.
			-- Live statuses/priorities are pulled from /api/filter-options.
			default_status = "inbox",
			default_priority = "normal",
		}

		-- ─────────────────────────────────────────────────────────────────
		-- API HELPER
		-- ─────────────────────────────────────────────────────────────────
		M.api = {}

		-- URL-encodes a path-as-id (vault-relative path with slashes and unicode).
		-- The API uses the relative path as the resource id and expects it
		-- percent-encoded (including the forward slashes between segments).
		function M.api._encode_id(path)
			return (path:gsub("([^%w%-%._~])", function(c)
				return string.format("%%%02X", string.byte(c))
			end))
		end

		function M.api.request(method, endpoint, params)
			local curl = require("plenary.curl")
			local url = M.config.api_url .. endpoint
			-- See M.api.health for rationale: `on_error` prevents plenary from
			-- raising error() from its libuv callback when curl exit code != 0.
			local options = {
				headers = {
					content_type = "application/json",
				},
				on_error = function() end,
			}

			local fn
			if method == "POST" then
				options.body = vim.fn.json_encode(params or {})
				fn = curl.post
			elseif method == "PUT" then
				options.body = vim.fn.json_encode(params or {})
				fn = curl.put
			elseif method == "DELETE" then
				fn = curl.delete
			else -- GET
				options.query = params
				fn = curl.get
			end

			local ok, res = pcall(fn, url, options)
			if not ok or not res or res.status ~= 200 or not res.body or res.body == "" then
				local code = (ok and res and res.status) or "no-response"
				vim.notify(
					string.format("TaskNotes API error (%s %s): %s", method, endpoint, tostring(code)),
					vim.log.levels.ERROR
				)
				return nil
			end
			local decoded_ok, decoded = pcall(vim.fn.json_decode, res.body)
			if not decoded_ok then
				vim.notify(
					string.format("TaskNotes API decode error (%s %s)", method, endpoint),
					vim.log.levels.ERROR
				)
				return nil
			end
			return decoded
		end

		function M.api.post(endpoint, body)
			return M.api.request("POST", endpoint, body)
		end

		function M.api.put(endpoint, body)
			return M.api.request("PUT", endpoint, body)
		end

		function M.api.get(endpoint, params)
			return M.api.request("GET", endpoint, params)
		end

		-- Health probe used at boot.
		-- @return boolean true if /api/health responded with success
		function M.api.health()
			local curl = require("plenary.curl")
			-- plenary's curl raises `error()` from its libuv on_exit callback when
			-- exit code != 0. That error escapes a wrapping pcall (different stack)
			-- and surfaces as "Lua callback" noise. Passing `on_error` neutralizes
			-- the throw; the curl call returns normally and we infer failure from
			-- the absent body / non-200 status.
			local ok, res = pcall(curl.get, M.config.api_url .. "/health", {
				timeout = 1500,
				on_error = function() end,
			})
			if not ok or not res or res.status ~= 200 or not res.body or res.body == "" then
				return false
			end
			local decoded_ok, decoded = pcall(vim.fn.json_decode, res.body)
			return decoded_ok and decoded and decoded.success == true or false
		end

		-- Returns the full task object for a given vault-relative path.
		function M.api.get_task(id)
			local res = M.api.get("/tasks/" .. M.api._encode_id(id))
			if res and res.success then
				return res.data
			end
			return nil
		end

		-- Partial update via PUT /api/tasks/{id}. patch is a table with only the
		-- fields to change (e.g. { status = "done" }).
		-- @return updated task object or nil on failure
		function M.api.update_task(id, patch)
			local res = M.api.put("/tasks/" .. M.api._encode_id(id), patch)
			if res and res.success then
				return res.data
			end
			return nil
		end

		function M.api.query_tasks(query)
			local res
			if query then
				res = M.api.post("/tasks/query", { query = query, limit = 1000 })
			else
				res = M.api.get("/tasks", { limit = 1000 })
			end

			if res and res.success and res.data and res.data.tasks then
				return res.data.tasks
			end
			return {}
		end

		-- ─────────────────────────────────────────────────────────────────
		-- API-backed caches (TTL'd, force-refresh via M.cache_ops.force_refresh)
		-- ─────────────────────────────────────────────────────────────────

		M.api._filter_options_cache = nil
		M.api._task_paths_cache = nil

		-- Fetches /api/filter-options (statuses, priorities, contexts, projects, tags).
		-- @param force_refresh boolean: bypass TTL cache
		-- @return table|nil { statuses, priorities, contexts, projects, tags } with rich metadata
		function M.api.get_filter_options(force_refresh)
			if not force_refresh and M.api._filter_options_cache then
				if os.time() - M.api._filter_options_cache.fetched_at < 300 then
					return M.api._filter_options_cache.data
				end
			end
			local res = M.api.get("/filter-options")
			if res and res.success and res.data then
				M.api._filter_options_cache = { data = res.data, fetched_at = os.time() }
				return res.data
			end
			return nil
		end

		-- Returns a set { [vault_relative_path] = true } of all task paths in the vault.
		-- Used to validate whether the current buffer is a task without touching the FS.
		function M.api.get_task_paths(force_refresh)
			if not force_refresh and M.api._task_paths_cache then
				if os.time() - M.api._task_paths_cache.fetched_at < 60 then
					return M.api._task_paths_cache.set
				end
			end
			local tasks = M.api.query_tasks(nil) or {}
			local set = {}
			for _, t in ipairs(tasks) do
				if t.path then
					set[t.path] = true
				end
			end
			M.api._task_paths_cache = { set = set, fetched_at = os.time() }
			return set
		end

		function M.api.invalidate_caches()
			M.api._filter_options_cache = nil
			M.api._task_paths_cache = nil
		end

		-- ─────────────────────────────────────────────────────────────────
		-- UTILITY FUNCTIONS
		-- ─────────────────────────────────────────────────────────────────

		-- Returns ISO 8601 timestamp with -03:00 offset
		local function get_timestamp()
			return os.date("!%Y-%m-%dT%H:%M:%S") .. "-03:00"
		end

		-- Creates a filename from a title, matching Obsidian/TaskNotes style
		local function create_filename(title)
			-- Remove only illegal filename characters: / \ : * ? " < > |
			local name = title:gsub("[%/%\\%:%*%?%\"%<%>%|]", "")
			return name .. ".md"
		end

		-- Calculates days remaining until a YYYY-MM-DD date
		local function get_days_until(date_str)
			if not date_str or date_str == "" then
				return nil
			end
			-- Support both YYYY-MM-DD and full ISO strings
			local y, m, d = date_str:match("(%d+)-(%d+)-(%d+)")
			if not y or not m or not d then
				return nil
			end

			local target_time = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0, min = 0, sec = 0 })
			local now = os.time()
			local diff = os.difftime(target_time, now)
			local days = math.ceil(diff / 86400)
			return days
		end

		-- ─────────────────────────────────────────────────────────────────
		-- STEP 3: Improved frontmatter parser
		-- Handles: scalars, YAML arrays (indented - item), inline arrays ([]),
		-- quoted strings, and gracefully skips malformed files.
		-- ─────────────────────────────────────────────────────────────────

		-- Strips surrounding single or double quotes from a string value
		local function strip_quotes(s)
			if not s then
				return s
			end
			s = vim.trim(s)
			if (s:sub(1, 1) == '"' and s:sub(-1) == '"') or (s:sub(1, 1) == "'" and s:sub(-1) == "'") then
				return s:sub(2, -2)
			end
			return s
		end

		-- Parses YAML frontmatter from a file.
		-- Reads only up to the closing '---' for performance.
		-- Returns a table of { key = value_or_table } or nil on failure.
		-- Uses a line-by-line state machine without goto for LuaJIT compatibility.
		local function parse_frontmatter(filepath)
			local ok, file = pcall(io.open, filepath, "r")
			if not ok or not file then
				return nil
			end

			-- Read all lines into a buffer (we stop early at closing ---)
			local raw_lines = {}
			for line in file:lines() do
				table.insert(raw_lines, line)
				-- Stop reading after we find the closing delimiter
				if #raw_lines > 1 and line:match("^%-%-%-") then
					break
				end
				-- Safety: don't read more than 200 lines for frontmatter
				if #raw_lines > 200 then
					break
				end
			end
			file:close()

			-- First line must be '---'
			if not raw_lines[1] or not raw_lines[1]:match("^%-%-%-") then
				return nil
			end

			local result = {}
			local current_array_key = nil

			for i = 2, #raw_lines do
				local line = raw_lines[i]

				-- Closing delimiter — stop parsing
				if line:match("^%-%-%-") then
					break
				end

				-- Indented list item: '  - value'
				if line:match("^%s+%-%s") then
					if current_array_key then
						local item = line:match("^%s+%-%s+(.*)")
						if item then
							item = strip_quotes(vim.trim(item))
							if item ~= "" then
								table.insert(result[current_array_key], item)
							end
						end
					end
				-- Key-value line: 'key: value' or 'key:'
				else
					local key, value = line:match("^([%w_%-]+):%s*(.*)")
					if key then
						current_array_key = nil -- reset array context
						value = vim.trim(value)

						-- Inline empty array: 'key: []' or bare 'key:'
						if value == "[]" or value == "" then
							result[key] = {}
							current_array_key = key

						-- Inline array with values: 'key: [a, b, c]'
						elseif value:match("^%[.+%]$") then
							local inner = value:sub(2, -2)
							local arr = {}
							for item in inner:gmatch("[^,]+") do
								local stripped = strip_quotes(vim.trim(item))
								if stripped ~= "" then
									table.insert(arr, stripped)
								end
							end
							result[key] = arr

						-- Scalar value
						else
							result[key] = strip_quotes(value)
						end
					end
				end
			end

			return result
		end

		-- ─────────────────────────────────────────────────────────────────
		-- STEP 4: Cache system
		-- ─────────────────────────────────────────────────────────────────

		M.cache = {
			data = {}, -- { [filepath] = { fm = table, mtime = number } }
			keys_index = {}, -- { [key] = { [value] = { filepath, ... } } }
			last_full_scan = 0,
		}

		-- Ensures the cache is fresh by fetching from the API.
		local function ensure_cache()
			local now = os.time()
			if now - M.cache.last_full_scan < M.config.cache_ttl then
				return
			end

			local t_start = vim.fn.reltime()
			
			local all_tasks = M.api.query_tasks(nil) or {}
			local index = {}
			local cache_data = {}

			for _, task in ipairs(all_tasks) do
				-- The API returns metadata flattened in the task object
				local fm = task
				-- Normalize to absolute path
				local filepath = M.config.vault_path .. "/" .. task.path
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

			M.cache.data = cache_data
			M.cache.keys_index = index
			M.cache.last_full_scan = now

			local elapsed = vim.fn.reltimestr(vim.fn.reltime(t_start))
			vim.notify(
				string.format("TaskNotes: cache refreshed from API (%d files, %ss)", #all_tasks, elapsed),
				vim.log.levels.DEBUG
			)
		end

		-- Invalidates the cache entry for a single file (after write operations)
		local function invalidate_file(filepath)
			M.cache.data[filepath] = nil
			-- Force index rebuild on next invocation
			M.cache.last_full_scan = 0
		end

		-- M.cache_ops: Public cache operations
		M.cache_ops = {}

		-- Forces a complete cache rebuild regardless of TTL.
		-- Invalidates BOTH the local frontmatter cache (used by <leader>owk drill-down)
		-- AND the API caches (filter-options + task paths).
		M.cache_ops.force_refresh = function()
			M.cache.data = {}
			M.cache.keys_index = {}
			M.cache.last_full_scan = 0
			ensure_cache()
			M.api.invalidate_caches()
			vim.notify("TaskNotes: local + API caches refreshed", vim.log.levels.INFO)
		end

		-- ─────────────────────────────────────────────────────────────────
		-- Rank tables for status/priority display order.
		-- Declared here (before M.picker) because pick_file and find_tasks
		-- both close over it. Sourced from /api/filter-options.
		-- ─────────────────────────────────────────────────────────────────

		local function get_rank_tables()
			local opts = M.api.get_filter_options()
			local status_ranks = {}
			local priority_ranks = {}
			if opts and opts.statuses then
				for i, s in ipairs(opts.statuses) do
					status_ranks[s.value] = s.order or i
				end
			end
			if opts and opts.priorities then
				-- High priority first → invert the natural order
				local n = #opts.priorities
				for i, p in ipairs(opts.priorities) do
					priority_ranks[p.value] = n - (p.order or i) + 1
				end
			end
			return status_ranks, priority_ranks
		end

		-- ─────────────────────────────────────────────────────────────────
		-- STEP 5-8: Snacks pickers (3-stage drill-down)
		-- ─────────────────────────────────────────────────────────────────

		M.picker = {}

		-- Stage 3: Pick a file from the list matching key=value.
		-- Displays filename with optional status/priority badge + time info.
		-- On <CR>: opens the file. On close without confirm: back to Stage 2.
		M.picker.pick_file = function(key, value, from_shortcut)
			local filepaths = M.cache.keys_index[key] and M.cache.keys_index[key][value]
			if not filepaths or #filepaths == 0 then
				vim.notify(string.format("TaskNotes: no files found for %s = %s", key, value), vim.log.levels.WARN)
				return
			end

			local status_ranks, priority_ranks = get_rank_tables()

			local items = {}
			for _, fp in ipairs(filepaths) do
				local filename = vim.fn.fnamemodify(fp, ":t")
				local title = filename:gsub("%.md$", "")
				local fm = M.cache.data[fp] and M.cache.data[fp].fm or {}

				local status_val = fm.status
				if type(status_val) == "table" then
					status_val = status_val[1]
				end
				local priority_val = fm.priority
				if type(priority_val) == "table" then
					priority_val = priority_val[1]
				end

				local status_rank = status_ranks[status_val] or 99
				local priority_rank = priority_ranks[priority_val] or 99

				local badge = ""
				if status_val then
					badge = badge .. "[" .. status_val .. "]"
				end
				if priority_val then
					badge = badge .. "[" .. priority_val .. "]"
				end

				local time_info = ""
				local days_until_due = get_days_until(fm.due)
				local days_until_sched = get_days_until(fm.scheduled)

				if days_until_due then
					if days_until_due == 0 then
						time_info = " (DUE TODAY)"
					elseif days_until_due < 0 then
						time_info = string.format(" (%dd OVERDUE)", math.abs(days_until_due))
					else
						time_info = string.format(" (%dd until due)", days_until_due)
					end
				elseif days_until_sched then
					if days_until_sched == 0 then
						time_info = " (Sched: Today)"
					elseif days_until_sched < 0 then
						time_info = string.format(" (%dd ago)", math.abs(days_until_sched))
					else
						time_info = string.format(" (%dd until sched)", days_until_sched)
					end
				end

				local display = badge ~= "" and (badge .. " " .. title .. time_info) or (title .. time_info)

				table.insert(items, {
					text = display,
					file = fp,
					status_rank = status_rank,
					priority_rank = priority_rank,
					title = title,
				})
			end

			table.sort(items, function(a, b)
				if a.status_rank ~= b.status_rank then
					return a.status_rank < b.status_rank
				end
				if a.priority_rank ~= b.priority_rank then
					return a.priority_rank < b.priority_rank
				end
				return a.title < b.title
			end)
			for i, item in ipairs(items) do
				item.idx = i
			end

			local confirmed = false
			Snacks.picker.pick({
				source = "tasknotes_file",
				title = string.format("%s: %s (%d files)", key, value, #filepaths),
				items = items,
				format = "text",
				preview = "file",
				confirm = function(picker, item)
					confirmed = true
					picker:close()
					if item then
						vim.cmd("edit " .. vim.fn.fnameescape(item.file))
					end
				end,
				on_close = function()
					if not confirmed then
						vim.schedule(function()
							M.picker.pick_value(key, from_shortcut)
						end)
					end
				end,
			})
		end

		-- Stage 2: Pick a value for the given key.
		-- Displays value + file count. On <CR>: transitions to Stage 3.
		-- On close without confirm: back to Stage 1 (unless from_shortcut).
		M.picker.pick_value = function(key, from_shortcut)
			ensure_cache()

			local value_map = M.cache.keys_index[key]
			if not value_map then
				vim.notify(string.format("TaskNotes: no values found for key '%s'", key), vim.log.levels.WARN)
				return
			end

			local items = {}
			for v, fps in pairs(value_map) do
				table.insert(items, {
					text = string.format("%s (%d files)", v, #fps),
					value = v,
				})
			end

			table.sort(items, function(a, b)
				return a.value < b.value
			end)
			for i, item in ipairs(items) do
				item.idx = i
			end

			local confirmed = false
			Snacks.picker.pick({
				source = "tasknotes_value",
				title = string.format("Values for: %s", key),
				items = items,
				format = "text",
				preview = "none",
				layout = { hidden = { "preview" } },
				confirm = function(picker, item)
					confirmed = true
					picker:close()
					if item then
						vim.schedule(function()
							M.picker.pick_file(key, item.value, from_shortcut)
						end)
					end
				end,
				on_close = function()
					if not confirmed and not from_shortcut then
						vim.schedule(function()
							M.picker.pick_key()
						end)
					end
				end,
			})
		end

		-- Stage 1: Pick a frontmatter key from the vault index.
		-- Displays key + file count. On <CR>: transitions to Stage 2.
		M.picker.pick_key = function()
			ensure_cache()

			local items = {}
			for key, value_map in pairs(M.cache.keys_index) do
				local file_set = {}
				for _, fps in pairs(value_map) do
					for _, fp in ipairs(fps) do
						file_set[fp] = true
					end
				end
				local file_count = 0
				for _ in pairs(file_set) do
					file_count = file_count + 1
				end

				table.insert(items, {
					text = string.format("%s (%d files)", key, file_count),
					value = key,
				})
			end

			if #items == 0 then
				vim.notify("TaskNotes: vault index is empty. Try <leader>owr to force refresh.", vim.log.levels.WARN)
				return
			end

			table.sort(items, function(a, b)
				return a.value < b.value
			end)
			for i, item in ipairs(items) do
				item.idx = i
			end

			Snacks.picker.pick({
				source = "tasknotes_key",
				title = "Frontmatter Key",
				items = items,
				format = "text",
				preview = "none",
				layout = { hidden = { "preview" } },
				confirm = function(picker, item)
					picker:close()
					if item then
						vim.schedule(function()
							M.picker.pick_value(item.value, false)
						end)
					end
				end,
			})
		end

		-- ─────────────────────────────────────────────────────────────────
		-- STEP 8: Shortcut pickers (skip Stage 1)
		-- ─────────────────────────────────────────────────────────────────

		-- Jumps directly to Stage 2 for the 'status' key
		M.picker.pick_file_by_status = function()
			ensure_cache()
			M.picker.pick_value("status", true)
		end

		-- Jumps directly to Stage 2 for the 'tags' key
		M.picker.pick_file_by_tag = function()
			ensure_cache()
			M.picker.pick_value("tags", true)
		end

		-- ─────────────────────────────────────────────────────────────────
		-- STEP 9: Task management operations (ported from legacy)
		-- ─────────────────────────────────────────────────────────────────

		M.task_ops = {}

		-- Writes YAML frontmatter back to a file.
		-- Preserves field ordering: known fields first, then any extras.
		local function write_frontmatter(filepath, metadata, body)
			body = body or ""

			local lines = { "---" }

			local order = {
				"status",
				"priority",
				"due",
				"scheduled",
				"projects",
				"contexts",
				"tags",
				"dateCreated",
				"dateModified",
				"completedDate",
				"timeEntries",
				"recurrence",
				"complete_instances",
				"skipped_instances",
			}

			-- Write ordered fields first
			for _, key in ipairs(order) do
				if metadata[key] ~= nil then
					if type(metadata[key]) == "table" then
						table.insert(lines, key .. ":")
						for _, v in ipairs(metadata[key]) do
							table.insert(lines, "  - " .. tostring(v))
						end
					else
						table.insert(lines, key .. ": " .. tostring(metadata[key]))
					end
				end
			end

			-- Write any remaining fields not in the ordered list
			local ordered_set = {}
			for _, k in ipairs(order) do
				ordered_set[k] = true
			end

			for key, value in pairs(metadata) do
				if not ordered_set[key] then
					if type(value) == "table" then
						table.insert(lines, key .. ":")
						for _, v in ipairs(value) do
							table.insert(lines, "  - " .. tostring(v))
						end
					else
						table.insert(lines, key .. ": " .. tostring(value))
					end
				end
			end

			table.insert(lines, "---")
			table.insert(lines, "")
			if body ~= "" then
				table.insert(lines, body)
			end

			local file = io.open(filepath, "w")
			if file then
				file:write(table.concat(lines, "\n"))
				file:close()
				return true
			end
			return false
		end

		-- Extracts the body content (everything after the closing ---)
		local function extract_body(filepath)
			local file = io.open(filepath, "r")
			if not file then
				return ""
			end
			local content = file:read("*all")
			file:close()
			-- Match content after the second ---
			local body = content:match("^%-%-%-\n.-\n%-%-%-\n\n?(.*)")
			return body or ""
		end

		-- ─────────────────────────────────────────────────────────────────
		-- Shared helpers for task_ops + query_builder
		-- ─────────────────────────────────────────────────────────────────

		-- Converts the current buffer's absolute path to a vault-relative id.
		-- Returns (id, abs, vault) on success, (nil, abs, vault) when outside.
		local function buffer_to_id()
			local abs = vim.fs.normalize(vim.fn.expand("%:p"))
			local vault = vim.fs.normalize(M.config.vault_path)
			-- Plain prefix check (no vim.pesc — that breaks with paths containing . or -)
			local prefix = vault .. "/"
			if abs:sub(1, #prefix) ~= prefix then
				return nil, abs, vault
			end
			return abs:sub(#prefix + 1), abs, vault
		end

		-- Returns the vault-relative id if the current buffer is a known task
		-- (per /api/tasks). Notifies and returns nil otherwise.
		-- This replaces the old folder-based TaskNotes/Tasks check — tasks can
		-- live anywhere in the vault as long as they carry `tag: task`.
		local function require_task_buffer()
			local id, abs, vault = buffer_to_id()
			if not id then
				vim.notify(
					string.format("Buffer is outside the vault.\n  file:  %s\n  vault: %s", abs, vault),
					vim.log.levels.WARN
				)
				return nil
			end
			local task_paths = M.api.get_task_paths()
			if not task_paths or not task_paths[id] then
				vim.notify(
					string.format(
						"Buffer is not a recognized task: %s\n(Force cache refresh with <leader>owr if recently added)",
						id
					),
					vim.log.levels.WARN
				)
				return nil
			end
			return id
		end

		-- Normalizes a frontmatter scalar that may be string or first-element of a list.
		local function unwrap_scalar(v)
			if type(v) == "table" then
				return v[1]
			end
			return v
		end

		-- Builds the item list for a 60-day calendar picker.
		-- @param current string|nil: currently selected date (renders a marker)
		-- @param include_clear boolean: prepend a "Clear" option
		local function build_calendar_items(current, include_clear)
			local day_names = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
			local items = {}
			if include_clear then
				table.insert(items, { text = "  [x] Clear", kind = "clear" })
			end
			table.insert(items, { text = "  [+] Custom date (YYYY-MM-DD)...", kind = "custom" })

			local today_ts = os.time()
			for offset = 0, 60 do
				local ts = today_ts + offset * 86400
				local date_str = os.date("%Y-%m-%d", ts)
				local day_name = day_names[tonumber(os.date("%w", ts)) + 1]
				local label
				if offset == 0 then
					label = "Today"
				elseif offset == 1 then
					label = "Tomorrow"
				elseif offset < 7 then
					label = string.format("In %d days", offset)
				elseif offset == 7 then
					label = "Next week"
				elseif offset % 7 == 0 then
					label = string.format("In %d weeks", math.floor(offset / 7))
				else
					label = string.format("+%dd", offset)
				end
				-- current may carry a THH:MM suffix (edit_fields); match on the
				-- date prefix so the day marker still renders.
				local cur_date = current and current:sub(1, 10)
				local marker = (date_str == cur_date) and "● " or "  "
				table.insert(items, {
					text = string.format("%s%s %s — %s", marker, day_name, date_str, label),
					value = date_str,
					kind = "date",
				})
			end
			for i, item in ipairs(items) do
				item.idx = i
			end
			return items
		end

		-- Builds the item list for the time-of-day picker (Stage 2 of date edit).
		-- @param current_time string|nil: currently selected "HH:MM" (renders a marker)
		local function build_time_items(current_time)
			local items = {
				{ text = "  [x] All-day (no time)", kind = "allday" },
				{ text = "  [+] Custom time (HH:MM)...", kind = "custom" },
			}
			-- Full 24h grid in 15-minute steps (00:00 → 23:45); filter by typing.
			for h = 0, 23 do
				for _, m in ipairs({ 0, 15, 30, 45 }) do
					local t = string.format("%02d:%02d", h, m)
					local marker = (t == current_time) and "● " or "  "
					table.insert(items, { text = marker .. t, value = t, kind = "time" })
				end
			end
			for i, item in ipairs(items) do
				item.idx = i
			end
			return items
		end

		-- Creates a new task file with frontmatter template using NLP API
		M.task_ops.create_task = function()
			vim.ui.input({ prompt = "Quick Add (NLP): " }, function(input)
				if not input or input == "" then
					return
				end

				-- /api/nlp/create both parses the NL string AND writes the task file
				-- server-side with the configured template. Replaces the prior
				-- /api/nlp/parse + write_frontmatter() pair (which bypassed the
				-- template and let the plugin drift from server formatting).
				local res = M.api.post("/nlp/create", { text = input })
				if not res or not res.success or not res.data or not res.data.task then
					return
				end

				local task = res.data.task
				local abs_path = M.config.vault_path .. "/" .. task.path
				vim.cmd("edit " .. vim.fn.fnameescape(abs_path))
				vim.notify("Created task: " .. (task.title or input), vim.log.levels.INFO)
				M.api.invalidate_caches()
				invalidate_file(abs_path)
			end)
		end

		-- Defines (or refreshes) a vim highlight group for a status/priority color
		-- and returns its name. Color is a hex string like "#1029e5".
		local function ensure_color_hl(prefix, value, color)
			if not color then
				return "Normal"
			end
			local name = prefix .. "_" .. value:gsub("[^%w]", "_")
			vim.api.nvim_set_hl(0, name, { fg = color })
			return name
		end

		-- Builds picker items for a list of filter-option entries
		-- (each entry has value/label/color/order/icon/isCompleted).
		local function build_option_items(prefix, options, current)
			local items = {}
			for i, opt in ipairs(options) do
				local marker = (opt.value == current) and "● " or "  "
				local hl = ensure_color_hl(prefix, opt.value, opt.color)
				table.insert(items, {
					idx = i,
					text = marker .. opt.label,
					value = opt.value,
					label = opt.label,
					color = opt.color,
					hl = hl,
					order = opt.order or i,
				})
			end
			table.sort(items, function(a, b)
				return (a.order or 99) < (b.order or 99)
			end)
			for i, item in ipairs(items) do
				item.idx = i
			end
			return items
		end

		-- Snacks format function that colorizes the entire item text using
		-- the precomputed hl group on item.hl. Safe with multi-byte markers (●).
		local function color_format(item, _picker)
			return { { item.text, item.hl or "Normal" } }
		end

		-- get_rank_tables defined earlier (before M.picker) — see line ~437.


		-- ─────────────────────────────────────────────────────────────────
		-- Field editor (Stage 1 = field selector, Stage 2 = value picker)
		-- Same UX as query_builder but for SETTING task metadata.
		-- All changes accumulate in a patch table; Save fires a single PUT.
		-- ─────────────────────────────────────────────────────────────────

		M.task_ops.edit_fields = {}

		local function fmt_field(value)
			if value == nil or value == "" then
				return "none"
			end
			if type(value) == "table" then
				if #value == 0 then
					return "none"
				end
				return table.concat(value, ", ")
			end
			return tostring(value)
		end

		-- Returns the effective value for a field (patch wins over original).
		local function effective(task, patch, field)
			if patch[field] ~= nil then
				return patch[field]
			end
			return task[field]
		end

		M.task_ops.edit_fields.open = function()
			local id = require_task_buffer()
			if not id then
				return
			end
			local task = M.api.get_task(id)
			if not task then
				vim.notify("Could not fetch task: " .. id, vim.log.levels.ERROR)
				return
			end
			local patch = {}
			M.task_ops.edit_fields._show(id, task, patch)
		end

		M.task_ops.edit_fields._show = function(id, task, patch)
			local items = {
				-- API maps `title` to the configured title-source frontmatter field
				-- (here `task:`); editing it via PUT does not rename the file.
				{ idx = 1, text = string.format("Task:      %s", fmt_field(effective(task, patch, "title"))), action = "title" },
				{ idx = 2, text = string.format("Status:    %s", fmt_field(effective(task, patch, "status"))), action = "status" },
				{ idx = 3, text = string.format("Priority:  %s", fmt_field(effective(task, patch, "priority"))), action = "priority" },
				{ idx = 4, text = string.format("Contexts:  %s", fmt_field(effective(task, patch, "contexts"))), action = "contexts" },
				{ idx = 5, text = string.format("Projects:  %s", fmt_field(effective(task, patch, "projects"))), action = "projects" },
				{ idx = 6, text = string.format("Tags:      %s", fmt_field(effective(task, patch, "tags"))), action = "tags" },
				{ idx = 7, text = string.format("Scheduled: %s", fmt_field(effective(task, patch, "scheduled"))), action = "scheduled" },
				{ idx = 8, text = string.format("Due:       %s", fmt_field(effective(task, patch, "due"))), action = "due" },
				{ idx = 9, text = "─────────────────────────", action = "noop" },
				{ idx = 10, text = "✓ Save changes", action = "save" },
				{ idx = 11, text = "✗ Discard", action = "discard" },
			}

			local pending_count = 0
			for _ in pairs(patch) do
				pending_count = pending_count + 1
			end

			Snacks.picker.pick({
				source = "tasknotes_edit_fields",
				title = string.format(
					"Edit Task — %s%s",
					task.title or id,
					pending_count > 0 and string.format(" (%d unsaved)", pending_count) or ""
				),
				items = items,
				format = "text",
				preview = "none",
				layout = { hidden = { "preview" } },
				confirm = function(picker, item)
					picker:close()
					if not item or item.action == "noop" then
						vim.schedule(function()
							M.task_ops.edit_fields._show(id, task, patch)
						end)
						return
					end
					vim.schedule(function()
						if item.action == "save" then
							if pending_count == 0 then
								vim.notify("No changes to save", vim.log.levels.INFO)
								return
							end
							local updated = M.api.update_task(id, patch)
							if updated then
								vim.notify(string.format("Saved %d field(s)", pending_count), vim.log.levels.INFO)
								vim.cmd("edit!")
								invalidate_file(M.config.vault_path .. "/" .. id)
							end
						elseif item.action == "discard" then
							vim.notify("Changes discarded", vim.log.levels.INFO)
						elseif item.action == "status" or item.action == "priority" then
							M.task_ops.edit_fields._pick_option(id, task, patch, item.action)
						elseif item.action == "title" then
							M.task_ops.edit_fields._pick_text(id, task, patch, item.action)
						elseif item.action == "contexts" or item.action == "projects" or item.action == "tags" then
							M.task_ops.edit_fields._pick_multi(id, task, patch, item.action)
						elseif item.action == "scheduled" or item.action == "due" then
							M.task_ops.edit_fields._pick_date(id, task, patch, item.action)
						end
					end)
				end,
			})
		end

		-- Free-text editor for scalar string fields (e.g. `title`, which the API
		-- routes to the configured title-source frontmatter field). Pre-fills the
		-- current value so the user edits in place rather than retyping.
		M.task_ops.edit_fields._pick_text = function(id, task, patch, field)
			local current = effective(task, patch, field)
			vim.ui.input({ prompt = field .. ": ", default = current or "" }, function(input)
				-- nil = cancelled (Esc) → leave patch untouched.
				if input ~= nil then
					patch[field] = input
				end
				M.task_ops.edit_fields._show(id, task, patch)
			end)
		end

		M.task_ops.edit_fields._pick_option = function(id, task, patch, field)
			local options = M.api.get_filter_options()
			local list = options and options[field .. "es"] or options and options[field .. "s"]
			-- statuses or priorities
			if field == "status" then
				list = options and options.statuses
			elseif field == "priority" then
				list = options and options.priorities
			end
			if not list then
				vim.notify("Could not fetch " .. field .. " options", vim.log.levels.ERROR)
				M.task_ops.edit_fields._show(id, task, patch)
				return
			end
			local current = effective(task, patch, field)
			local items = build_option_items("TaskNotesEdit_" .. field, list, current)

			local confirmed = false
			Snacks.picker.pick({
				source = "tasknotes_edit_" .. field,
				title = string.format("%s (current: %s)", field, current or "none"),
				items = items,
				format = color_format,
				preview = "none",
				layout = { hidden = { "preview" } },
				confirm = function(picker, item)
					confirmed = true
					picker:close()
					if item then
						patch[field] = item.value
					end
					vim.schedule(function()
						M.task_ops.edit_fields._show(id, task, patch)
					end)
				end,
				on_close = function()
					if not confirmed then
						vim.schedule(function()
							M.task_ops.edit_fields._show(id, task, patch)
						end)
					end
				end,
			})
		end

		M.task_ops.edit_fields._pick_multi = function(id, task, patch, field)
			local options = M.api.get_filter_options()
			local raw = options and options[field] or {}
			local current = effective(task, patch, field) or {}
			local current_set = {}
			for _, v in ipairs(current) do
				current_set[v] = true
			end

			-- Items are plain — Snacks renders its native selection dot for
			-- entries present in picker.list.selected (see `on_show` below).
			local items = {}
			local preselect_targets = {}
			for i, opt in ipairs(raw) do
				local item = { idx = i, text = opt, value = opt }
				table.insert(items, item)
				if current_set[opt] then
					table.insert(preselect_targets, item)
				end
			end
			table.insert(items, { idx = #items + 1, text = "+ New " .. field:sub(1, -2) .. "...", kind = "new" })

			-- Collects Tab-marked items (the FULL desired set, excluding "[+] New").
			local function collect_marks(picker)
				local values = {}
				for _, it in ipairs(picker.list.selected) do
					if it.kind ~= "new" then
						table.insert(values, it.value)
					end
				end
				return values
			end

			local confirmed = false
			Snacks.picker.pick({
				source = "tasknotes_edit_" .. field,
				title = string.format("%s — <Tab> toggle, <CR> apply", field),
				items = items,
				format = "text",
				preview = "none",
				layout = { hidden = { "preview" } },
				on_show = function(picker)
					-- Pre-mark items whose value is already in the effective set,
					-- so the user sees them with the native dot and can Tab them
					-- off (remove) or Tab additional items on (add) without
					-- losing the originals.
					picker.list:set_selected(preselect_targets)
				end,
				confirm = function(picker, single_item)
					confirmed = true
					-- "+ New ..." path: prompt for a new value and append to the
					-- currently-marked set (preserves originals + any toggles).
					if single_item and single_item.kind == "new" then
						local marks = collect_marks(picker)
						picker:close()
						vim.schedule(function()
							vim.ui.input({ prompt = "New " .. field:sub(1, -2) .. ": " }, function(input)
								if input and input ~= "" then
									table.insert(marks, input)
								end
								patch[field] = marks
								M.task_ops.edit_fields._show(id, task, patch)
							end)
						end)
						return
					end
					-- Regular path: apply the marked set as the new full value.
					-- An empty set is intentional (user cleared all marks).
					local values = collect_marks(picker)
					picker:close()
					patch[field] = values
					vim.schedule(function()
						M.task_ops.edit_fields._show(id, task, patch)
					end)
				end,
				on_close = function()
					if not confirmed then
						vim.schedule(function()
							M.task_ops.edit_fields._show(id, task, patch)
						end)
					end
				end,
			})
		end

		M.task_ops.edit_fields._pick_date = function(id, task, patch, field)
			local current = effective(task, patch, field)
			local items = build_calendar_items(current, true)

			local confirmed = false
			Snacks.picker.pick({
				source = "tasknotes_edit_" .. field,
				title = string.format("%s (current: %s)", field, current or "none"),
				items = items,
				format = "text",
				preview = "none",
				layout = { hidden = { "preview" } },
				confirm = function(picker, item)
					confirmed = true
					picker:close()
					if not item then
						vim.schedule(function()
							M.task_ops.edit_fields._show(id, task, patch)
						end)
						return
					end
					if item.kind == "clear" then
						patch[field] = ""
						vim.schedule(function()
							M.task_ops.edit_fields._show(id, task, patch)
						end)
					elseif item.kind == "custom" then
						vim.schedule(function()
							vim.ui.input({ prompt = "Date (YYYY-MM-DD[THH:MM]): " }, function(input)
								if input and input:match("^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d$") then
									-- Full date+time given inline → set directly, skip time stage.
									patch[field] = input
									M.task_ops.edit_fields._show(id, task, patch)
								elseif input and input:match("^%d%d%d%d%-%d%d%-%d%d$") then
									-- Date only → advance to the time-of-day picker.
									M.task_ops.edit_fields._pick_time(id, task, patch, field, input)
								elseif input and input ~= "" then
									vim.notify("Invalid format. Use YYYY-MM-DD or YYYY-MM-DDTHH:MM", vim.log.levels.ERROR)
									M.task_ops.edit_fields._show(id, task, patch)
								else
									M.task_ops.edit_fields._show(id, task, patch)
								end
							end)
						end)
					else
						-- A concrete calendar day → choose time (or all-day) in Stage 2.
						vim.schedule(function()
							M.task_ops.edit_fields._pick_time(id, task, patch, field, item.value)
						end)
					end
				end,
				on_close = function()
					if not confirmed then
						vim.schedule(function()
							M.task_ops.edit_fields._show(id, task, patch)
						end)
					end
				end,
			})
		end

		-- Stage 2 of date editing: pick the time-of-day for an already-chosen day.
		-- "All-day" stores the bare YYYY-MM-DD; a time stores YYYY-MM-DDTHH:MM.
		M.task_ops.edit_fields._pick_time = function(id, task, patch, field, date_str)
			local current = effective(task, patch, field)
			local cur_time = nil
			if current and current:sub(1, 10) == date_str then
				cur_time = current:match("T(%d%d:%d%d)")
			end
			local items = build_time_items(cur_time)

			local confirmed = false
			Snacks.picker.pick({
				source = "tasknotes_edit_" .. field .. "_time",
				title = string.format("%s @ %s — pick time", field, date_str),
				items = items,
				format = "text",
				preview = "none",
				layout = { hidden = { "preview" } },
				confirm = function(picker, item)
					confirmed = true
					picker:close()
					if not item or item.kind == "allday" then
						patch[field] = date_str
						vim.schedule(function()
							M.task_ops.edit_fields._show(id, task, patch)
						end)
					elseif item.kind == "custom" then
						vim.schedule(function()
							vim.ui.input({ prompt = "Time (HH:MM): " }, function(input)
								if input and input:match("^%d%d:%d%d$") then
									patch[field] = date_str .. "T" .. input
								elseif input and input ~= "" then
									vim.notify("Invalid time format. Use HH:MM", vim.log.levels.ERROR)
									patch[field] = date_str
								else
									patch[field] = date_str
								end
								M.task_ops.edit_fields._show(id, task, patch)
							end)
						end)
					else
						patch[field] = date_str .. "T" .. item.value
						vim.schedule(function()
							M.task_ops.edit_fields._show(id, task, patch)
						end)
					end
				end,
				on_close = function()
					if not confirmed then
						vim.schedule(function()
							M.task_ops.edit_fields._show(id, task, patch)
						end)
					end
				end,
			})
		end

		-- ─────────────────────────────────────────────────────────────────
		-- Legacy query system (preserved for backward compatibility)
		-- ─────────────────────────────────────────────────────────────────

		-- Builds a filter function from a query parameter table.
		-- Query params: { status, priority, contexts, scheduled_before, scheduled_after }
		M.build_query_filter = function(query)
			return function(metadata)
				if query.status and #query.status > 0 then
					local status_val = metadata.status
					if type(status_val) == "table" then
						status_val = status_val[1]
					end
					local match = false
					for _, s in ipairs(query.status) do
						if status_val == s then
							match = true
							break
						end
					end
					if not match then
						return false
					end
				end

				if query.priority and #query.priority > 0 then
					local priority_val = metadata.priority
					if type(priority_val) == "table" then
						priority_val = priority_val[1]
					end
					local match = false
					for _, p in ipairs(query.priority) do
						if priority_val == p then
							match = true
							break
						end
					end
					if not match then
						return false
					end
				end

				if query.contexts and #query.contexts > 0 then
					if not metadata.contexts then
						return false
					end
					local ctx_list = metadata.contexts
					if type(ctx_list) == "string" then
						ctx_list = { ctx_list }
					end
					local match = false
					for _, qc in ipairs(query.contexts) do
						for _, mc in ipairs(ctx_list) do
							if mc == qc then
								match = true
								break
							end
						end
						if match then
							break
						end
					end
					if not match then
						return false
					end
				end

				-- Date range filters: a missing `scheduled` field is treated as
				-- unknown (SQL NULL semantics) and excluded when a bound is set.
				-- Bounds are inclusive: scheduled_after = "on or after",
				-- scheduled_before = "on or before". Comparison is lexicographic
				-- on ISO YYYY-MM-DD prefixes, which is order-preserving for dates.
				if query.scheduled_after or query.scheduled_before then
					if not metadata.scheduled then
						return false
					end
					local sched = tostring(metadata.scheduled):sub(1, 10)
					if query.scheduled_after and sched < query.scheduled_after then
						return false
					end
					if query.scheduled_before and sched > query.scheduled_before then
						return false
					end
				end

				return true
			end
		end

		-- Finds tasks using the API and opens a Snacks picker.
		-- @param query_or_filter table|function|nil: API FilterQuery OR legacy filter function
		-- @param filter_fn function|nil: Legacy filter function (if first arg is api_query)
		M.find_tasks = function(query_or_filter, filter_fn)
			local api_query, final_filter
			if type(query_or_filter) == "function" then
				final_filter = query_or_filter
			else
				api_query = query_or_filter
				final_filter = filter_fn
			end

			local tasks = {}
			if api_query then
				tasks = M.api.query_tasks(api_query) or {}
			else
				local all_tasks = M.api.query_tasks(nil) or {}
				if final_filter then
					-- API returns flat objects (status/priority/etc. at top level), not nested under frontmatter.
					for _, t in ipairs(all_tasks) do
						if final_filter(t) then
							table.insert(tasks, t)
						end
					end
				else
					tasks = all_tasks
				end
			end

			local status_ranks, priority_ranks = get_rank_tables()

			local items = {}
			for _, task in ipairs(tasks) do
				local fm = task
				local status_val = fm.status
				if type(status_val) == "table" then
					status_val = status_val[1]
				end
				local priority_val = fm.priority
				if type(priority_val) == "table" then
					priority_val = priority_val[1]
				end

				local status_rank = status_ranks[status_val] or 99
				local priority_rank = priority_ranks[priority_val] or 99

				local abs_path = M.config.vault_path .. "/" .. task.path
				local title = vim.fn.fnamemodify(abs_path, ":t:r")

				local time_info = ""
				local days_until_due = get_days_until(fm.due)
				local days_until_sched = get_days_until(fm.scheduled)

				if days_until_due then
					if days_until_due == 0 then
						time_info = " (DUE TODAY)"
					elseif days_until_due < 0 then
						time_info = string.format(" (%dd OVERDUE)", math.abs(days_until_due))
					else
						time_info = string.format(" (%dd until due)", days_until_due)
					end
				elseif days_until_sched then
					if days_until_sched == 0 then
						time_info = " (Sched: Today)"
					elseif days_until_sched < 0 then
						time_info = string.format(" (%dd ago)", math.abs(days_until_sched))
					else
						time_info = string.format(" (%dd until sched)", days_until_sched)
					end
				end

				local display =
					string.format("[%s][%s] %s%s", status_val or "none", priority_val or "none", title, time_info)

				table.insert(items, {
					text = display,
					file = abs_path,
					status_rank = status_rank,
					priority_rank = priority_rank,
					title = title,
				})
			end

			if #items == 0 then
				vim.notify("No tasks found", vim.log.levels.INFO)
				return
			end

			table.sort(items, function(a, b)
				if a.status_rank ~= b.status_rank then
					return a.status_rank < b.status_rank
				end
				if a.priority_rank ~= b.priority_rank then
					return a.priority_rank < b.priority_rank
				end
				return a.title < b.title
			end)
			for i, item in ipairs(items) do
				item.idx = i
			end

			Snacks.picker.pick({
				source = "tasknotes_find",
				title = "TaskNotes",
				items = items,
				format = "text",
				preview = "file",
				confirm = function(picker, item)
					picker:close()
					if item then
						vim.cmd("edit " .. vim.fn.fnameescape(item.file))
					end
				end,
			})
		end

		-- ─────────────────────────────────────────────────────────────────
		-- Interactive query builder (field-selector pattern)
		-- ─────────────────────────────────────────────────────────────────
		--
		-- UX: Stage 1 = field selector (status, priority, contexts, dates, apply, reset)
		--     Stage 2 = picker for that field's values (multi-select via <Tab> for list fields,
		--               calendar picker for date fields). On close → back to Stage 1.
		--     Apply  = builds filter and calls M.find_tasks.
		M.query_builder = {}

		local function fmt_list(t)
			if not t or #t == 0 then
				return "none"
			end
			return table.concat(t, ", ")
		end

		M.query_builder.open = function()
			ensure_cache()
			local query = { status = {}, priority = {}, contexts = {} }
			M.query_builder._show_fields(query)
		end

		M.query_builder._show_fields = function(query)
			local items = {
				{ idx = 1, text = string.format("Status:           %s", fmt_list(query.status)), action = "status" },
				{ idx = 2, text = string.format("Priority:         %s", fmt_list(query.priority)), action = "priority" },
				{ idx = 3, text = string.format("Contexts:         %s", fmt_list(query.contexts)), action = "contexts" },
				{ idx = 4, text = string.format("Scheduled on/after:  %s", query.scheduled_after or "none"), action = "scheduled_after" },
				{ idx = 5, text = string.format("Scheduled on/before: %s", query.scheduled_before or "none"), action = "scheduled_before" },
				{ idx = 6, text = "─────────────────────────", action = "noop" },
				{ idx = 7, text = "✓ Apply query", action = "apply" },
				{ idx = 8, text = "✗ Reset filters", action = "reset" },
			}

			Snacks.picker.pick({
				source = "tasknotes_query_builder",
				title = "Query Builder",
				items = items,
				format = "text",
				preview = "none",
				layout = { hidden = { "preview" } },
				confirm = function(picker, item)
					picker:close()
					if not item or item.action == "noop" then
						vim.schedule(function()
							M.query_builder._show_fields(query)
						end)
						return
					end
					vim.schedule(function()
						if item.action == "apply" then
							local filter = M.build_query_filter(query)
							M.find_tasks(filter)
						elseif item.action == "reset" then
							M.query_builder._show_fields({ status = {}, priority = {}, contexts = {} })
						elseif item.action == "status" then
							local opts = M.api.get_filter_options()
							local statuses = (opts and opts.statuses) or {}
							M.query_builder._pick_multi(query, "status", statuses, "Status")
						elseif item.action == "priority" then
							local opts = M.api.get_filter_options()
							local priorities = (opts and opts.priorities) or {}
							M.query_builder._pick_multi(query, "priority", priorities, "Priority")
						elseif item.action == "contexts" then
							local opts = M.api.get_filter_options()
							local raw = (opts and opts.contexts) or {}
							-- /api/filter-options returns contexts as plain strings.
							local ctx_opts = {}
							for _, c in ipairs(raw) do
								table.insert(ctx_opts, { value = c, label = c })
							end
							M.query_builder._pick_multi(query, "contexts", ctx_opts, "Contexts")
						elseif item.action == "scheduled_after" or item.action == "scheduled_before" then
							M.query_builder._pick_date(query, item.action)
						end
					end)
				end,
			})
		end

		-- @param options table: list of either strings or {value, label, color, order} objects
		M.query_builder._pick_multi = function(query, field, options, label)
			if #options == 0 then
				vim.notify("No options available for " .. field, vim.log.levels.WARN)
				vim.schedule(function()
					M.query_builder._show_fields(query)
				end)
				return
			end

			local current_set = {}
			for _, v in ipairs(query[field] or {}) do
				current_set[v] = true
			end

			local items = {}
			for i, opt in ipairs(options) do
				-- Support both string options and {value, label, color, order} option objects.
				local value, display, color, order
				if type(opt) == "string" then
					value, display = opt, opt
				else
					value = opt.value
					display = opt.label or opt.value
					color = opt.color
					order = opt.order
				end
				local marker = current_set[value] and "[x] " or "[ ] "
				local hl = ensure_color_hl("TaskNotesQuery_" .. field, value, color)
				table.insert(items, {
					idx = i,
					text = marker .. display,
					value = value,
					hl = hl,
					order = order or i,
				})
			end
			table.sort(items, function(a, b)
				return (a.order or 99) < (b.order or 99)
			end)
			for i, item in ipairs(items) do
				item.idx = i
			end

			local confirmed = false
			Snacks.picker.pick({
				source = "tasknotes_query_multi",
				title = string.format("%s — <Tab> select, <CR> apply", label),
				items = items,
				format = color_format,
				preview = "none",
				layout = { hidden = { "preview" } },
				confirm = function(picker)
					confirmed = true
					local selected = picker:selected({ fallback = true })
					local values = {}
					for _, item in ipairs(selected) do
						table.insert(values, item.value)
					end
					query[field] = values
					picker:close()
					vim.schedule(function()
						M.query_builder._show_fields(query)
					end)
				end,
				on_close = function()
					if not confirmed then
						vim.schedule(function()
							M.query_builder._show_fields(query)
						end)
					end
				end,
			})
		end

		M.query_builder._pick_date = function(query, field)
			local current = query[field]
			local items = build_calendar_items(current, true)

			local confirmed = false
			Snacks.picker.pick({
				source = "tasknotes_query_date",
				title = string.format("%s (current: %s)", field, current or "none"),
				items = items,
				format = "text",
				preview = "none",
				layout = { hidden = { "preview" } },
				confirm = function(picker, item)
					confirmed = true
					picker:close()
					if not item then
						vim.schedule(function()
							M.query_builder._show_fields(query)
						end)
						return
					end
					if item.kind == "clear" then
						query[field] = nil
						vim.schedule(function()
							M.query_builder._show_fields(query)
						end)
					elseif item.kind == "custom" then
						vim.schedule(function()
							vim.ui.input({ prompt = "Date (YYYY-MM-DD): " }, function(input)
								if input and input:match("^%d%d%d%d%-%d%d%-%d%d$") then
									query[field] = input
								elseif input and input ~= "" then
									vim.notify("Invalid date format. Use YYYY-MM-DD", vim.log.levels.ERROR)
								end
								M.query_builder._show_fields(query)
							end)
						end)
					else
						query[field] = item.value
						vim.schedule(function()
							M.query_builder._show_fields(query)
						end)
					end
				end,
				on_close = function()
					if not confirmed then
						vim.schedule(function()
							M.query_builder._show_fields(query)
						end)
					end
				end,
			})
		end

		-- ─────────────────────────────────────────────────────────────────
		-- STEP 10: Boot health check + Keybindings
		--
		-- Per the API-driven directive: if /api/health does not respond at
		-- startup the plugin refuses to register keymaps and notifies the user.
		-- No file-I/O fallback for mutations.
		-- ─────────────────────────────────────────────────────────────────

		if not M.api.health() then
			vim.notify(
				"TaskNotes API not reachable at "
					.. M.config.api_url
					.. "\nKeymaps NOT registered. Start the TaskNotes API server and :Lazy reload tasknotes.",
				vim.log.levels.WARN
			)
			return
		end

		-- <leader>ow* — Zettelkasten search + filtering
		-- All mutations route through the multi-field editor (`owe`); singles
		-- removed because edit_fields covers status/priority/contexts/projects/
		-- scheduled/due in one PUT.
		vim.keymap.set("n", "<leader>owk", M.picker.pick_key, { desc = "Search by frontmatter key" })
		vim.keymap.set("n", "<leader>owr", M.cache_ops.force_refresh, { desc = "Force cache rebuild" })
		vim.keymap.set("n", "<leader>ows", M.picker.pick_file_by_status, { desc = "Filter by status" })
		vim.keymap.set("n", "<leader>owo", M.picker.pick_file_by_tag, { desc = "Filter by tag/project" })
		vim.keymap.set("n", "<leader>owq", M.query_builder.open, { desc = "Task: Query builder" })

		vim.keymap.set("n", "<leader>own", M.task_ops.create_task, { desc = "Task: New" })
		vim.keymap.set("n", "<leader>owe", M.task_ops.edit_fields.open, { desc = "Task: Edit fields" })
	end, -- end config
}
