-- TaskNotes v2 — Multi-stage Snacks.picker search + task management
-- Provides frontmatter-indexed search across the entire Zettelkasten vault
-- and preserves all legacy task management operations.
--
-- Architecture:
--   M.config        — Configuration table
--   M.cache         — In-memory frontmatter cache with TTL + mtime invalidation
--   parse_frontmatter() — Improved YAML state-machine parser
--   scan_vault()    — Full/incremental vault scan
--   build_index()   — Inverted index: key → value → [filepaths]
--   ensure_cache()  — TTL-gated cache refresh
--   M.picker.*      — 3-stage Snacks pickers (Key → Value → File)
--   M.task_ops.*    — Task CRUD operations (ported from legacy)
--   Keybindings     — <leader>ow* (search + task management)

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
			cache_ttl = 30, -- seconds
			default_status = "open",
			default_priority = "normal",
			statuses = { "none", "open", "in-progress", "on-hold", "waiting", "done", "archive" },
			priorities = { "none", "low", "normal", "high" },
		}

		-- ─────────────────────────────────────────────────────────────────
		-- API HELPER
		-- ─────────────────────────────────────────────────────────────────
		M.api = {}

		function M.api.request(method, endpoint, params)
			local curl = require("plenary.curl")
			local url = M.config.api_url .. endpoint
			local options = {
				headers = {
					content_type = "application/json",
				},
			}

			if method == "POST" then
				options.body = vim.fn.json_encode(params or {})
				local res = curl.post(url, options)
				if res.status ~= 200 then
					vim.notify("TaskNotes API error (POST " .. endpoint .. "): " .. res.status, vim.log.levels.ERROR)
					return nil
				end
				return vim.fn.json_decode(res.body)
			else
				options.query = params
				local res = curl.get(url, options)
				if res.status ~= 200 then
					vim.notify("TaskNotes API error (GET " .. endpoint .. "): " .. res.status, vim.log.levels.ERROR)
					return nil
				end
				return vim.fn.json_decode(res.body)
			end
		end

		function M.api.post(endpoint, body)
			return M.api.request("POST", endpoint, body)
		end

		function M.api.get(endpoint, params)
			return M.api.request("GET", endpoint, params)
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
		-- UTILITY FUNCTIONS
		-- ─────────────────────────────────────────────────────────────────

		-- Returns ISO 8601 timestamp with -03:00 offset
		local function get_timestamp()
			return os.date("!%Y-%m-%dT%H:%M:%S") .. "-03:00"
		end

		-- Returns date string YYYY-MM-DD, offset_days from today
		local function get_date(offset_days)
			offset_days = offset_days or 0
			return os.date("%Y-%m-%d", os.time() + (offset_days * 86400))
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

		-- Forces a complete cache rebuild regardless of TTL
		M.cache_ops.force_refresh = function()
			M.cache.data = {}
			M.cache.keys_index = {}
			M.cache.last_full_scan = 0
			ensure_cache()
			vim.notify("TaskNotes: cache force-refreshed", vim.log.levels.INFO)
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

				local status_rank = 99
				for i, s in ipairs(M.config.statuses) do
					if s == status_val then
						status_rank = i
						break
					end
				end

				local priority_rank = 99
				for i, p in ipairs(M.config.priorities) do
					if p == priority_val then
						priority_rank = #M.config.priorities - i + 1
						break
					end
				end

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

		-- Creates a new task file with frontmatter template using NLP API
		M.task_ops.create_task = function()
			vim.ui.input({ prompt = "Quick Add (NLP): " }, function(input)
				if not input or input == "" then
					return
				end

				local res = M.api.post("/nlp/parse", { text = input })
				if not res or not res.success or not res.data then
					return
				end

				local nlp = res.data.taskData or {}
				local title = nlp.title or input
				local filename = create_filename(title)
				local filepath = M.config.vault_path .. "/" .. M.config.tasks_folder .. "/" .. filename

				-- Ensure directory exists
				vim.fn.mkdir(M.config.vault_path .. "/" .. M.config.tasks_folder, "p")

				local metadata = {
					status = nlp.status or M.config.default_status,
					priority = nlp.priority or M.config.default_priority,
					scheduled = nlp.scheduled or get_date(0),
					tags = nlp.tags or { "task" },
					projects = nlp.projects or {},
					contexts = nlp.contexts or {},
					dateCreated = get_timestamp(),
					dateModified = get_timestamp(),
				}

				-- If tags doesn't have 'task', add it
				local has_task_tag = false
				for _, t in ipairs(metadata.tags) do
					if t == "task" then
						has_task_tag = true
						break
					end
				end
				if not has_task_tag then
					table.insert(metadata.tags, "task")
				end

				if write_frontmatter(filepath, metadata, "") then
					vim.cmd("edit " .. vim.fn.fnameescape(filepath))
					vim.notify("Created task: " .. title, vim.log.levels.INFO)
					invalidate_file(filepath)
				else
					vim.notify("Failed to create task", vim.log.levels.ERROR)
				end
			end)
		end

		-- Cycles the status field on the current TaskNotes file
		M.task_ops.cycle_status = function()
			local filepath = vim.fn.expand("%:p")
			local vault = M.config.vault_path
			-- Looser check: must be a markdown file within the vault
			if not (filepath:match("%.md$") and filepath:find(vim.pesc(vault), 1, true)) then
				vim.notify("Not a TaskNotes file (outside vault or not .md)", vim.log.levels.WARN)
				return
			end

			local metadata = parse_frontmatter(filepath)
			if not metadata then
				vim.notify("No frontmatter found", vim.log.levels.ERROR)
				return
			end

			vim.ui.select(M.config.statuses, {
				prompt = "Select Status:",
				format_item = function(item)
					return item:gsub("^%l", string.upper)
				end,
			}, function(choice)
				if not choice then return end

				metadata.status = choice
				metadata.dateModified = get_timestamp()

				-- Auto-set completedDate when marking done
				if metadata.status == "done" and not metadata.completedDate then
					metadata.completedDate = get_date(0)
				end

				local body = extract_body(filepath)
				if write_frontmatter(filepath, metadata, body) then
					vim.notify("Status set to: " .. metadata.status, vim.log.levels.INFO)
					vim.cmd("edit!")
					invalidate_file(filepath)
				end
			end)
		end

		-- Cycles the priority field on the current TaskNotes file
		M.task_ops.cycle_priority = function()
			local filepath = vim.fn.expand("%:p")
			local vault = M.config.vault_path
			if not (filepath:match("%.md$") and filepath:find(vim.pesc(vault), 1, true)) then
				vim.notify("Not a TaskNotes file", vim.log.levels.WARN)
				return
			end

			local metadata = parse_frontmatter(filepath)
			if not metadata then
				vim.notify("No frontmatter found", vim.log.levels.ERROR)
				return
			end

			vim.ui.select(M.config.priorities, {
				prompt = "Select Priority:",
				format_item = function(item)
					return item:gsub("^%l", string.upper)
				end,
			}, function(choice)
				if not choice then return end

				metadata.priority = choice
				metadata.dateModified = get_timestamp()

				local body = extract_body(filepath)
				if write_frontmatter(filepath, metadata, body) then
					vim.notify("Priority set to: " .. metadata.priority, vim.log.levels.INFO)
					vim.cmd("edit!")
					invalidate_file(filepath)
				end
			end)
		end

		-- Adds a context tag to the current TaskNotes file
		M.task_ops.add_context = function(context)
			local filepath = vim.fn.expand("%:p")
			if not filepath:match("TaskNotes/Tasks") then
				vim.notify("Not a TaskNotes file", vim.log.levels.WARN)
				return
			end

			local metadata = parse_frontmatter(filepath)
			if not metadata then
				vim.notify("No frontmatter found", vim.log.levels.ERROR)
				return
			end

			-- Normalize contexts to a table
			if not metadata.contexts then
				metadata.contexts = {}
			elseif type(metadata.contexts) == "string" then
				metadata.contexts = { metadata.contexts }
			end

			-- Avoid duplicates
			for _, ctx in ipairs(metadata.contexts) do
				if ctx == context then
					vim.notify("Context already exists: " .. context, vim.log.levels.INFO)
					return
				end
			end

			table.insert(metadata.contexts, context)
			metadata.dateModified = get_timestamp()

			local body = extract_body(filepath)
			if write_frontmatter(filepath, metadata, body) then
				vim.notify("Added context: " .. context, vim.log.levels.INFO)
				vim.cmd("edit!")
				invalidate_file(filepath)
			end
		end

		-- Sets the scheduled date on the current TaskNotes file
		M.task_ops.set_scheduled = function(offset_days)
			local filepath = vim.fn.expand("%:p")
			if not filepath:match("TaskNotes/Tasks") then
				vim.notify("Not a TaskNotes file", vim.log.levels.WARN)
				return
			end

			local metadata = parse_frontmatter(filepath)
			if not metadata then
				vim.notify("No frontmatter found", vim.log.levels.ERROR)
				return
			end

			metadata.scheduled = get_date(offset_days)
			metadata.dateModified = get_timestamp()

			local body = extract_body(filepath)
			if write_frontmatter(filepath, metadata, body) then
				vim.notify("Scheduled: " .. metadata.scheduled, vim.log.levels.INFO)
				vim.cmd("edit!")
				invalidate_file(filepath)
			end
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

				if query.scheduled_before and metadata.scheduled then
					if metadata.scheduled > query.scheduled_before then
						return false
					end
				end
				if query.scheduled_after and metadata.scheduled then
					if metadata.scheduled < query.scheduled_after then
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
					for _, t in ipairs(all_tasks) do
						if final_filter(t.frontmatter or {}) then
							table.insert(tasks, t)
						end
					end
				else
					tasks = all_tasks
				end
			end

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

				local status_rank = 99
				for i, s in ipairs(M.config.statuses) do
					if s == status_val then
						status_rank = i
						break
					end
				end

				local priority_rank = 99
				for i, p in ipairs(M.config.priorities) do
					if p == priority_val then
						priority_rank = #M.config.priorities - i + 1
						break
					end
				end

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

		-- Interactive query builder (preserved from legacy)
		M.query_tasks = function()
			local query = {}

			vim.ui.input({ prompt = "Filter by status (comma-separated, or empty for all): " }, function(status_input)
				if not status_input then
					return
				end
				if status_input ~= "" then
					query.status = {}
					for s in status_input:gmatch("[^,]+") do
						table.insert(query.status, vim.trim(s))
					end
				end

				vim.ui.input(
					{ prompt = "Filter by priority (comma-separated, or empty for all): " },
					function(priority_input)
						if not priority_input then
							return
						end
						if priority_input ~= "" then
							query.priority = {}
							for p in priority_input:gmatch("[^,]+") do
								table.insert(query.priority, vim.trim(p))
							end
						end

						vim.ui.input(
							{ prompt = "Filter by context (comma-separated, or empty for all): " },
							function(context_input)
								if not context_input then
									return
								end
								if context_input ~= "" then
									query.contexts = {}
									for c in context_input:gmatch("[^,]+") do
										table.insert(query.contexts, vim.trim(c))
									end
								end

								vim.ui.input(
									{ prompt = "Scheduled after (YYYY-MM-DD, or empty): " },
									function(after_date)
										if not after_date then
											return
										end
										if after_date ~= "" then
											query.scheduled_after = after_date
										end

										vim.ui.input(
											{ prompt = "Scheduled before (YYYY-MM-DD, or empty): " },
											function(before_date)
												if not before_date then
													return
												end
												if before_date ~= "" then
													query.scheduled_before = before_date
												end

												local filter = M.build_query_filter(query)
												M.find_tasks(filter)
											end
										)
									end
								)
							end
						)
					end
				)
			end)
		end

		-- ─────────────────────────────────────────────────────────────────
		-- STEP 10: Keybindings
		--
		-- Prefix allocation:
		--   <leader>w* — Zettelkasten search (new)
		--     Note: <leader>z (single key) = Snacks Zen Mode — multi-key
		--     sequences like <leader>zs are distinct and do not conflict.
		--   <leader>z* — Task/Note management (Z = Zettel/Task management)
		--     Note: <leader>t is occupied by Snacks pickers and Harpoon.
		--     <leader>n is occupied by Colemak window navigation.
		-- ─────────────────────────────────────────────────────────────────

		-- <leader>ow* — Zettelkasten search & Task Management
		vim.keymap.set(
			"n",
			"<leader>owt",
			M.picker.pick_key,
			{ desc = "Search By Key" }
		)
		vim.keymap.set("n", "<leader>owr", M.cache_ops.force_refresh, { desc = "Force cache rebuild" })
		vim.keymap.set("n", "<leader>ows", M.picker.pick_file_by_status, { desc = "Filter by status" })
		vim.keymap.set("n", "<leader>owo", M.picker.pick_file_by_tag, { desc = "Filter by tag/project" })

		-- <leader>owk* — Task management (Unified)
		vim.keymap.set("n", "<leader>owkn", M.task_ops.create_task, { desc = "Task: New" })
		vim.keymap.set("n", "<leader>owks", M.task_ops.cycle_status, { desc = "Task: Cycle Status" })
		vim.keymap.set("n", "<leader>owkp", M.task_ops.cycle_priority, { desc = "Task: Cycle Priority" })
		vim.keymap.set("n", "<leader>owkt", function()
			vim.ui.input({ prompt = "Context: " }, function(context)
				if context and context ~= "" then
					M.task_ops.add_context(context)
				end
			end)
		end, { desc = "Task: Add custom context" })

		-- <leader>owkd* — Date scheduling
		vim.keymap.set("n", "<leader>owkdt", function()
			M.task_ops.set_scheduled(0)
		end, { desc = "Task: Schedule for today" })
		vim.keymap.set("n", "<leader>owkdm", function()
			M.task_ops.set_scheduled(1)
		end, { desc = "Task: Schedule for tomorrow" })
		vim.keymap.set("n", "<leader>owkdw", function()
			M.task_ops.set_scheduled(7)
		end, { desc = "Task: Schedule for next week" })
		vim.keymap.set("n", "<leader>owkdd", function()
			vim.ui.input({ prompt = "Days from now: " }, function(days)
				if days and days ~= "" then
					M.task_ops.set_scheduled(tonumber(days) or 0)
				end
			end)
		end, { desc = "Task: Schedule custom date" })

		-- <leader>owq* — Smart Queries
		vim.keymap.set("n", "<leader>owqq", M.query_tasks, { desc = "Task: Query (custom filter)" })
		vim.keymap.set("n", "<leader>owqh", function()
			local filter = M.build_query_filter({ status = { "open", "in-progress" }, priority = { "high" } })
			M.find_tasks(filter)
		end, { desc = "Task: Query High priority active" })

		vim.keymap.set("n", "<leader>owqt", function()
			local today = get_date(0)
			local filter = M.build_query_filter({ scheduled_before = today, scheduled_after = today })
			M.find_tasks(filter)
		end, { desc = "Task: Query Scheduled today" })

		vim.keymap.set("n", "<leader>owqo", function()
			local today = get_date(0)
			local filter = function(m)
				local s = m.status
				if type(s) == "table" then
					s = s[1]
				end
				if s == "done" or s == "archive" then
					return false
				end
				if not m.scheduled then
					return false
				end
				return m.scheduled < today
			end
			M.find_tasks(filter)
		end, { desc = "Task: Query Overdue" })
	end, -- end config
}
