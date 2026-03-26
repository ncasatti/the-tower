return {
  "epwalsh/obsidian.nvim", -- Depends on obsidian.nvim
  optional = true,

  config = function()
    -- TaskNotes configuration
    local M = {}

    M.config = {
      vault_path = vim.fn.expand("~/Documents/Zettelkasten"),
      tasks_folder = "TaskNotes/Tasks",
      default_status = "open",
      default_priority = "normal",
      statuses = { "none", "open", "in-progress", "on-hold", "done", "archive" },
      priorities = { "none", "low", "normal", "high" },
    }

    -- Utility: Get ISO timestamp
    local function get_timestamp()
      return os.date("!%Y-%m-%dT%H:%M:%S") .. "-03:00"
    end

    -- Utility: Get date in YYYY-MM-DD format
    local function get_date(offset_days)
      offset_days = offset_days or 0
      return os.date("%Y-%m-%d", os.time() + (offset_days * 86400))
    end

    -- Utility: Create zettelkasten filename from title
    local function create_filename(title)
      local suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      return tostring(os.time()) .. "-" .. suffix .. ".md"
    end

    -- Utility: Read YAML frontmatter from file
    local function read_frontmatter(filepath)
      local file = io.open(filepath, "r")
      if not file then return nil end

      local content = file:read("*all")
      file:close()

      local frontmatter = content:match("^%s*%-%-%-\n(.-)%-%-%-")
      if not frontmatter then return nil end

      local metadata = {}
      for line in frontmatter:gmatch("[^\n]+") do
        local key, value = line:match("^([%w_]+):%s*(.+)")
        if key and value then
          metadata[key] = value
        end
      end

      return metadata, content
    end

    -- Utility: Write YAML frontmatter to file
    local function write_frontmatter(filepath, metadata, body)
      body = body or ""

      local lines = { "---" }

      -- Write metadata in specific order
      local order = { "status", "priority", "due", "scheduled", "projects", "contexts", "tags", "dateCreated", "dateModified", "timeEntries" }

      for _, key in ipairs(order) do
        if metadata[key] then
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

      -- Write any remaining metadata
      for key, value in pairs(metadata) do
        local found = false
        for _, k in ipairs(order) do
          if k == key then found = true break end
        end
        if not found then
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
      table.insert(lines, body)

      local file = io.open(filepath, "w")
      if file then
        file:write(table.concat(lines, "\n"))
        file:close()
        return true
      end
      return false
    end

    -- Create new task
    M.create_task = function()
      vim.ui.input({ prompt = "Task title: " }, function(title)
        if not title or title == "" then return end

        local filename = create_filename(title)
        local filepath = M.config.vault_path .. "/" .. M.config.tasks_folder .. "/" .. filename

        -- Ensure directory exists
        vim.fn.mkdir(M.config.vault_path .. "/" .. M.config.tasks_folder, "p")

        -- Create frontmatter
        local metadata = {
          status = M.config.default_status,
          priority = M.config.default_priority,
          scheduled = get_date(0),
          tags = { "task" },
          dateCreated = get_timestamp(),
          dateModified = get_timestamp(),
        }

        -- Write file
        if write_frontmatter(filepath, metadata, "") then
          vim.cmd("edit " .. filepath)
          vim.notify("Created task: " .. title, vim.log.levels.INFO)
        else
          vim.notify("Failed to create task", vim.log.levels.ERROR)
        end
      end)
    end

    -- Cycle status
    M.cycle_status = function()
      local filepath = vim.fn.expand("%:p")
      if not filepath:match("TaskNotes/Tasks") then
        vim.notify("Not a TaskNotes file", vim.log.levels.WARN)
        return
      end

      local metadata, body = read_frontmatter(filepath)
      if not metadata then
        vim.notify("No frontmatter found", vim.log.levels.ERROR)
        return
      end

      -- Find current status index
      local current_status = metadata.status or "none"
      local current_idx = 1
      for i, status in ipairs(M.config.statuses) do
        if status == current_status then
          current_idx = i
          break
        end
      end

      -- Cycle to next status
      local next_idx = (current_idx % #M.config.statuses) + 1
      metadata.status = M.config.statuses[next_idx]
      metadata.dateModified = get_timestamp()

      -- Add completion date if status is done
      if metadata.status == "done" and not metadata.completedDate then
        metadata.completedDate = get_date(0)
      end

      if write_frontmatter(filepath, metadata, body:match("%-%-%-\n\n(.*)") or "") then
        vim.notify("Status: " .. metadata.status, vim.log.levels.INFO)
        vim.cmd("edit!") -- Reload file
      end
    end

    -- Cycle priority
    M.cycle_priority = function()
      local filepath = vim.fn.expand("%:p")
      if not filepath:match("TaskNotes/Tasks") then
        vim.notify("Not a TaskNotes file", vim.log.levels.WARN)
        return
      end

      local metadata, body = read_frontmatter(filepath)
      if not metadata then
        vim.notify("No frontmatter found", vim.log.levels.ERROR)
        return
      end

      -- Find current priority index
      local current_priority = metadata.priority or "none"
      local current_idx = 1
      for i, priority in ipairs(M.config.priorities) do
        if priority == current_priority then
          current_idx = i
          break
        end
      end

      -- Cycle to next priority
      local next_idx = (current_idx % #M.config.priorities) + 1
      metadata.priority = M.config.priorities[next_idx]
      metadata.dateModified = get_timestamp()

      if write_frontmatter(filepath, metadata, body:match("%-%-%-\n\n(.*)") or "") then
        vim.notify("Priority: " .. metadata.priority, vim.log.levels.INFO)
        vim.cmd("edit!") -- Reload file
      end
    end

    -- Add context
    M.add_context = function(context)
      local filepath = vim.fn.expand("%:p")
      if not filepath:match("TaskNotes/Tasks") then
        vim.notify("Not a TaskNotes file", vim.log.levels.WARN)
        return
      end

      local metadata, body = read_frontmatter(filepath)
      if not metadata then
        vim.notify("No frontmatter found", vim.log.levels.ERROR)
        return
      end

      -- Initialize contexts if needed
      if not metadata.contexts then
        metadata.contexts = {}
      elseif type(metadata.contexts) == "string" then
        metadata.contexts = { metadata.contexts }
      end

      -- Add context if not already present
      local found = false
      for _, ctx in ipairs(metadata.contexts) do
        if ctx == context then found = true break end
      end

      if not found then
        table.insert(metadata.contexts, context)
        metadata.dateModified = get_timestamp()

        if write_frontmatter(filepath, metadata, body:match("%-%-%-\n\n(.*)") or "") then
          vim.notify("Added context: " .. context, vim.log.levels.INFO)
          vim.cmd("edit!") -- Reload file
        end
      else
        vim.notify("Context already exists: " .. context, vim.log.levels.INFO)
      end
    end

    -- Set scheduled date
    M.set_scheduled = function(offset_days)
      local filepath = vim.fn.expand("%:p")
      if not filepath:match("TaskNotes/Tasks") then
        vim.notify("Not a TaskNotes file", vim.log.levels.WARN)
        return
      end

      local metadata, body = read_frontmatter(filepath)
      if not metadata then
        vim.notify("No frontmatter found", vim.log.levels.ERROR)
        return
      end

      metadata.scheduled = get_date(offset_days)
      metadata.dateModified = get_timestamp()

      if write_frontmatter(filepath, metadata, body:match("%-%-%-\n\n(.*)") or "") then
        vim.notify("Scheduled: " .. metadata.scheduled, vim.log.levels.INFO)
        vim.cmd("edit!") -- Reload file
      end
    end

    -- Query builder: Create filter from query parameters
    -- Query params: { status = {}, priority = {}, contexts = {}, scheduled_before = "", scheduled_after = "" }
    M.build_query_filter = function(query)
      return function(metadata)
        -- Filter by status (if specified)
        if query.status and #query.status > 0 then
          local status_match = false
          for _, s in ipairs(query.status) do
            if metadata.status == s then
              status_match = true
              break
            end
          end
          if not status_match then return false end
        end

        -- Filter by priority (if specified)
        if query.priority and #query.priority > 0 then
          local priority_match = false
          for _, p in ipairs(query.priority) do
            if metadata.priority == p then
              priority_match = true
              break
            end
          end
          if not priority_match then return false end
        end

        -- Filter by contexts (if specified)
        if query.contexts and #query.contexts > 0 then
          if not metadata.contexts then return false end

          local contexts_list = metadata.contexts
          if type(contexts_list) == "string" then
            contexts_list = { contexts_list }
          end

          local context_match = false
          for _, qc in ipairs(query.contexts) do
            for _, mc in ipairs(contexts_list) do
              if mc == qc then
                context_match = true
                break
              end
            end
            if context_match then break end
          end
          if not context_match then return false end
        end

        -- Filter by scheduled date range
        if query.scheduled_before and metadata.scheduled then
          if metadata.scheduled > query.scheduled_before then return false end
        end
        if query.scheduled_after and metadata.scheduled then
          if metadata.scheduled < query.scheduled_after then return false end
        end

        return true
      end
    end

    -- Find tasks (vim.ui.select)
    M.find_tasks = function(filter)
      local tasks_dir = M.config.vault_path .. "/" .. M.config.tasks_folder
      local files = vim.fn.glob(tasks_dir .. "/*.md", false, true)

      local tasks = {}
      for _, file in ipairs(files) do
        local metadata = read_frontmatter(file)
        if metadata then
          -- Apply filter
          local include = true
          if filter then
            include = filter(metadata)
          end

          if include then
            local title = vim.fn.fnamemodify(file, ":t:r"):match("%d+%-(.+)") or vim.fn.fnamemodify(file, ":t:r")
            table.insert(tasks, {
              file = file,
              title = title,
              status = metadata.status or "none",
              priority = metadata.priority or "none",
              scheduled = metadata.scheduled or "",
            })
          end
        end
      end

      if #tasks == 0 then
        vim.notify("No tasks found", vim.log.levels.INFO)
        return
      end

      -- Use vim.ui.select
      vim.ui.select(tasks, {
        prompt = "TaskNotes",
        format_item = function(item)
          return string.format("[%s] [%s] %s", item.status, item.priority, item.title)
        end,
      }, function(choice)
        if choice then
          vim.cmd("edit " .. choice.file)
        end
      end)
    end

    -- Interactive query builder
    M.query_tasks = function()
      local query = {}

      -- Step 1: Select statuses (multi-select)
      vim.ui.input({
        prompt = "Filter by status (comma-separated, or empty for all): "
      }, function(status_input)
        if not status_input then return end

        if status_input ~= "" then
          query.status = {}
          for s in status_input:gmatch("[^,]+") do
            table.insert(query.status, vim.trim(s))
          end
        end

        -- Step 2: Select priorities
        vim.ui.input({
          prompt = "Filter by priority (comma-separated, or empty for all): "
        }, function(priority_input)
          if not priority_input then return end

          if priority_input ~= "" then
            query.priority = {}
            for p in priority_input:gmatch("[^,]+") do
              table.insert(query.priority, vim.trim(p))
            end
          end

          -- Step 3: Select contexts
          vim.ui.input({
            prompt = "Filter by context (comma-separated, or empty for all): "
          }, function(context_input)
            if not context_input then return end

            if context_input ~= "" then
              query.contexts = {}
              for c in context_input:gmatch("[^,]+") do
                table.insert(query.contexts, vim.trim(c))
              end
            end

            -- Step 4: Scheduled date range (optional)
            vim.ui.input({
              prompt = "Scheduled after (YYYY-MM-DD, or empty): "
            }, function(after_date)
              if not after_date then return end

              if after_date ~= "" then
                query.scheduled_after = after_date
              end

              vim.ui.input({
                prompt = "Scheduled before (YYYY-MM-DD, or empty): "
              }, function(before_date)
                if not before_date then return end

                if before_date ~= "" then
                  query.scheduled_before = before_date
                end

                -- Execute query
                local filter = M.build_query_filter(query)
                M.find_tasks(filter)
              end)
            end)
          end)
        end)
      end)
    end

    -- Keybindings
    vim.keymap.set("n", "<leader>tn", M.create_task, { desc = "New Task" })
    vim.keymap.set("n", "<leader>ts", M.cycle_status, { desc = "Cycle Task Status" })
    vim.keymap.set("n", "<leader>tp", M.cycle_priority, { desc = "Cycle Task Priority" })

    -- Context management
    vim.keymap.set("n", "<leader>tcw", function() M.add_context("work") end, { desc = "Add 'work' context" })
    vim.keymap.set("n", "<leader>tcf", function() M.add_context("freelance") end, { desc = "Add 'freelance' context" })
    vim.keymap.set("n", "<leader>tcs", function() M.add_context("study") end, { desc = "Add 'study' context" })
    vim.keymap.set("n", "<leader>tcc", function()
      vim.ui.input({ prompt = "Context: " }, function(context)
        if context and context ~= "" then
          M.add_context(context)
        end
      end)
    end, { desc = "Add custom context" })

    -- Date management
    vim.keymap.set("n", "<leader>tdt", function() M.set_scheduled(0) end, { desc = "Schedule for today" })
    vim.keymap.set("n", "<leader>tdm", function() M.set_scheduled(1) end, { desc = "Schedule for tomorrow" })
    vim.keymap.set("n", "<leader>tdw", function() M.set_scheduled(7) end, { desc = "Schedule for next week" })
    vim.keymap.set("n", "<leader>tdd", function()
      vim.ui.input({ prompt = "Days from now: " }, function(days)
        if days and days ~= "" then
          M.set_scheduled(tonumber(days) or 0)
        end
      end)
    end, { desc = "Schedule custom date" })

    -- Task finder and views
    vim.keymap.set("n", "<leader>tq", M.query_tasks, { desc = "Query Tasks (custom filter)" })
    vim.keymap.set("n", "<leader>tvf", function() M.find_tasks() end, { desc = "Find Tasks" })

    -- Predefined query shortcuts
    vim.keymap.set("n", "<leader>tqh", function()
      -- High priority, open/in-progress tasks
      local filter = M.build_query_filter({ status = {"open", "in-progress"}, priority = {"high"} })
      M.find_tasks(filter)
    end, { desc = "Query: High priority active tasks" })

    vim.keymap.set("n", "<leader>tqt", function()
      -- Tasks scheduled for today
      local today = get_date(0)
      local filter = M.build_query_filter({ scheduled_before = today, scheduled_after = today })
      M.find_tasks(filter)
    end, { desc = "Query: Tasks scheduled today" })

    vim.keymap.set("n", "<leader>tqo", function()
      -- Overdue tasks (scheduled before today, not done)
      local today = get_date(0)
      local filter = function(m)
        if m.status == "done" or m.status == "archive" then return false end
        if not m.scheduled then return false end
        return m.scheduled < today
      end
      M.find_tasks(filter)
    end, { desc = "Query: Overdue tasks" })
    vim.keymap.set("n", "<leader>tvi", function()
      M.find_tasks(function(m) return m.status == "none" end)
    end, { desc = "View Inbox (none)" })
    vim.keymap.set("n", "<leader>tvt", function()
      M.find_tasks(function(m) return m.status == "open" or m.status == "in-progress" end)
    end, { desc = "View Todo" })
    vim.keymap.set("n", "<leader>tvw", function()
      M.find_tasks(function(m)
        if not m.contexts then return false end
        if type(m.contexts) == "string" then return m.contexts == "work" end
        for _, ctx in ipairs(m.contexts) do
          if ctx == "work" then return true end
        end
        return false
      end)
    end, { desc = "View Work tasks" })
    vim.keymap.set("n", "<leader>tvfw", function()
      M.find_tasks(function(m)
        if not m.contexts then return false end
        if type(m.contexts) == "string" then return m.contexts == "freelance" end
        for _, ctx in ipairs(m.contexts) do
          if ctx == "freelance" then return true end
        end
        return false
      end)
    end, { desc = "View Freelance tasks" })
    vim.keymap.set("n", "<leader>tvd", function()
      M.find_tasks(function(m) return m.status == "done" end)
    end, { desc = "View Done tasks" })
  end,
}
