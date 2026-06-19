[← nvim docs index](../README.md)

# TaskNotes — Neovim client for the TaskNotes API

A Neovim front-end for task management, implemented as a single Lua module
(`lua/plugins/writing/tasknotes.lua`). It is an **HTTP client** for the
[TaskNotes](https://github.com/callumalpass/tasknotes) Obsidian plugin's REST API
at `http://localhost:8080/api` — **not** a filesystem indexer. Obsidian (with the
TaskNotes plugin and its API server) must be running for any of this to work.

## Table of contents

- [How it works](#how-it-works)
- [Prerequisites](#prerequisites)
- [Keybindings](#keybindings)
- [Workflows](#workflows)
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

## Prerequisites

- **TaskNotes API** reachable at `http://localhost:8080` (Obsidian open, TaskNotes
  plugin enabled with its API server running).
- Neovim deps: `plenary.nvim`, `snacks.nvim`.

## Keybindings

All bindings are **flat under `<leader>ow`** (no chord sub-trees). Registered in
`tasknotes.lua` after the boot health check passes.

| Key | Action | What it does |
|-----|--------|--------------|
| `owk` | **Search** | Master 3-stage drill-down: frontmatter **Key → Value → File** (preview; opens on `<CR>`) |
| `ows` | **Filter: status** | Pick a status, list matching tasks |
| `owo` | **Filter: tag/project** | Pick a tag/project, list matching tasks |
| `owt` | **Tag browser** | Vault-wide two-stage **Tag → Notes** over all notes (the only real FS scan) |
| `owq` | **Query builder** | Interactive multi-field filter (multi-select via `<Tab>`, inclusive date ranges) |
| `own` | **New task** | Natural-language quick-add (`POST /api/nlp/create`) |
| `owe` | **Edit fields** | Multi-field editor; batches changes into a **single PUT** |
| `owp` | **Pomodoro / time** | State-aware Pomodoro & time-tracking panel |
| `owr` | **Refresh** | Force cache rebuild |

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

### Build a query — `owq`
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

### Pomodoro & time tracking — `owp`
State-aware panel (idle / running / paused) over `/api/pomodoro/*`: start, pause,
resume, stop. Per-task time tracking over `/api/tasks/{id}/time/*` (start, start
with description, stop). Read-only views: Pomodoro stats, today's time summary
(`/api/time/summary`), active sessions (`/api/time/active`). After a server-side
write the open task buffer is auto-reloaded (with an unsaved-changes guard).

### Refresh — `owr`
Invalidates the caches and forces a full rebuild on the next call.

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
