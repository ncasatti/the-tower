-- TaskNotes v2 — Multi-stage Telescope search + task management
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
--   M.telescope.*   — 3-stage Telescope pickers (Key → Value → File)
--   M.task_ops.*    — Task CRUD operations (ported from legacy)
--   Keybindings     — <leader>z* (search) + <leader>w* (task management)

return {
    -- This is a standalone plugin spec.
    -- It depends on telescope and plenary which are already installed.
    dir = "/home/ncasatti/.the-grid/the-tower/nvim/lua/plugins/writing",
    name = "tasknotes",
    event = "VeryLazy",
    dependencies = {
        "nvim-telescope/telescope.nvim",
        "nvim-lua/plenary.nvim",
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
            vault_path      = vim.fn.expand("~/Documents/Zettelkasten"),
            tasks_folder    = "TaskNotes/Tasks",
            cache_ttl       = 30, -- seconds
            default_status  = "open",
            default_priority = "normal",
            statuses        = { "none", "open", "in-progress", "on-hold", "waiting", "done", "archive" },
            priorities      = { "none", "low", "normal", "high" },
        }

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

        -- Creates a Zettelkasten-style filename from a title
        local function create_filename(title)
            local suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
            return tostring(os.time()) .. "-" .. suffix .. ".md"
        end

        -- ─────────────────────────────────────────────────────────────────
        -- STEP 3: Improved frontmatter parser
        -- Handles: scalars, YAML arrays (indented - item), inline arrays ([]),
        -- quoted strings, and gracefully skips malformed files.
        -- ─────────────────────────────────────────────────────────────────

        -- Strips surrounding single or double quotes from a string value
        local function strip_quotes(s)
            if not s then return s end
            s = vim.trim(s)
            if (s:sub(1, 1) == '"' and s:sub(-1) == '"') or
               (s:sub(1, 1) == "'" and s:sub(-1) == "'") then
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
            if not ok or not file then return nil end

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
            data           = {}, -- { [filepath] = { fm = table, mtime = number } }
            keys_index     = {}, -- { [key] = { [value] = { filepath, ... } } }
            last_full_scan = 0,
        }

        -- Scans all .md files in the vault, parsing only new/changed files
        local function scan_vault()
            local vault = M.config.vault_path
            local files = vim.fn.glob(vault .. "/**/*.md", false, true)

            for _, filepath in ipairs(files) do
                local mtime = vim.fn.getftime(filepath)
                local cached = M.cache.data[filepath]

                -- Only re-parse if file has changed since last scan
                if not cached or cached.mtime ~= mtime then
                    local fm = parse_frontmatter(filepath)
                    if fm then
                        M.cache.data[filepath] = { fm = fm, mtime = mtime }
                    else
                        -- File has no frontmatter — remove stale entry if any
                        M.cache.data[filepath] = nil
                    end
                end
            end
        end

        -- Builds the inverted index from the parsed cache data.
        -- Result: keys_index[key][value] = { filepath1, filepath2, ... }
        local function build_index()
            local index = {}

            for filepath, entry in pairs(M.cache.data) do
                for key, value in pairs(entry.fm) do
                    if not index[key] then
                        index[key] = {}
                    end

                    -- Normalize value to a list for uniform processing
                    local values
                    if type(value) == "table" then
                        values = value
                    else
                        values = { tostring(value) }
                    end

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

            M.cache.keys_index = index
        end

        -- Ensures the cache is fresh. Skips work if within TTL.
        -- On TTL expiry: runs incremental scan + rebuilds index.
        local function ensure_cache()
            local now = os.time()
            if now - M.cache.last_full_scan < M.config.cache_ttl then
                return
            end

            local t_start = vim.fn.reltime()
            scan_vault()
            build_index()
            M.cache.last_full_scan = now

            local elapsed = vim.fn.reltimestr(vim.fn.reltime(t_start))
            local file_count = 0
            for _ in pairs(M.cache.data) do file_count = file_count + 1 end
            vim.notify(
                string.format("TaskNotes: cache refreshed (%d files, %ss)", file_count, elapsed),
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
        -- STEP 5-8: Telescope pickers (3-stage drill-down)
        -- ─────────────────────────────────────────────────────────────────

        M.telescope = {}

        -- Creates the glow-based markdown previewer (mirrors telescope.lua config)
        local function make_previewer()
            local previewers = require("telescope.previewers")
            return previewers.new_termopen_previewer({
                get_command = function(entry)
                    local path = entry.path or entry.filename or entry.value
                    if path and path:match("%.md$") then
                        return { "glow", "-s", "dark", path }
                    end
                    return { "bat", "--style=numbers", "--color=always", path }
                end,
            })
        end

        -- Stage 3: Pick a file from the list matching key=value
        -- Displays relative path from vault root with optional status/priority badge.
        -- On <CR>: opens the file in a buffer.
        M.telescope.pick_file = function(key, value)
            local pickers  = require("telescope.pickers")
            local finders  = require("telescope.finders")
            local conf     = require("telescope.config").values
            local actions  = require("telescope.actions")
            local action_state = require("telescope.actions.state")

            local filepaths = M.cache.keys_index[key] and M.cache.keys_index[key][value]
            if not filepaths or #filepaths == 0 then
                vim.notify(
                    string.format("TaskNotes: no files found for %s = %s", key, value),
                    vim.log.levels.WARN
                )
                return
            end

            local vault = M.config.vault_path
            local entries = {}
            for _, fp in ipairs(filepaths) do
                local rel = fp:gsub("^" .. vim.pesc(vault) .. "/", "")
                local fm  = M.cache.data[fp] and M.cache.data[fp].fm or {}

                -- Build optional badge: [status][priority]
                local badge = ""
                if fm.status and type(fm.status) == "string" then
                    badge = badge .. "[" .. fm.status .. "]"
                elseif fm.status and type(fm.status) == "table" and fm.status[1] then
                    badge = badge .. "[" .. fm.status[1] .. "]"
                end
                if fm.priority and type(fm.priority) == "string" then
                    badge = badge .. "[" .. fm.priority .. "]"
                end

                local display = badge ~= "" and (badge .. " " .. rel) or rel

                table.insert(entries, {
                    display  = display,
                    ordinal  = rel,
                    path     = fp,
                    filename = fp,
                })
            end

            -- Sort by display string
            table.sort(entries, function(a, b) return a.ordinal < b.ordinal end)

            pickers.new({}, {
                prompt_title = string.format("%s: %s (%d files)", key, value, #filepaths),
                finder = finders.new_table({
                    results = entries,
                    entry_maker = function(e) return e end,
                }),
                sorter   = conf.generic_sorter({}),
                previewer = make_previewer(),
                attach_mappings = function(prompt_bufnr, map)
                    actions.select_default:replace(function()
                        local selection = action_state.get_selected_entry()
                        actions.close(prompt_bufnr)
                        if selection then
                            vim.cmd("edit " .. vim.fn.fnameescape(selection.path))
                        end
                    end)
                    return true
                end,
            }):find()
        end

        -- Stage 2: Pick a value for the given key.
        -- Displays value + file count. On <CR>: transitions to Stage 3.
        M.telescope.pick_value = function(key)
            local pickers  = require("telescope.pickers")
            local finders  = require("telescope.finders")
            local conf     = require("telescope.config").values
            local actions  = require("telescope.actions")
            local action_state = require("telescope.actions.state")

            ensure_cache()

            local value_map = M.cache.keys_index[key]
            if not value_map then
                vim.notify(
                    string.format("TaskNotes: no values found for key '%s'", key),
                    vim.log.levels.WARN
                )
                return
            end

            local entries = {}
            for v, fps in pairs(value_map) do
                table.insert(entries, {
                    display = string.format("%s (%d files)", v, #fps),
                    ordinal = v,
                    value   = v,
                })
            end

            -- Sort alphabetically
            table.sort(entries, function(a, b) return a.ordinal < b.ordinal end)

            pickers.new({}, {
                prompt_title = string.format("Values for: %s", key),
                finder = finders.new_table({
                    results = entries,
                    entry_maker = function(e) return e end,
                }),
                sorter = conf.generic_sorter({}),
                attach_mappings = function(prompt_bufnr, map)
                    actions.select_default:replace(function()
                        local selection = action_state.get_selected_entry()
                        actions.close(prompt_bufnr)
                        if selection then
                            M.telescope.pick_file(key, selection.value)
                        end
                    end)
                    -- <Esc> returns to Stage 1
                    map("i", "<Esc>", function()
                        actions.close(prompt_bufnr)
                        M.telescope.pick_key()
                    end)
                    map("n", "<Esc>", function()
                        actions.close(prompt_bufnr)
                        M.telescope.pick_key()
                    end)
                    return true
                end,
            }):find()
        end

        -- Stage 1: Pick a frontmatter key from the vault index.
        -- Displays key + file count. On <CR>: transitions to Stage 2.
        M.telescope.pick_key = function()
            local pickers  = require("telescope.pickers")
            local finders  = require("telescope.finders")
            local conf     = require("telescope.config").values
            local actions  = require("telescope.actions")
            local action_state = require("telescope.actions.state")

            ensure_cache()

            local entries = {}
            for key, value_map in pairs(M.cache.keys_index) do
                -- Count unique files for this key
                local file_set = {}
                for _, fps in pairs(value_map) do
                    for _, fp in ipairs(fps) do
                        file_set[fp] = true
                    end
                end
                local file_count = 0
                for _ in pairs(file_set) do file_count = file_count + 1 end

                table.insert(entries, {
                    display = string.format("%s (%d files)", key, file_count),
                    ordinal = key,
                    value   = key,
                })
            end

            -- Sort alphabetically
            table.sort(entries, function(a, b) return a.ordinal < b.ordinal end)

            if #entries == 0 then
                vim.notify("TaskNotes: vault index is empty. Try <leader>zr to force refresh.", vim.log.levels.WARN)
                return
            end

            pickers.new({}, {
                prompt_title = "Frontmatter Key",
                finder = finders.new_table({
                    results = entries,
                    entry_maker = function(e) return e end,
                }),
                sorter = conf.generic_sorter({}),
                attach_mappings = function(prompt_bufnr, _)
                    actions.select_default:replace(function()
                        local selection = action_state.get_selected_entry()
                        actions.close(prompt_bufnr)
                        if selection then
                            M.telescope.pick_value(selection.value)
                        end
                    end)
                    return true
                end,
            }):find()
        end

        -- ─────────────────────────────────────────────────────────────────
        -- STEP 8: Shortcut pickers (skip Stage 1)
        -- ─────────────────────────────────────────────────────────────────

        -- Jumps directly to Stage 2 for the 'status' key
        M.telescope.pick_file_by_status = function()
            ensure_cache()
            M.telescope.pick_value("status")
        end

        -- Jumps directly to Stage 2 for the 'tags' key
        M.telescope.pick_file_by_tag = function()
            ensure_cache()
            M.telescope.pick_value("tags")
        end

        -- Jumps directly to Stage 2 for the 'projects' key
        M.telescope.pick_file_by_project = function()
            ensure_cache()
            M.telescope.pick_value("projects")
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
                "status", "priority", "due", "scheduled",
                "projects", "contexts", "tags",
                "dateCreated", "dateModified", "completedDate",
                "timeEntries", "recurrence", "complete_instances", "skipped_instances",
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
            for _, k in ipairs(order) do ordered_set[k] = true end

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
            if not file then return "" end
            local content = file:read("*all")
            file:close()
            -- Match content after the second ---
            local body = content:match("^%-%-%-\n.-\n%-%-%-\n\n?(.*)")
            return body or ""
        end

        -- Creates a new task file with frontmatter template
        M.task_ops.create_task = function()
            vim.ui.input({ prompt = "Task title: " }, function(title)
                if not title or title == "" then return end

                local filename = create_filename(title)
                local filepath = M.config.vault_path .. "/" .. M.config.tasks_folder .. "/" .. filename

                -- Ensure directory exists
                vim.fn.mkdir(M.config.vault_path .. "/" .. M.config.tasks_folder, "p")

                local metadata = {
                    status       = M.config.default_status,
                    priority     = M.config.default_priority,
                    scheduled    = get_date(0),
                    tags         = { "task" },
                    dateCreated  = get_timestamp(),
                    dateModified = get_timestamp(),
                }

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
            if not filepath:match("TaskNotes/Tasks") then
                vim.notify("Not a TaskNotes file", vim.log.levels.WARN)
                return
            end

            local metadata = parse_frontmatter(filepath)
            if not metadata then
                vim.notify("No frontmatter found", vim.log.levels.ERROR)
                return
            end

            -- Normalize status: may be a table (e.g. status: [done])
            local current_status
            if type(metadata.status) == "table" then
                current_status = metadata.status[1] or "none"
            else
                current_status = metadata.status or "none"
            end

            local current_idx = 1
            for i, s in ipairs(M.config.statuses) do
                if s == current_status then
                    current_idx = i
                    break
                end
            end

            local next_idx = (current_idx % #M.config.statuses) + 1
            metadata.status = M.config.statuses[next_idx]
            metadata.dateModified = get_timestamp()

            -- Auto-set completedDate when marking done
            if metadata.status == "done" and not metadata.completedDate then
                metadata.completedDate = get_date(0)
            end

            local body = extract_body(filepath)
            if write_frontmatter(filepath, metadata, body) then
                vim.notify("Status: " .. metadata.status, vim.log.levels.INFO)
                vim.cmd("edit!")
                invalidate_file(filepath)
            end
        end

        -- Cycles the priority field on the current TaskNotes file
        M.task_ops.cycle_priority = function()
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

            local current_priority = metadata.priority or "none"
            if type(current_priority) == "table" then
                current_priority = current_priority[1] or "none"
            end

            local current_idx = 1
            for i, p in ipairs(M.config.priorities) do
                if p == current_priority then
                    current_idx = i
                    break
                end
            end

            local next_idx = (current_idx % #M.config.priorities) + 1
            metadata.priority = M.config.priorities[next_idx]
            metadata.dateModified = get_timestamp()

            local body = extract_body(filepath)
            if write_frontmatter(filepath, metadata, body) then
                vim.notify("Priority: " .. metadata.priority, vim.log.levels.INFO)
                vim.cmd("edit!")
                invalidate_file(filepath)
            end
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
                    if type(status_val) == "table" then status_val = status_val[1] end
                    local match = false
                    for _, s in ipairs(query.status) do
                        if status_val == s then match = true; break end
                    end
                    if not match then return false end
                end

                if query.priority and #query.priority > 0 then
                    local priority_val = metadata.priority
                    if type(priority_val) == "table" then priority_val = priority_val[1] end
                    local match = false
                    for _, p in ipairs(query.priority) do
                        if priority_val == p then match = true; break end
                    end
                    if not match then return false end
                end

                if query.contexts and #query.contexts > 0 then
                    if not metadata.contexts then return false end
                    local ctx_list = metadata.contexts
                    if type(ctx_list) == "string" then ctx_list = { ctx_list } end
                    local match = false
                    for _, qc in ipairs(query.contexts) do
                        for _, mc in ipairs(ctx_list) do
                            if mc == qc then match = true; break end
                        end
                        if match then break end
                    end
                    if not match then return false end
                end

                if query.scheduled_before and metadata.scheduled then
                    if metadata.scheduled > query.scheduled_before then return false end
                end
                if query.scheduled_after and metadata.scheduled then
                    if metadata.scheduled < query.scheduled_after then return false end
                end

                return true
            end
        end

        -- Finds tasks in the tasks folder and opens a Telescope picker.
        -- Uses the new Telescope-based picker instead of vim.ui.select.
        M.find_tasks = function(filter)
            local pickers  = require("telescope.pickers")
            local finders  = require("telescope.finders")
            local conf     = require("telescope.config").values
            local actions  = require("telescope.actions")
            local action_state = require("telescope.actions.state")

            local tasks_dir = M.config.vault_path .. "/" .. M.config.tasks_folder
            local files = vim.fn.glob(tasks_dir .. "/**/*.md", false, true)

            local entries = {}
            for _, file in ipairs(files) do
                local metadata = parse_frontmatter(file)
                if metadata then
                    local include = true
                    if filter then include = filter(metadata) end

                    if include then
                        local status_val = metadata.status
                        if type(status_val) == "table" then status_val = status_val[1] end
                        local priority_val = metadata.priority
                        if type(priority_val) == "table" then priority_val = priority_val[1] end

                        local title = vim.fn.fnamemodify(file, ":t:r"):match("%d+%-(.+)")
                            or vim.fn.fnamemodify(file, ":t:r")

                        local display = string.format(
                            "[%s][%s] %s",
                            status_val or "none",
                            priority_val or "none",
                            title
                        )

                        table.insert(entries, {
                            display  = display,
                            ordinal  = display,
                            path     = file,
                            filename = file,
                        })
                    end
                end
            end

            if #entries == 0 then
                vim.notify("No tasks found", vim.log.levels.INFO)
                return
            end

            table.sort(entries, function(a, b) return a.ordinal < b.ordinal end)

            pickers.new({}, {
                prompt_title = "TaskNotes",
                finder = finders.new_table({
                    results = entries,
                    entry_maker = function(e) return e end,
                }),
                sorter    = conf.generic_sorter({}),
                previewer = make_previewer(),
                attach_mappings = function(prompt_bufnr, _)
                    actions.select_default:replace(function()
                        local selection = action_state.get_selected_entry()
                        actions.close(prompt_bufnr)
                        if selection then
                            vim.cmd("edit " .. vim.fn.fnameescape(selection.path))
                        end
                    end)
                    return true
                end,
            }):find()
        end

        -- Interactive query builder (preserved from legacy)
        M.query_tasks = function()
            local query = {}

            vim.ui.input({ prompt = "Filter by status (comma-separated, or empty for all): " }, function(status_input)
                if not status_input then return end
                if status_input ~= "" then
                    query.status = {}
                    for s in status_input:gmatch("[^,]+") do
                        table.insert(query.status, vim.trim(s))
                    end
                end

                vim.ui.input({ prompt = "Filter by priority (comma-separated, or empty for all): " }, function(priority_input)
                    if not priority_input then return end
                    if priority_input ~= "" then
                        query.priority = {}
                        for p in priority_input:gmatch("[^,]+") do
                            table.insert(query.priority, vim.trim(p))
                        end
                    end

                    vim.ui.input({ prompt = "Filter by context (comma-separated, or empty for all): " }, function(context_input)
                        if not context_input then return end
                        if context_input ~= "" then
                            query.contexts = {}
                            for c in context_input:gmatch("[^,]+") do
                                table.insert(query.contexts, vim.trim(c))
                            end
                        end

                        vim.ui.input({ prompt = "Scheduled after (YYYY-MM-DD, or empty): " }, function(after_date)
                            if not after_date then return end
                            if after_date ~= "" then query.scheduled_after = after_date end

                            vim.ui.input({ prompt = "Scheduled before (YYYY-MM-DD, or empty): " }, function(before_date)
                                if not before_date then return end
                                if before_date ~= "" then query.scheduled_before = before_date end

                                local filter = M.build_query_filter(query)
                                M.find_tasks(filter)
                            end)
                        end)
                    end)
                end)
            end)
        end

        -- ─────────────────────────────────────────────────────────────────
        -- STEP 10: Keybindings
        --
        -- Prefix allocation:
        --   <leader>z* — Zettelkasten search (new)
        --     Note: <leader>z (single key) = Snacks Zen Mode — multi-key
        --     sequences like <leader>zs are distinct and do not conflict.
        --   <leader>w* — Task/Note management (W = Writing/Work tasks)
        --     Note: <leader>t is occupied by Snacks (Telescope/Test group)
        --     and Harpoon. <leader>n is occupied by Colemak window navigation.
        -- ─────────────────────────────────────────────────────────────────

        -- <leader>oz* — Zettelkasten search
        vim.keymap.set("n", "<leader>ozs", M.telescope.pick_key,
            { desc = "Zettel: Search Frontmatter (Key→Value→File)" })
        vim.keymap.set("n", "<leader>ozr", M.cache_ops.force_refresh,
            { desc = "Zettel: Force cache rebuild" })
        vim.keymap.set("n", "<leader>ozf", M.telescope.pick_file_by_status,
            { desc = "Zettel: Filter by status" })
        vim.keymap.set("n", "<leader>ozt", M.telescope.pick_file_by_tag,
            { desc = "Zettel: Filter by tag" })
        vim.keymap.set("n", "<leader>ozp", M.telescope.pick_file_by_project,
            { desc = "Zettel: Filter by project" })

        -- <leader>ow* — Task management
        vim.keymap.set("n", "<leader>own", M.task_ops.create_task,
            { desc = "Task: New" })
        vim.keymap.set("n", "<leader>ows", M.task_ops.cycle_status,
            { desc = "Task: Cycle Status" })
        vim.keymap.set("n", "<leader>owp", M.task_ops.cycle_priority,
            { desc = "Task: Cycle Priority" })

        -- Context management
        vim.keymap.set("n", "<leader>owcw", function() M.task_ops.add_context("work") end,
            { desc = "Task: Add 'work' context" })
        vim.keymap.set("n", "<leader>owcf", function() M.task_ops.add_context("freelance") end,
            { desc = "Task: Add 'freelance' context" })
        vim.keymap.set("n", "<leader>owcs", function() M.task_ops.add_context("study") end,
            { desc = "Task: Add 'study' context" })
        vim.keymap.set("n", "<leader>owcc", function()
            vim.ui.input({ prompt = "Context: " }, function(context)
                if context and context ~= "" then
                    M.task_ops.add_context(context)
                end
            end)
        end, { desc = "Task: Add custom context" })

        -- Date scheduling
        vim.keymap.set("n", "<leader>owdt", function() M.task_ops.set_scheduled(0) end,
            { desc = "Task: Schedule for today" })
        vim.keymap.set("n", "<leader>owdm", function() M.task_ops.set_scheduled(1) end,
            { desc = "Task: Schedule for tomorrow" })
        vim.keymap.set("n", "<leader>owdw", function() M.task_ops.set_scheduled(7) end,
            { desc = "Task: Schedule for next week" })
        vim.keymap.set("n", "<leader>owdd", function()
            vim.ui.input({ prompt = "Days from now: " }, function(days)
                if days and days ~= "" then
                    M.task_ops.set_scheduled(tonumber(days) or 0)
                end
            end)
        end, { desc = "Task: Schedule custom date" })

        -- Task finder and views (Telescope-based)
        vim.keymap.set("n", "<leader>owq",  M.query_tasks,
            { desc = "Task: Query (custom filter)" })
        vim.keymap.set("n", "<leader>owvf", function() M.find_tasks() end,
            { desc = "Task: Find All" })

        -- Predefined query shortcuts
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
                if type(s) == "table" then s = s[1] end
                if s == "done" or s == "archive" then return false end
                if not m.scheduled then return false end
                return m.scheduled < today
            end
            M.find_tasks(filter)
        end, { desc = "Task: Query Overdue" })

        -- View shortcuts
        vim.keymap.set("n", "<leader>owvi", function()
            M.find_tasks(function(m)
                local s = m.status
                if type(s) == "table" then s = s[1] end
                return s == "none"
            end)
        end, { desc = "Task: View Inbox (none)" })

        vim.keymap.set("n", "<leader>owvt", function()
            M.find_tasks(function(m)
                local s = m.status
                if type(s) == "table" then s = s[1] end
                return s == "open" or s == "in-progress"
            end)
        end, { desc = "Task: View Todo" })

        vim.keymap.set("n", "<leader>owvw", function()
            M.find_tasks(function(m)
                if not m.contexts then return false end
                local ctx = m.contexts
                if type(ctx) == "string" then return ctx == "work" end
                for _, c in ipairs(ctx) do
                    if c == "work" then return true end
                end
                return false
            end)
        end, { desc = "Task: View Work" })

        vim.keymap.set("n", "<leader>owvl", function()
            M.find_tasks(function(m)
                if not m.contexts then return false end
                local ctx = m.contexts
                if type(ctx) == "string" then return ctx == "freelance" end
                for _, c in ipairs(ctx) do
                    if c == "freelance" then return true end
                end
                return false
            end)
        end, { desc = "Task: View Freelance" })

        vim.keymap.set("n", "<leader>owvd", function()
            M.find_tasks(function(m)
                local s = m.status
                if type(s) == "table" then s = s[1] end
                return s == "done"
            end)
        end, { desc = "Task: View Done" })

    end, -- end config
}
