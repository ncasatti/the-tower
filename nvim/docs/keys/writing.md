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
- `<leader>or` — Rename note
- `<leader>od` — Paste image
- `<leader>ov` — Open in Obsidian app
- `<leader>oG` — Visual Graph of Zettelkasten (ideadrop, global)
- `<leader>og` — Visual Local Graph of current note (ideadrop, 1-hop neighborhood)
- `<leader>,` — Project Todo list (.todo.md in cwd, ideadrop) — `lua/plugins/writing/ideadrop.lua:171`

## TaskNotes (`<leader>o*`)

API-driven via TaskNotes HTTP API (`localhost:8080/api`). Plugin disables itself if the API is unreachable at startup.

### Search / filter

- `<leader>owk` — Search by frontmatter key (3-stage drill-down: key → value → file)
- `<leader>owr` — Force refresh of local cache + API caches
- `<leader>ows` — Filter by status (shortcut into stage 2)
- `<leader>ou` — Search tags (Globaly)
- `<leader>owo` — Filter by tag/project (shortcut into stage 2)
- `<leader>oq` — Query templates (Snacks picker: today / overdue)
- `<leader>oQ` — Interactive query builder (field-selector with multi-select, inclusive date bounds)

### Task management

Mutations go through `PUT /api/tasks/{url-encoded-path}`. Statuses, priorities, contexts and projects are pulled live from `/api/filter-options`.

- `<leader>own` — New task (NLP quick-add via `/api/nlp/create`, server-side template)
- `<leader>owe` — Edit fields (field-selector form: status / priority / contexts / projects / scheduled / due — multi-select fields pre-mark current values with the native Snacks dot, Tab to toggle, all changes accumulate into one PUT on save)

### Views

- `<leader>oc` — Toggle inline task card (virtual card under the frontmatter; global, on by default)
- `<leader>oi` — Toggle task info panel (right-hand split with the full task context)

### Task info panel (inside the panel)

The panel's own buffer carries these keys; they act on the task the
panel follows.

- `<CR>` — On a link row (parents, subtasks, dependencies): open that note in the editing window. On a property row: edit that field.
- `s` — Edit the status
- `p` — Edit the priority
- `d` — Edit the due date
- `<q>` — Close the panel

The edits go through the same path as `<leader>oe` (`task_ops.edit_field`
→ `apply_patch` → `PUT /api/tasks/{id}`); the pickers are the ones
`<leader>oe` uses.

## Markdown rendering (`<leader>m*`, buffer-local in `.md`)

- `<leader>mr` — Toggle rendering
- `<leader>mq` — Toggle fold under cursor
- `<leader>mf` — Navigate to link under cursor
- `<leader>me` — Expand all headings
- `<leader>mc` — Collapse all headings
- `<leader>mh` — Cycle heading level (`#` → `##` → ... → restart)
- `<leader>mx` — Toggle checkbox
- `<leader>ml` — Open link in browser
- `<leader>mp` — Preview PDF (pandoc → pdflatex → zathura, recompiles on save)
- `<leader>mP` — Stop PDF preview
- `<leader>mE` — Export PDF next to the `.md` (one-shot, no viewer)
- `]]` / `[[` — Next / previous heading or callout
