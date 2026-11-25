[← nvim docs index](../README.md)

# TaskNotes — Neovim client for the TaskNotes API

A Neovim front-end for task management, implemented as a modular Lua tree under
`lua/tasknotes/` (the lazy spec at `lua/plugins/writing/tasknotes.lua` is just an
18-line loader that calls `require("tasknotes").setup()`). It is an **HTTP client**
for the [TaskNotes](https://github.com/callumalpass/tasknotes) Obsidian plugin's
REST API at `http://localhost:8080/api` — **not** a filesystem indexer. Obsidian
(with the TaskNotes plugin and its API server) must be running for any of this to
work.

## Table of contents

- [How it works](#how-it-works)
- [Module structure](#module-structure)
- [Prerequisites](#prerequisites)
- [Keybindings](#keybindings)
- [Workflows](#workflows)
- [Inline task card](#inline-task-card)
- [Hidden frontmatter](#hidden-frontmatter)
- [Task info panel](#task-info-panel)
- [Configuration](#configuration)
- [Row rendering](#row-rendering)
- [Data model](#data-model)
- [API endpoints used](#api-endpoints-used)
- [Troubleshooting](#troubleshooting)

## How it works

The module is an API client with a thin in-memory index layered on top of the API
responses. The flow is: query the API → build an index from the response → drive
Snacks pickers from the index.

- **API client.** All reads/writes go through `http://localhost:8080/api`. Task
  data is fetched with `GET /api/tasks` (not a vault scan); the in-memory
  `keys_index` (`{ key → value → [filepaths] }`) is rebuilt from that response.
- **Boot health check.** On load the plugin probes `GET /api/health` (1.5s
  timeout). **If the API is unreachable, the keymaps are NOT registered** and the
  plugin returns early. No `<leader>ow*` binding will exist until the API is up.
- **Caching.** Three time-based caches, all **full-rebuild on expiry** (no
  incremental, mtime-based re-parsing):

  | Cache | TTL | Source |
  |---|---|---|
  | Task index (`keys_index`) | 30s | `GET /api/tasks` |
  | Filter options | 300s | `GET /api/filter-options` |
  | Task paths | 60s | API |

- **The one real filesystem scan.** The vault-wide tag browser (`owt`) is the only
  feature that reads the disk directly: an async, chunked scan of the vault
  (`~/.the-grid/zettelkasten`) over **all** notes, not just tasks.
- **Live filter options.** Statuses, priorities, contexts, projects and tags —
  plus their colors, icons and display order — come live from
  `GET /api/filter-options`. Nothing is hardcoded.

## Module structure

The implementation is a strict dependency tree (a `require` DAG) under
`lua/tasknotes/`, with `config` at the root and `init` as the only public entry
point. The lazy spec under `lua/plugins/writing/` does nothing but `require` it.

| Module | Responsibility |
|---|---|
| `config` | Tunables — the single source of truth (paths, API URL, TTLs, row glyphs) |
| `api` | HTTP client for the REST API + the TTL'd API caches (filter-options, task paths) |
| `util` | Pure helpers (date math, due/scheduled formatting, path↔id) — no Snacks/API at load |
| `cache` | Task index (API-sourced, TTL-gated) + the whole-vault notes index (FS-scanned, `owt`) |
| `context` | Task context builder — parents, subtasks, progress and checklist counts for one task |
| `card` | The inline task card: a `Context` rendered as extmark virtual lines under the frontmatter |
| `frontmatter` | Hidden frontmatter: the rows above the closing `---` concealed with a `conceal_lines` extmark |
| `panel` | The task info side panel: shows and edits the task properties in a right-hand split |
| `ui` | Shared Snacks picker view, the live-color engine, status/priority rank tables, row formatter |
| `pickers` | The `Key → Value → File` drill-down + status/tag shortcuts + the vault tag browser |
| `query` | Filter builder, the API-backed task finder, and the interactive query builder |
| `query_templates` | Pre-canned date filters (today / overdue) reachable via `oq` |
| `task_ops` | NLP task creation (`own`) + the staged multi-field editor (`owe`) |
| `pomodoro` | The Pomodoro & time-tracking panel (`owp`) |
| `init` | Public entry: `setup(opts)` merges config in place, gates on `/api/health`, registers keymaps |

Adding a feature: put pure logic in `util`, API calls in `api`, shared rendering
in `ui`, then wire the keymap in `init`.

## Prerequisites

- **TaskNotes API** reachable at `http://localhost:8080` (Obsidian open, TaskNotes
  plugin enabled with its API server running).
- Neovim deps: `plenary.nvim`, `snacks.nvim`.

## Keybindings

All bindings are **flat under `<leader>o`** (no chord sub-trees). Registered in
`tasknotes.lua` after the boot health check passes.

| Key | Action | What it does |
|-----|--------|--------------|
| `owk` | **Search** | Master 3-stage drill-down: frontmatter **Key → Value → File** (preview; opens on `<CR>`) |
| `ows` | **Filter: status** | Pick a status, list matching tasks |
| `owo` | **Filter: tag/project** | Pick a tag/project, list matching tasks |
| `owt` | **Tag browser** | Vault-wide two-stage **Tag → Notes** over all notes (the only real FS scan) |
| `oq` | **Query templates** | Snacks picker: today (sched/due on/before today) / overdue (sched/due before today) |
| `oQ` | **Query builder** | Interactive multi-field filter (multi-select via `<Tab>`, inclusive date ranges) |
| `own` | **New task** | Natural-language quick-add (`POST /api/nlp/create`) |
| `owe` | **Edit fields** | Multi-field editor; batches changes into a **single PUT** |
| `owp` | **Pomodoro / time** | State-aware Pomodoro & time-tracking panel |
| `owr` | **Refresh** | Force cache rebuild |
| `oc` | **Toggle inline card** | Show/hide the inline task card under the frontmatter |
| `oi` | **Info panel** | Toggle the task info side panel (shows and edits the task properties) |
| `oI` | **Info panel (top)** | Same panel as a full-width top split, note below |
| `oh` | **Toggle frontmatter** | Hide/show the frontmatter rows of task notes (the closing `---` stays visible) |

> The old chord-based design (`oz*` search, `c*` contexts, `d*` dates, `v*` views,
> `q*` query presets) **no longer exists**. Per-field mutations were collapsed into
> the `owe` multi-field editor.

## Workflows

### Search a task by any frontmatter field — `owk`
Three-stage Snacks drill-down: pick a frontmatter **key** → pick a **value** for
that key → pick the **file** (with preview, opens on `<CR>`). Each stage can step
back to the previous one on close.

### Filter by status or tag — `ows` / `owo`
Single-stage pickers fed by live `filter-options`. Pick a value, get the matching
tasks.

### Browse the whole vault by tag — `owt`
Two-stage **Tag → Notes** over every note in the vault (not just tasks). Backed by
a dedicated async filesystem scan.

### Query templates — `oq`
Pre-canned filters for the two common date-based buckets. Each template is a
`find_tasks` filter closure that runs against `/api/tasks` and renders the
matches with the standard task row format. Both templates check `scheduled`
**OR** `due` (whichever is on/before the threshold), so a task with only one
of the fields set still appears.

- **Today** — Scheduled or due on or before today (inclusive). The default
  starting point; tasks that have landed on your plate but are still pending.
- **Overdue** — Scheduled or due strictly before today. The "I missed this"
  bucket.

Both templates are pure filter functions — neither reads from nor writes back
to the local cache.

### Build a query — `oQ`
Interactive field selector (status / priority / contexts, multi-select with
`<Tab>`; inclusive date-range bounds), then runs the filtered query against the
API.

### Create a task — `own`
Free-text **natural-language** input sent to `POST /api/nlp/create`. The **API**
parses it and writes the task file server-side using the configured template — the
plugin does not write frontmatter itself.

### Edit task fields — `owe`
Staged editor (field selector → per-field picker) that accumulates changes into one
`patch` and fires a **single `PUT /api/tasks/{id}`** on Save. Covers **title,
status, priority, contexts, projects, tags, scheduled, due**. Includes a 60-day
calendar picker and a 24h / 15-min time-of-day picker.

> Editing **title** updates the configured title-source frontmatter field (e.g.
> `task:`); it does **not** rename the file.

On Save the note buffer is **written first** (so unsaved note text reaches the
server) and reloaded afterwards **without `edit!`** (so the server's new
frontmatter shows up and no local text is lost).

### Pomodoro & time tracking — `owp`
State-aware panel (idle / running / paused) over `/api/pomodoro/*`: start, pause,
resume, stop. Per-task time tracking over `/api/tasks/{id}/time/*` (start, start
with description, stop). Read-only views: Pomodoro stats, today's time summary
(`/api/time/summary`), active sessions (`/api/time/active`). After a server-side
write the open task buffer is auto-reloaded (with an unsaved-changes guard).

### Refresh — `owr`
Invalidates the caches and forces a full rebuild on the next call.

## Inline task card

Opening a TaskNotes task note draws a dimmed **card** right under the
closing `---` of the frontmatter — the same place Obsidian draws its own
card. The card is **virtual text**: it is an extmark (`virt_lines`) in the
`tasknotes_card` namespace, so the buffer itself is never modified and
nothing is written to the file.

What the card shows:

- **Header** — status icon and priority dot (in the live colors from
  `/api/filter-options`), the title, the scheduled/due dates and the tags.
- **Parents** — the projects the task declares (`↑ project`).
- **Subtasks** — tasks whose `projects` point back at this note, as tree
  rows (`├`/`└`) with their status icon. At most `card_max_subtasks` rows
  are drawn; the rest collapse into a `+N more` line.
- **Progress** — `subtasks done/total · checklist done/total`. The
  checklist counts the body of the note only (frontmatter excluded):
  `[ ]` open, `[x]`/`[X]` done, `[-]`/`[~]` in progress.

`<leader>oc` toggles the card globally (on by default, for the session).
The toggle redraws every loaded task buffer.

The card is **read-only** and never blocks: it is drawn from the in-memory
task cache. When the cache is stale an asynchronous refresh is started in
the background and the card is redrawn when it lands (the
`User TaskNotesCacheRefreshed` event). Notes that are not tasks get no
card.

## Hidden frontmatter

A task note opens on its **body**: the YAML block at the top is concealed
with a `conceal_lines` extmark in the `tasknotes_frontmatter` namespace.
Like the card, the conceal is virtual — the buffer is never modified
(`modified` stays false), nothing is written to the file and
`'conceallevel'` is not lowered.

What is hidden:

- Every row **above** the closing `---` of the frontmatter.
- The **closing `---` stays visible** — concealing it would also hide
  the inline card, whose virtual lines are anchored on that row.

Notes that are not tasks (not in the task cache) are never touched.

`<leader>oh` toggles the conceal globally (on by default, for the
session) and re-applies it to every loaded note. With the frontmatter
shown you edit the YAML by hand as usual; with it hidden, moving the
cursor into a hidden row reveals that row, so one keystroke is enough to
reach a field.

The conceal follows the fence: it is re-applied when the note is
entered, on save, while the note is edited and whenever the task cache
is refreshed (the cache may land after the note was opened).

## Task info panel

`<leader>oi` toggles a **side panel**: a right-hand split
(`Snacks.win`, `position = "right"`, width `panel_width`, 50% of the
editor by default) that shows the
full context of the task under the cursor and lets you edit its
properties. `<leader>oI` opens the same panel as a **top split** over
the full editor width with the note below (height `panel_height`, 25%
of the editor by default) — for narrow portrait screens. Either key
closes an open panel. Opening the panel moves the cursor into it.

What the panel shows:

- **Header** — status icon and priority dot (in the live colors from
  `/api/filter-options`) and the title.
- **Properties** — one row per editable field: Task, Status, Priority,
  Scheduled, Due, Projects, Tags, Estimate (contexts are not shown). Each row shows
  the current value (the live label and color for status and priority,
  an em dash `—` when the field is empty). The Estimate row shows the
  raw minutes — the unit the editor prompts in. The Projects row shows
  the **link names** (`Parent Note`), not the raw wikilinks
  (`[[Parent Note]]`); the value sent on edit is untouched. A saved
  field shows up at once: the cache takes the task the API answers
  with and keeps it until the server's task list catches up.
- **Parents** — the projects the task declares.
- **Subtasks** — tasks whose `projects` point back at this note, with
  their status icon, priority and dates, plus a text progress bar
  (`████░░░░ 2/6`).
- **Dependencies** — **Blocked by** (the tasks this one waits on) and
  **Blocking** (the tasks this one holds up). Both come from the API's
  `blockedBy` / `blocking` fields; a dependency that is not in the task
  cache is listed by name but cannot be opened.
- **Checklist** — one row per checklist state in use in the note body,
  with the icon and color of the matching task status: `[ ]` open
  (inbox), `[-]` doing (in-progress), `[~]` on-hold, `[>]` waiting,
  `[x]` done. The inline card's `checklist done/total` counts all five.
- **Time** — tracked minutes vs. the estimate (`1h 26m / 1h`).
- **Footer hint** — the keys that work in the panel.

Empty sections are omitted. A buffer that is not a task shows
`Not a TaskNotes task`; while the task cache is still empty the panel
shows `Loading tasks…`.

The panel **inherits the global `wrap` and `linebreak`** settings, and
`<leader>W` toggles wrap in the panel window like in any other window.
With wrap on, long rows wrap. With wrap off, every row is **fitted to
the panel width**: the least important parts of a row (a subtask's
priority and dates) are dropped first, and a row that still does not
fit is cut with `…` on a character boundary — never in the middle of a
word or a glyph. The width follows the panel window, so resizing the
panel re-fits the rows.

The panel **follows the buffer**: entering another buffer re-renders it
for that buffer, while entering the panel window itself never
re-renders it. It also re-renders on save and when the task cache is
refreshed.

### Panel keys

The keys are local to the panel's own buffer.

| Key | Action |
|---|---|
| `<CR>` | On a link row (parents, subtasks, dependencies): open that note **in the editing window**. On a property row: edit that field. |
| `s` | Edit the **status** of the followed task. |
| `p` | Edit the **priority** of the followed task. |
| `c` | Edit the **scheduled date** of the followed task. |
| `d` | Edit the **due date** of the followed task. |
| `t` | Edit the **tags** of the followed task. |
| `<q>` | Close the panel. |

After an edit the cursor stays in the panel (the field pickers keep the
window they were opened from as their return window,
`task_ops.picker_main`).

The edits always act on the task the panel **follows** — not on the
buffer under the cursor — and they go through the same path as
`<leader>oe`: `task_ops.edit_field` → `task_ops.apply_patch`, which
writes the note buffer if it has unsaved changes, PUTs the field to the
API and reloads the note afterwards (ADR-009). The value pickers are
the ones `<leader>oe` uses; the estimate is typed in minutes and an
empty value clears it.

Rendering never touches the network: the panel reads the in-memory
cache only. Only an explicit edit key reaches the API, and the write
path (`task_ops`) is loaded lazily, inside the key handler.

## Configuration

Tunables live in **`lua/tasknotes/config.lua`** — the single source of truth.
`setup(opts)` merges overrides into that table *in place*, so every module holding
a `require("tasknotes.config")` reference sees them. The lazy spec calls `setup()`
with no args; to override, pass a table from the spec's `config` function.

| Key | Default | Purpose |
|---|---|---|
| `vault_path` | `~/.the-grid/zettelkasten` | Vault root (used by the `owt` FS scan and path↔id) |
| `tasks_folder` | `TaskNotes/Tasks` | Task subfolder |
| `api_url` | `http://localhost:8080/api` | REST API base |
| `cache_ttl` | `30` | Local task-index TTL (seconds) |
| `default_status` / `default_priority` | `inbox` / `normal` | Fallbacks for NLP create |
| `pomodoro_minutes` | `nil` | Optional WORK-length override (breaks stay server-managed) |
| `status_icons` | per-status glyphs | **User-tunable** status glyph map (see [Row rendering](#row-rendering)) |
| `default_icon` | `●` | Fallback glyph for unmapped statuses |
| `priority_icon` | `●` | The priority-dot glyph |
| `card_max_subtasks` | `5` | Subtask rows drawn in the inline card before `+N more` |
| `panel_width` | `0.5` | Width of the task info side panel: below `1` a share of the editor width (`0.5` = 50%, kept when the terminal is resized), `1` or more a fixed column count |
| `panel_height` | `0.25` | Height of the top panel (`oI`), same rule over the editor height |
| `frontmatter_hidden` | `true` | Hide the frontmatter rows of task notes (toggle with `oh`) |
| `completed_statuses` | `{ done = true }` | Fallback "completed" status set when the API's filter-options cache is empty |

## Row rendering

Search rows (`owk` file stage, `ows`/`owo`, `owq` results) render as four segments
— **status glyph · priority dot · title · dimmed date** — instead of the old
`[status][priority]` text badges:

- **Glyphs are local and tunable.** `config.status_icons` maps each status `value`
  to a glyph (keys: `inbox`, `in-progress`, `on-hold`, `waiting`, `done`); unmapped
  statuses fall back to `default_icon`. Edit these in `config.lua` to use your own
  Nerd Font glyphs. (The API's own `icon` field is a *Lucide name*, not a terminal
  glyph, so it can't be rendered directly.)
- **Colors are live, not local.** Status-glyph and priority-dot colors come from
  `GET /api/filter-options` at runtime (`ui.get_color_tables` →
  `ui.ensure_color_hl`); they are never hardcoded.
- **Title resolution.** The title segment uses `fm.task` (string, or first
  element of a list) when present, falling back to `fm.title` and finally the
  filename stem. Mirrors the convention used by the whole-vault notes index
  (`ot`) so both surfaces show the same title. Source: `util.task_title`.
- The date suffix (`util.due_info`) keeps the **OVERDUE / DUE TODAY** emphasis.

## Data model

Tasks are Markdown notes whose frontmatter is **written and normalized by the API**,
not by this plugin. Fields the plugin reads and/or sends in edits:

| Field | Notes |
|---|---|
| `status` | From live filter-options |
| `priority` | From live filter-options |
| `scheduled` | `YYYY-MM-DD` or `YYYY-MM-DDTHH:MM` |
| `due` | Drives the **OVERDUE / DUE TODAY** display |
| `tags`, `contexts`, `projects` | Multi-value |
| `timeEntries` | Mutated server-side by time tracking |
| `recurrence`, `complete_instances`, `skipped_instances` | Recurring tasks |
| `dateCreated`, `dateModified` | Timestamps |
| `completedDate` | **Stamped server-side by the API on completion**, not by the plugin |
| `title` | Mapped to the configured title-source field; editing it does **not** rename the file |

## API endpoints used

| Endpoint | Use |
|---|---|
| `GET /api/health` | Boot health check (keymaps gated on this) |
| `GET /api/tasks` | Full task fetch → builds the in-memory index |
| `POST /api/tasks/query` | Filtered queries (query builder) |
| `GET /api/tasks/{id}` | Fetch a single task |
| `PUT /api/tasks/{id}` | Edit (batched patch from `owe`) |
| `GET /api/filter-options` | Live statuses/priorities/contexts/projects/tags + colors/icons/order |
| `POST /api/nlp/create` | Natural-language task creation (`own`) |
| `/api/pomodoro/*` | Pomodoro state |
| `/api/tasks/{id}/time/*` | Per-task time tracking |
| `GET /api/time/summary` | Today's time summary |
| `GET /api/time/active` | Active time sessions |

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| No `<leader>ow*` keymaps exist | API was down at boot (health check failed) | Start Obsidian + the TaskNotes API, then restart Neovim |
| Stale task data | 30s index cache | `owr` to force a rebuild |
| Edits don't appear | API write succeeded but buffer not reloaded | Reopen the task buffer (time-tracking writes auto-reload) |
