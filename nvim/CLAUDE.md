# CLAUDE.md — Agent rules

Rules for AI agents editing this Neovim config. This file is **rules only** — for
the map and reference, see:

- **[README.md](README.md)** — documentation index.
- **[docs/architecture.md](docs/architecture.md)** — how it's wired (bootstrap,
  modules, LSP, keymaps, settings).

> `AGENTS.md` and `GEMINI.md` are symlinks to this file — edit only `CLAUDE.md`.

## CRITICAL — Colemak navigation

Navigation is remapped to a **Colemak** layout (`u/e/i/n` → `k/j/l/h`, etc.).
Standard `hjkl` do **not** behave as in vanilla Vim. When writing keymaps, motions,
or docs, account for the remaps — full table in
[docs/keys/editor.md](docs/keys/editor.md). Never assume vanilla bindings.

## Conventions

- **Leader namespace** is allocated by domain — respect it (table in
  [docs/architecture.md](docs/architecture.md#keymap-system)). New maps go under the
  correct prefix; plugin-specific maps live in the plugin spec's `keys = {}`.
- **Plugins are modular** — one file per plugin under
  `lua/plugins/<category>/`. A new plugin → a new file in the right category, and
  (if the category isn't already imported) an `{ import = ... }` entry in
  `lua/config/lazy.lua`. A plugin that outgrows one file (e.g. **TaskNotes**) gets
  its own `lua/<name>/` module tree, with only a thin lazy spec left under
  `lua/plugins/<category>/` — keep the tree out of `plugins/` so lazy's directory
  import doesn't try to load the modules as plugin specs.
- **LSP** uses the native `vim.lsp.config`/`enable` API with per-server modules in
  `lua/plugins/lsp/servers/`. To add a server, follow
  [docs/architecture.md](docs/architecture.md#lsp-architecture).
- **`conceallevel=2`** is required by Obsidian markdown — do not lower it.
- **Match surrounding style** — 2-space indent, `stylua` formatting.

## Gotchas

- `lua/plugins/android/` exists but is **not wired into the lazy spec** (its import
  is commented out in `lua/config/lazy.lua`).
- This directory is **copied into the Nix store** by Home Manager
  (`nix/home/dotfiles.nix`, `source = ../../nvim; recursive = true`) — not a live
  symlink. **Edits require `sudo nixos-rebuild switch` to take effect**, and **new
  files must be `git add`-ed first**: the flake copies only git-tracked files, so an
  untracked module is invisible at runtime (`module '…' not found`).

## Verify — don't trust docs blindly

Docs in this repo have drifted from the code before. When a doc and the code
disagree, **the code wins** — fix the doc and cite `file:line`.

## Documentation rules

The doc system: `README.md` = index, `docs/` = per-feature, this file = agent
rules. Follow the conventions already in use (Diátaxis, Minimum Viable
Documentation, no duplication, back-link every sub-doc to the README).
