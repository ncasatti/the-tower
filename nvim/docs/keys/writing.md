# Writing

Obsidian (Zettelkasten), TaskNotes (task management), Markdown rendering.

## Obsidian (`<leader>o*`)

- `<leader>os` — Search notes
- `<leader>og` — Grep notes
- `<leader>on` — New note
- `<leader>ot` — Insert template
- `<leader>oo` — Quick switch note
- `<leader>oa` — Show all links
- `<leader>ob` — Show backlinks
- `<leader>of` — Follow link
- `<leader>ox` — Toggle checkbox
- `<leader>o#` — Search tags
- `<leader>or` — Rename note
- `<leader>oi` — Paste image
- `<leader>ov` — Open in Obsidian app

## TaskNotes (`<leader>ow*`)

API-driven via TaskNotes HTTP API (`localhost:8080/api`). Plugin disables itself if the API is unreachable at startup.

### Search / filter

- `<leader>owk` — Search by frontmatter key (3-stage drill-down: key → value → file)
- `<leader>owr` — Force refresh of local cache + API caches
- `<leader>ows` — Filter by status (shortcut into stage 2)
- `<leader>owo` — Filter by tag/project (shortcut into stage 2)
- `<leader>owq` — Interactive query builder (field-selector with multi-select, inclusive date bounds)

### Task management

Mutations go through `PUT /api/tasks/{url-encoded-path}`. Statuses, priorities, contexts and projects are pulled live from `/api/filter-options`.

- `<leader>own` — New task (NLP quick-add via `/api/nlp/create`, server-side template)
- `<leader>owe` — Edit fields (field-selector form: status / priority / contexts / projects / scheduled / due — multi-select fields pre-mark current values with the native Snacks dot, Tab to toggle, all changes accumulate into one PUT on save)

## Markdown rendering (`<leader>m*`, buffer-local in `.md`)

- `<leader>mr` — Toggle rendering
- `<leader>mq` — Toggle fold under cursor
- `<leader>mf` — Navigate to link under cursor
- `<leader>me` — Expand all headings
- `<leader>mc` — Collapse all headings
- `<leader>mh` — Cycle heading level (`#` → `##` → ... → restart)
- `<leader>mx` — Toggle checkbox
- `<leader>ml` — Open link in browser
- `]]` / `[[` — Next / previous heading or callout
