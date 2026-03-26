# TaskNotes Helper for Neovim

Complete guide to using TaskNotes integration in Neovim with your Obsidian workflow.

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Keybindings Reference](#keybindings-reference)
4. [Core Features](#core-features)
5. [Workflows](#workflows)
6. [Task File Format](#task-file-format)
7. [Integration with Obsidian](#integration-with-obsidian)
8. [Tips & Tricks](#tips--tricks)
9. [Custom Query System](#8-custom-query-system)

---

## Overview

TaskNotes is a note-based task management system integrated with your Zettelkasten. This Neovim plugin provides fast task creation and management while maintaining full compatibility with the Obsidian TaskNotes plugin.

### What You Can Do in Neovim

✅ Create tasks with templates
✅ Update status and priority
✅ Add contexts (work, freelance, study)
✅ Schedule tasks with dates
✅ Find and filter tasks
✅ View tasks by context or status

### What Stays in Obsidian

🍅 Pomodoro timer
📅 Calendar view
📊 Time tracking analytics
🔍 Complex queries and automations

---

## Quick Start

### Creating Your First Task

1. Press `<leader>tn` (space + t + n)
2. Type your task title: "Complete project documentation"
3. Press Enter
4. File opens automatically in `TaskNotes/Tasks/`

### Managing the Task

- **Change status**: `<leader>ts` (cycles: open → in-progress → done)
- **Set priority**: `<leader>tp` (cycles: normal → high → low → none)
- **Add context**: `<leader>tcw` (adds "work" context)
- **Schedule**: `<leader>tdt` (schedule for today)

### Finding Tasks

- **All tasks**: `<leader>tf`
- **Todo items**: `<leader>tvt`
- **Work tasks**: `<leader>tvw`

---

## Keybindings Reference

All keybindings use the `<leader>t` prefix. Press `<leader>` (space) and wait to see which-key suggestions.

### Task Management

| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>tn` | **New Task** | Create a new task with prompt |
| `<leader>ts` | **Cycle Status** | Change task status (none → open → in-progress → on-hold → done → archive) |
| `<leader>tp` | **Cycle Priority** | Change priority (none → low → normal → high) |

### Context Management

| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>tcw` | **Add Work** | Add "work" context |
| `<leader>tcf` | **Add Freelance** | Add "freelance" context |
| `<leader>tcs` | **Add Study** | Add "study" context |
| `<leader>tcc` | **Custom Context** | Add custom context (prompts) |

### Date Scheduling

| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>tdt` | **Today** | Schedule for today |
| `<leader>tdm` | **Tomorrow** | Schedule for tomorrow |
| `<leader>tdw` | **Next Week** | Schedule for 7 days from now |
| `<leader>tdd` | **Custom Date** | Custom offset (prompts for days) |

### Task Finder & Views

| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>tvf` | **Find Tasks** | Show all tasks in picker |
| `<leader>tvi` | **Inbox** | View tasks with status: none |
| `<leader>tvt` | **Todo** | View open and in-progress tasks |
| `<leader>tvw` | **Work** | View tasks with "work" context |
| `<leader>tvfw` | **Freelance** | View tasks with "freelance" context |
| `<leader>tvd` | **Done** | View completed tasks |

### Custom Queries

| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>tq` | **Query Tasks** | Interactive query builder (filter by multiple criteria) |
| `<leader>tqh` | **High Priority** | High priority active tasks (open/in-progress + high) |
| `<leader>tqt` | **Today** | Tasks scheduled for today |
| `<leader>tqo` | **Overdue** | Overdue tasks (scheduled before today, not done) |

---

## Core Features

### 1. Task Creation

Creates a new task file with proper TaskNotes format.

**Usage:**
```
<leader>tn
```

**What happens:**
1. Prompts for task title
2. Creates file: `~/Documents/Zettelkasten/TaskNotes/Tasks/{timestamp}-{title}.md`
3. Generates YAML frontmatter with defaults:
   - Status: `open`
   - Priority: `normal`
   - Scheduled: Today's date
   - Tags: `[task]`
   - Timestamps: `dateCreated`, `dateModified`

**Example:**
```
Press: <leader>tn
Type: "Fix API endpoint bug"
Result: File created and opened for editing
```

### 2. Status Cycling

Quickly update task status through the workflow.

**Usage:**
```
<leader>ts
```

**Status Workflow:**
```
none → open → in-progress → on-hold → done → archive → (back to none)
```

**Special behavior:**
- When marked as `done`, automatically adds `completedDate`
- Updates `dateModified` on every change
- Works only in TaskNotes files

### 3. Priority Management

Cycle through priority levels.

**Usage:**
```
<leader>tp
```

**Priority Levels:**
```
none → low → normal → high → (back to none)
```

**Priority colors in Obsidian:**
- **High**: 🔴 Red
- **Normal**: 🟡 Yellow
- **Low**: 🟢 Green
- **None**: ⚪ Gray

### 4. Context Tags

Add context tags to categorize tasks.

**Built-in contexts:**
- `work` - Work-related tasks
- `freelance` - Freelance projects
- `study` - Learning and study tasks

**Usage:**
```
<leader>tcw  # Add work
<leader>tcf  # Add freelance
<leader>tcs  # Add study
<leader>tcc  # Custom (prompts)
```

**Multiple contexts:**
Tasks can have multiple contexts. They're stored as an array in frontmatter.

### 5. Date Scheduling

Set when you plan to work on the task.

**Quick dates:**
```
<leader>tdt  # Today (offset: 0 days)
<leader>tdm  # Tomorrow (offset: +1 day)
<leader>tdw  # Next week (offset: +7 days)
```

**Custom dates:**
```
<leader>tdd
Enter offset: 14
Result: Scheduled 14 days from now
```

**Date format:** `YYYY-MM-DD` (ISO 8601)

### 6. Task Finder (Snacks Picker)

Fuzzy find and filter tasks with visual picker.

**Basic finder:**
```
<leader>tf
```

**Display format:**
```
[status] [priority] Title

Example:
[open] [high] Fix API endpoint bug
[in-progress] [normal] Write documentation
[done] [low] Update README
```

**Navigation:**
- Type to filter
- `Enter` to open task
- `Esc` to cancel

### 7. Task Views (Filtered Lists)

Pre-configured filters for common task views.

**Inbox** (`<leader>tvi`):
```
Shows: status = "none"
Use for: New tasks to process
```

**Todo** (`<leader>tvt`):
```
Shows: status = "open" OR "in-progress"
Use for: Active work items
```

**Work** (`<leader>tvw`):
```
Shows: contexts contains "work"
Use for: Work-related tasks only
```

**Freelance** (`<leader>tvfw`):
```
Shows: contexts contains "freelance"
Use for: Client projects
```

**Done** (`<leader>tvd`):
```
Shows: status = "done"
Use for: Completed tasks review
```

### 8. Custom Query System

Advanced filtering to find tasks by multiple criteria simultaneously.

**Interactive Query Builder** (`<leader>tq`):
```
Prompts for:
1. Status (comma-separated): "open, in-progress"
2. Priority (comma-separated): "high, normal"
3. Context (comma-separated): "work, freelance"
4. Scheduled after (YYYY-MM-DD): "2025-10-01"
5. Scheduled before (YYYY-MM-DD): "2025-10-31"

Leave any field empty to skip filtering by that criteria.
```

**Example Queries:**
```
Query: High priority work tasks due this week
- Status: open, in-progress
- Priority: high
- Context: work
- After: 2025-10-02
- Before: 2025-10-09

Query: All freelance tasks (any status/priority)
- Status: (empty)
- Priority: (empty)
- Context: freelance
- After: (empty)
- Before: (empty)
```

**Predefined Query Shortcuts:**

**High Priority Active** (`<leader>tqh`):
```
Shows: status = "open" OR "in-progress" AND priority = "high"
Use for: Urgent tasks requiring immediate attention
```

**Today** (`<leader>tqt`):
```
Shows: scheduled = today's date
Use for: Tasks planned for today
```

**Overdue** (`<leader>tqo`):
```
Shows: scheduled < today AND status != "done" AND status != "archive"
Use for: Tasks that missed their scheduled date
```

---

## Workflows

### Workflow 1: Inbox Processing

**GTD-style task processing:**

1. Create tasks quickly: `<leader>tn`
2. Review inbox: `<leader>tvi`
3. For each task:
   - Set status: `<leader>ts` → "open"
   - Set priority: `<leader>tp`
   - Add context: `<leader>tcw/f/s`
   - Schedule: `<leader>tdt/m/w`

### Workflow 2: Daily Planning

**Morning routine:**

1. Open todo view: `<leader>tvt`
2. Select today's tasks
3. Update status to "in-progress": `<leader>ts`
4. Use Obsidian pomodoro for time tracking

### Workflow 3: Context Switching

**Switching between work modes:**

**Start work:**
```
<leader>tvw  # View work tasks
Select task
<leader>ts   # Mark in-progress
```

**Switch to freelance:**
```
<leader>tvf  # View freelance tasks
Select task
<leader>ts   # Mark in-progress
```

**Study time:**
```
<leader>tvs  # View study tasks
Select task
<leader>ts   # Mark in-progress
```

### Workflow 4: Project-Based Tasks

**Creating tasks for a project:**

1. Open project note
2. Create task: `<leader>tn`
3. In Obsidian: Link task to project note
4. Add project-specific context

### Workflow 5: Custom Queries for Advanced Filtering

**Finding specific task combinations:**

**Morning priority review:**
```
<leader>tqh  # View high priority active tasks
Review and start top priority items
```

**Weekly planning:**
```
<leader>tq
- Status: open, in-progress
- Priority: (empty)
- Context: work
- After: 2025-10-07  # Next Monday
- Before: 2025-10-13  # Next Sunday

Plan work tasks for the upcoming week
```

**Context-specific overdue review:**
```
<leader>tq
- Status: open, in-progress, on-hold
- Priority: (empty)
- Context: freelance
- After: (empty)
- Before: 2025-10-01  # Yesterday

Find overdue freelance tasks to reschedule
```

**Multi-context active tasks:**
```
<leader>tq
- Status: in-progress
- Priority: (empty)
- Context: work, freelance
- After: (empty)
- Before: (empty)

See all currently active tasks across work and freelance
```

---

## Task File Format

TaskNotes uses YAML frontmatter for metadata.

### Basic Structure

```markdown
---
status: open
priority: normal
scheduled: 2025-10-02
tags:
  - task
contexts:
  - work
dateCreated: 2025-10-02T14:30:00-03:00
dateModified: 2025-10-02T15:45:00-03:00
---

Optional task notes and details go here.
You can add any markdown content.

## Subtasks
- [ ] Research options
- [ ] Write implementation
- [ ] Test thoroughly
```

### Metadata Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `status` | string | Current workflow state | `open`, `in-progress`, `done` |
| `priority` | string | Task priority level | `none`, `low`, `normal`, `high` |
| `scheduled` | date | When to work on it | `2025-10-02` |
| `due` | date | Deadline (optional) | `2025-10-15` |
| `contexts` | array | Category tags | `[work, urgent]` |
| `projects` | array | Related project links | `["[[Project Name]]"]` |
| `tags` | array | System tags | `[task]` |
| `dateCreated` | timestamp | Creation time | `2025-10-02T14:30:00-03:00` |
| `dateModified` | timestamp | Last update time | `2025-10-02T15:45:00-03:00` |
| `completedDate` | date | When marked done | `2025-10-03` |
| `timeEntries` | array | Pomodoro sessions (Obsidian) | See below |

### Time Entries (Managed by Obsidian)

```yaml
timeEntries:
  - startTime: 2025-10-02T14:30:00-03:00
    description: Work session
    endTime: 2025-10-02T14:55:00-03:00
```

**Note:** Time tracking is managed by Obsidian's pomodoro timer. Don't edit manually.

### Filename Format

```
{timestamp}-{title-slug}.md

Example:
1696262400-fix-api-endpoint-bug.md
```

**Components:**
- `timestamp`: Unix timestamp (10 digits)
- `title-slug`: Lowercase, hyphenated, alphanumeric only

---

## Integration with Obsidian

### How It Works

**Shared Storage:**
- Both Neovim and Obsidian read/write the same files
- Changes in one appear immediately in the other
- No sync required - direct file system access

### What to Do Where

| Task | Neovim | Obsidian |
|------|--------|----------|
| Quick task creation | ✅ Faster | ⚪ GUI |
| Status updates | ✅ Keybindings | ⚪ Click |
| Priority changes | ✅ Quick cycle | ⚪ Dropdown |
| Context tagging | ✅ Fast add | ⚪ Autocomplete |
| Scheduling | ✅ Quick dates | ✅ Calendar picker |
| Finding tasks | ✅ Fuzzy search | ✅ Views & queries |
| Pomodoro timer | ❌ N/A | ✅ Built-in |
| Time tracking | ❌ N/A | ✅ Automatic |
| Calendar view | ❌ N/A | ✅ Visual |
| Analytics | ❌ N/A | ✅ Charts |

### Best Practices

**Use Neovim for:**
- Creating tasks during coding sessions
- Quick status updates
- Batch processing (inbox → todo)
- Keyboard-driven workflows

**Use Obsidian for:**
- Time tracking with pomodoro
- Reviewing task history
- Complex queries and filtering
- Visual calendar planning
- Linking tasks to notes

### Keeping in Sync

**No action needed!** Both tools work on the same files.

**Tips:**
- If editing in both simultaneously, save frequently
- Neovim auto-reloads files (`:edit!` or just reopen)
- Obsidian watches for file changes automatically

---

## Tips & Tricks

### 1. Rapid Inbox Processing

**Use keyboard shortcuts:**
```
<leader>tvi    # Open inbox
j/k           # Navigate tasks (Colemak: e/u)
<Enter>       # Open task
<leader>ts    # Set status
<leader>tp    # Set priority
<leader>tcw   # Add context
<leader>tdt   # Schedule today
:wq           # Save and close
```

Repeat for each task in inbox.

### 2. Morning Review Routine

**Check what's scheduled for today:**
```
1. <leader>tf           # Open all tasks
2. Look for today's date in scheduled column
3. Open each task
4. <leader>ts → "in-progress"
```

**Or use Obsidian's calendar view** for visual planning.

### 3. Context-Based Time Blocking

**Dedicate time blocks to contexts:**

```
Morning (9-12): Work tasks
<leader>tvw

Afternoon (13-17): Freelance
<leader>tvf

Evening (19-21): Study
<leader>tvs (if created)
```

### 4. Custom Context Creation

**Create contexts for anything:**

```
<leader>tcc
Enter: "urgent"        → Urgent tasks
Enter: "waiting"       → Blocked tasks
Enter: "someday"       → Future ideas
Enter: "personal"      → Personal tasks
```

### 5. Quick Status Transitions

**Keyboard-driven status workflow:**

```
Create:        <leader>tn
Process:       <leader>ts → "open"
Start:         <leader>ts → "in-progress"
Pause:         <leader>ts → "on-hold"
Complete:      <leader>ts → "done"
Archive:       <leader>ts → "archive"
```

### 6. Integration with Coding Workflow

**Create task from TODO comment:**

1. See `// TODO: Fix memory leak` in code
2. Press `<leader>tn`
3. Type: "Fix memory leak in UserService"
4. Add context: `<leader>tcw` (work)
5. Continue coding

### 7. Weekly Review

**Review completed tasks:**

```
<leader>tvd    # View done tasks
```

**Check what's due:**
- Use Obsidian calendar view
- Or check `due` field in task files

### 8. Project Linking

**In Obsidian:**
1. Create project note: `Project - Website Redesign`
2. Create task in Neovim: `<leader>tn` → "Design homepage mockup"
3. In Obsidian: Add `projects: ["[[Project - Website Redesign]]"]`

**Now:**
- Task shows in project note backlinks
- Project context visible in task

### 9. Bulk Operations

**Need to update multiple tasks?**

Use Vim's power:
```bash
# Find all tasks with "work" context
:Grep contexts.*work TaskNotes/Tasks

# Or use shell
cd ~/Documents/Zettelkasten/TaskNotes/Tasks
grep -l "contexts.*work" *.md

# Edit multiple files
:args *.md
:argdo %s/priority: low/priority: normal/g | update
```

### 10. Backup and Export

**Your tasks are just markdown files!**

```bash
# Backup
cp -r ~/Documents/Zettelkasten/TaskNotes ~/Backups/

# Version control
cd ~/Documents/Zettelkasten
git add TaskNotes/
git commit -m "Update tasks"

# Export to plain text
cd TaskNotes/Tasks
cat *.md > all-tasks.txt
```

### 11. Power User Query Tips

**Combine queries for powerful filters:**

```
# Find stale tasks (on-hold, scheduled long ago)
<leader>tq
Status: on-hold
Before: 2025-09-01

# High priority tasks for specific contexts
<leader>tq
Priority: high
Context: work, urgent

# Review tasks scheduled for date range
<leader>tq
After: 2025-10-01
Before: 2025-10-31
```

**Quick daily queries:**
```
Morning: <leader>tqt    # What's scheduled today?
         <leader>tqo    # What's overdue?
         <leader>tqh    # What's high priority?

Evening: <leader>tvd    # What did I complete?
```

**Programmatic queries (advanced):**

You can create custom keybindings in `lua/plugins/tasknotes.lua`:

```lua
-- Example: Urgent work tasks
vim.keymap.set("n", "<leader>tqu", function()
  local filter = M.build_query_filter({
    status = {"open", "in-progress"},
    priority = {"high"},
    contexts = {"work", "urgent"}
  })
  M.find_tasks(filter)
end, { desc = "Query: Urgent work tasks" })
```

---

## Troubleshooting

### Task Not Recognized

**Problem:** Status/priority cycling doesn't work

**Solution:** Check that:
1. File is in `TaskNotes/Tasks/` directory
2. File has YAML frontmatter with `---` delimiters
3. File path contains "TaskNotes/Tasks"

### Snacks Picker Not Opening

**Problem:** `<leader>tf` does nothing

**Solution:**
1. Check Snacks is enabled: `:checkhealth snacks`
2. Ensure `picker = { enabled = true }` in snacks config
3. Try `:lua Snacks.picker.files()` to test picker

### Dates Not Updating

**Problem:** Scheduled date doesn't change

**Solution:**
1. Save file after edit: `:w`
2. Reload file: `:edit!`
3. Check file permissions in `TaskNotes/Tasks/`

### Context Not Adding

**Problem:** Context doesn't appear in frontmatter

**Solution:**
1. Ensure `contexts:` field exists (even if empty)
2. Check YAML syntax is valid
3. Try adding manually first, then use helper

---

## Advanced Configuration

### Customizing Defaults

Edit `lua/plugins/tasknotes.lua` and modify `M.config`:

```lua
M.config = {
  vault_path = vim.fn.expand("~/Documents/Zettelkasten"),
  tasks_folder = "TaskNotes/Tasks",
  default_status = "open",      -- Change to "none" for inbox
  default_priority = "normal",   -- Change to "none"
  statuses = { "none", "open", "in-progress", "on-hold", "done", "archive" },
  priorities = { "none", "low", "normal", "high" },
}
```

### Adding Custom Views

Add a new filter in `lua/plugins/tasknotes.lua`:

```lua
-- View urgent tasks (high priority + open status)
vim.keymap.set("n", "<leader>tvu", function()
  M.find_tasks(function(m)
    return m.priority == "high" and m.status == "open"
  end)
end, { desc = "View Urgent tasks" })
```

### Custom Contexts

Create shortcuts for your own contexts:

```lua
-- Add "personal" context
vim.keymap.set("n", "<leader>tcp", function()
  M.add_context("personal")
end, { desc = "Add 'personal' context" })
```

---

## FAQ

**Q: Can I use this without Obsidian?**
A: Yes! TaskNotes helper works standalone. You'll miss pomodoro/calendar features, but task management works fine.

**Q: What if I delete a task in Neovim?**
A: It's gone from Obsidian too (same file). Use status "archive" instead of deleting.

**Q: Can I change the tasks folder location?**
A: Yes, edit `tasks_folder` in `M.config` (lua/plugins/tasknotes.lua).

**Q: Do I need the Obsidian TaskNotes plugin?**
A: No, but you'll get pomodoro, calendar, and analytics with it.

**Q: Can I use TaskNotes with other note apps?**
A: Yes! As long as they support markdown + YAML frontmatter.

---

## Resources

- **TaskNotes Obsidian Plugin**: https://github.com/callumalpass/obsidian-task-notes
- **Your Config**: `~/.config/konfig/nvim/lua/plugins/tasknotes.lua`
- **Tasks Location**: `~/Documents/Zettelkasten/TaskNotes/Tasks/`
- **Obsidian Vault**: `~/Documents/Zettelkasten/`

---

## Support

**Issues with TaskNotes helper:**
- Check config: `~/.config/konfig/nvim/lua/plugins/tasknotes.lua`
- Review this documentation
- Check Neovim health: `:checkhealth`

**Issues with Obsidian integration:**
- Verify file format matches TaskNotes spec
- Check Obsidian plugin settings
- Ensure file paths are correct

---

*Last updated: 2025-10-02*
*Compatible with: Neovim 0.10+, Obsidian TaskNotes v3.24.5+*
