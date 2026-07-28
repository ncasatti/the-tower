# Neovim Configuration

A modular **Neovim** setup managed with [lazy.nvim](https://github.com/folke/lazy.nvim),
featuring a **Colemak-remapped** navigation layout, native LSP across 13 languages,
Snacks-based UI, and an Obsidian/TaskNotes writing workflow. Part of the
**[the-tower](../README.md)** NixOS configuration — this directory is deployed to
`~/.config/nvim` by Home Manager (`nix/home/dotfiles.nix`, a store copy — see
[Quick start](#quick-start)).

> **New here? Read [docs/architecture.md](docs/architecture.md) first** for how it's
> wired, then [docs/keys/keys.md](docs/keys/keys.md) for the keybindings — navigation
> is Colemak, so `hjkl` will *not* behave as you expect.

## Highlights

- **Colemak navigation** — `u/e/i/n` replace `k/j/l/h` across all modes.
- **Native LSP** (`vim.lsp.config`/`enable`) for 13 languages via Mason, with
  per-server config modules.
- **Snacks.nvim** — dashboard, unified picker, scroll, zen mode.
- **Writing** — Obsidian, TaskNotes (API client), LaTeX (vimtex + nabla), Jupyter.
- **Full dev stack** — DAP debugging, Neotest, Git (Neogit), DB (dadbod),
  Android/Gradle, Python REPL/Jupyter.

## Quick start

This config deploys with the-tower (`sudo nixos-rebuild switch --flake .#<host>`).
Home Manager copies this directory into the Nix store (`dotfiles.nix`,
`recursive = true`) — it is **not** a live symlink, so **edits require a rebuild**
to take effect, and **new files must be `git add`-ed first** (the flake only copies
git-tracked files).

```vim
:Lazy            " plugin manager dashboard
:Mason           " LSP / tool installer
:checkhealth     " diagnose the setup
```

## Documentation

### Overview
| Doc | What it covers |
|---|---|
| [architecture.md](docs/architecture.md) | Bootstrap, directory layout, plugin modules, LSP, keymaps, settings |
| [CLAUDE.md](CLAUDE.md) | Rules for AI agents working in this config |

### Keybindings
| Doc | Domain |
|---|---|
| [keys/keys.md](docs/keys/keys.md) | Index of all keybinding docs |
| [keys/editor.md](docs/keys/editor.md) | Colemak core + windows + search + buffers |
| [keys/lsp.md](docs/keys/lsp.md) · [keys/git.md](docs/keys/git.md) · [keys/debug.md](docs/keys/debug.md) · [keys/testing.md](docs/keys/testing.md) | LSP / Git / Debug / Test |
| [keys/navigation.md](docs/keys/navigation.md) · [keys/writing.md](docs/keys/writing.md) · [keys/languages.md](docs/keys/languages.md) · [keys/ai.md](docs/keys/ai.md) · [keys/android.md](docs/keys/android.md) · [keys/database.md](docs/keys/database.md) | Navigation / Writing / Languages / AI / Android / DB |

### Features & setup
| Doc | What it covers |
|---|---|
| [tasknotes.md](docs/tasknotes.md) | TaskNotes — Neovim client for the TaskNotes API |
| [android-setup.md](docs/android-setup.md) | Android/Java development setup |
| [android-debugging-guide.md](docs/android-debugging-guide.md) | Android debugging |
| [python-setup-complete.md](docs/python-setup-complete.md) · [python-debug-setup.md](docs/python-debug-setup.md) · [python-keybindings.md](docs/python-keybindings.md) · [pyworks-guide.md](docs/pyworks-guide.md) | Python: setup, debugging, keys, Jupyter/Pyworks |

## For contributors & agents

Read [CLAUDE.md](CLAUDE.md) before editing — it captures the non-obvious rules
(Colemak remaps, leader namespace, how to add plugins/LSP servers). Agent rule
files (`AGENTS.md`, `GEMINI.md`) are symlinks to `CLAUDE.md`.
