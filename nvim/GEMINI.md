# GEMINI.md

This file provides context to Gemini when working with this Neovim configuration.

## Project Overview

This is a personal Neovim configuration that uses [Lazy.nvim](https://github.com/folke/lazy.nvim) as the plugin manager. The configuration is highly customized with a Colemak-inspired keybinding layout, comprehensive LSP integration via Mason, a modern centered UI experience using Noice.nvim, and deep integration with Obsidian for task and note management.

The configuration is structured in a modular way, with the main entry point being `init.lua`, which loads the core configuration, keybindings, and the Lazy.nvim plugin manager setup.

## Building and Running

This is a Neovim configuration, so there is no build process. To "run" the project, simply open Neovim. The plugins are managed by Lazy.nvim and will be installed automatically on the first launch.

Key commands for managing plugins:

*   `:Lazy`: Open the Lazy.nvim dashboard.
*   `:Lazy sync`: Update plugins to the versions specified in `lazy-lock.json`.
*   `:Lazy update`: Update plugins and regenerate the `lazy-lock.json` file.
*   `:TSUpdate`: Update Treesitter parsers.

## Development Conventions

Plugin management is handled by Lazy.nvim. Plugin specifications are located in the `lua/plugins/` directory. Each file in this directory returns a Lazy.nvim plugin specification.

To add a new plugin:

1.  Create a new file in `lua/plugins/` with the plugin's name (e.g., `lua/plugins/new-plugin.lua`).
2.  Add the Lazy.nvim plugin specification to the file.
3.  Restart Neovim. Lazy.nvim will automatically install and load the new plugin.

The configuration uses a Colemak-based keybinding system. See the "Keybinding System" section for more details.

## Key Features

### Keybinding System

The configuration uses a completely remapped navigation system based on Colemak principles. This applies in normal, visual, and insert modes.

*   **Navigation**: `u/e/i/n` for up/down/right/left.
*   **Word Navigation**: `N/I` for word backward/forward.
*   **Paging**: `E/U` for page down/up.
*   **Insert Mode**: `l/L` to enter insert mode at the cursor/start of the line.
*   **Undo**: `z` for undo.
*   **Yank**: `;` for yank.

### Language Server Protocol (LSP)

LSP is managed by `mason.nvim` and `mason-lspconfig.nvim`. The configuration automatically installs a set of default language servers, including:

*   `clangd` (C/C++)
*   `rust_analyzer` (Rust)
*   `pyright` (Python)
*   `gopls` (Go)
*   `luau_lsp` (Lua)

LSP keybindings are standard, with `gd` for go to definition, `gr` for references, and `K` for hover documentation.

### User Interface

The UI is heavily customized using `noice.nvim` to create a modern, centered command-line experience. The command line, completion menu, and notifications are all styled and positioned for a clean look.

### Integrations

*   **Obsidian**: The configuration is tightly integrated with Obsidian for note-taking and task management. The `obsidian.nvim` plugin is used for this, and there is a custom `tasknotes.lua` plugin for managing tasks.
*   **Claude Code**: The `claude-code.nvim` plugin provides AI assistant integration.
*   **Codeium**: The `codeium.vim` plugin provides AI code completion.
*   **Git**: `neogit` provides a Magit-like interface for Git.
*   **Tmux**: `nvim-tmux-navigation` allows for seamless navigation between Neovim and tmux panes.
