return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	lazy = true,
	ft = "markdown",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	keys = {
		-- Search commands
		{ "<leader>oS", "<cmd>Obsidian search<cr>", desc = "Search Notes" },

		-- Main commands
		{ "<leader>oN", "<cmd>Obsidian new<cr>", desc = "New Note" },
		{ "<leader>oT", "<cmd>Obsidian template<cr>", desc = "Insert Template" },
		{ "<leader>oo", "<cmd>Obsidian quick_switch<cr>", desc = "Quick Switch" },

		-- Link commands
		{ "<leader>oa", "<cmd>Obsidian links<cr>", desc = "Show All Links" },
		{ "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Show Backlinks" },

		-- Link and checkbox commands
		{ "<leader>of", "<cmd>Obsidian follow_link<cr>", desc = "Follow Link" },
		{ "<leader>ox", "<cmd>Obsidian toggle_checkbox<cr>", desc = "Toggle Checkbox" },

		-- Additional commands
		-- NOTE: <leader>ow is now owned by tasknotes.lua (M.picker.note_search) —
		-- a cache-backed whole-vault note-by-tag picker. The native `Obsidian tags`
		-- did a live ripgrep scan on every call (slow) and couldn't inherit our
		-- Snacks layout/nav, so the binding was moved out of here.
		{
			"<leader>oR",
			function()
				return require("obsidian").util.rename_with_visual_selection()
			end,
			desc = "Rename Note",
		},
		{ "<leader>od", "<cmd>Obsidian paste_img<cr>", desc = "Paste Image" },
		{ "<leader>ov", "<cmd>Obsidian open<cr>", desc = "Open in Obsidian App" },
	},
	config = function(_, opts)
		require("obsidian").setup({
			workspaces = {
				{
					name = "Zettelkasten",
					path = vim.fn.expand("~/.the-grid/zettelkasten/"),
					-- Per-workspace overrides deep-merge into the global opts when this
					-- vault is active. notes_subdir/templates.subdir MUST be strings —
					-- passing a function makes obsidian.nvim tostring() it into a literal
					-- folder name ("function: 0x…"), so the per-vault split lives here.
					overrides = {
						-- notes_subdir = "Fleeting",
						templates = { subdir = "Templates" },
					},
				},
				{
					name = "Agents",
					path = vim.fn.expand("~/.local/share/the-grid/"),
					-- No overrides: Agents inherits the global defaults (no notes_subdir,
					-- no templates.subdir) so obsidian.nvim never pre-creates those dirs.
				},
			},

			-- SETOPTS: Disable legacy commands
			legacy_commands = false,

			-- Disable obsidian.nvim UI rendering to avoid conflict with render-markdown.nvim
			-- (both plugins conceal list markers and apply icons, causing visual overlap)
			ui = { enable = false },

			-- Disable obsidian.nvim's frontmatter management. Its BufWritePre hook
			-- (autocmds.lua -> note:update_frontmatter) reserializes the WHOLE
			-- frontmatter with an encoder that can't represent nested structures
			-- (lists of maps). TaskNotes writes exactly that — `timeEntries`,
			-- `recurrence`, `complete_instances` — so every save collapsed those
			-- arrays into a single quoted string, corrupting the YAML. We own
			-- frontmatter via TaskNotes (API) + templates, so this automatism is
			-- pure liability here.
			frontmatter = { enabled = false },

			-- notes_subdir / templates.subdir are set per-workspace via the
			-- `overrides` tables above (Zettelkasten only). Left unset globally so
			-- the Agents vault stays flat.

			-- Vault-relative attachment folder. The plugin default ("attachments")
			-- doesn't match this vault; this path feeds both `Obsidian paste_img`
			-- and snacks.image's resolve hook (wikilink image rendering).
			attachments = {
				folder = "Zettelkasten/references/attachments",
			},

			-- gitignore-style filters applied to the note scanner. Syncthing drops
			-- versioned copies of every modified/removed file under `.stversions/`
			-- and obsidian.nvim picks them up on tags/tasks/backlinks/search as
			-- ghost duplicates. Pattern must end with `/` to be directory-scoped
			-- (matches the directory itself + every file inside); without it,
			-- `.stversions` would only match the literal folder name and miss
			-- files like `.stversions/foo.md`. `.obsidian/` is also added for
			-- vault metadata that obsidian.nvim's own scanner otherwise indexes.
			file = {
				ignore_filters = { ".stversions/", ".obsidian/" },
			},

			-- Completion is deprecated, now provided via the built-in obsidian-ls
			-- completion = {
			--   nvim_cmp = true,
			--   min_chars = 2,
			-- },
			-- `subdir` is injected per-workspace (Zettelkasten → "Templates") via the
			-- workspace overrides above; only the shared formats live here.
			templates = {
				date_format = "%Y-%m-%d-%a",
				time_format = "%H:%M",
			},

			-- Inline task checkbox cycle: todo → working → pause → waiting → important → done.
			-- Order drives the <CR> smart_action in actions.lua:215 which reads
			-- `Obsidian.opts.checkbox.order`. The visual mapping (icon + color) is
			-- owned by render-markdown.nvim (see `checkbox.custom` there).
			checkbox = {
				order = { " ", "-", "~", ">", "!", "x" },
				create_new = true,
			},
		})

		-- Patch Note.save_to_buffer to honour `frontmatter.enabled = false` in ALL
			-- code paths — not only the BufWritePre autocmd. The LSP rename handler
			-- (obsidian-ls, lua/obsidian/lsp/handlers/_rename.lua) calls save_to_buffer
			-- directly, which reserializes the WHOLE frontmatter. obsidian's YAML PARSER
			-- flattens TaskNotes' nested `timeEntries` (a list of maps) into a single
			-- quoted string on read, so any parse→reserialize round-trip corrupts it.
			-- With frontmatter management off, TaskNotes owns it — make save_to_buffer a
			-- no-op so the block stays byte-for-byte intact. Rename still renames the
			-- file and updates [[backlinks]] (those go via the WorkspaceEdit, untouched).
			local Note = require("obsidian").Note
			local orig_save_to_buffer = Note.save_to_buffer
			Note.save_to_buffer = function(self, save_opts)
				if self.should_save_frontmatter and not self:should_save_frontmatter() then
					return false
				end
				return orig_save_to_buffer(self, save_opts)
			end

			-- Patch obsidian.picker.util.make_display to prefix filename:lnum:col.
			-- obsidian.nvim PR #963 ("util cleanup", merged 2026-09-15) changed this
			-- function to drop the filename prefix when `entry.text` is present. That
			-- broke the visual contract of pickers fed LSP locations — most visibly
			-- `:Obsidian backlinks` (commands/backlinks.lua), which renders one row per
			-- incoming backlink with the matched line as `text` and the source file as
			-- `filename`. Since then, every backlink row shows just the line, with no
			-- indication of which note it belongs to (the filename only surfaces in the
			-- preview pane and buffer name).
			--
			-- We restore the pre-#963 format — `icon filename:lnum:col  text` — by
			-- replacing `M.make_display` on the cached module table. Every picker
			-- backend (snacks, telescope, mini, fzf, ui) accesses it as a top-level
			-- local `ut = require("obsidian.picker.util")`, so updating the module
			-- table in `package.loaded` propagates to all of them at once.
			--
			-- The original is captured before we overwrite, and we pcall it as a
			-- fallback so a future upstream refactor (rename, signature change,
			-- table→function flip) degrades to current upstream behaviour instead of
			-- throwing in every picker.
			do
				local picker_util = require("obsidian.picker.util")
				local orig_make_display = picker_util.make_display
				picker_util.make_display = function(entry)
					-- Bail out for non-table entries (strings etc.) — mirrors the
					-- original function's first guard so we don't crash on inputs
					-- other picker backends may legitimately pass.
					if type(entry) ~= "table" then
						local ok, fallback = pcall(orig_make_display, entry)
						if ok then
							return fallback
						end
						return tostring(entry or "")
					end

					local Path = require("obsidian.path")
					local icons = require("obsidian.icons")

					local buf = {}
					local icon = icons.get_icon(entry)
					if icon then
						buf[#buf + 1] = icon
						buf[#buf + 1] = " "
					end

					-- Filename prefix with lnum/col. Preserved verbatim from the
					-- pre-#963 implementation so visual spacing and the `:lnum:col`
					-- suffix match the historical contract.
					if entry.filename then
						buf[#buf + 1] = Path.new(entry.filename):vault_relative_path()
						if entry.lnum ~= nil then
							buf[#buf + 1] = ":"
							buf[#buf + 1] = tostring(entry.lnum)
							if entry.col ~= nil then
								buf[#buf + 1] = ":"
								buf[#buf + 1] = tostring(entry.col)
							end
						end
					end

					-- Text after a single space. If only `user_data` is present
					-- (some non-LSP pickers), surface that as a fallback to keep the
					-- row informative instead of empty.
					if entry.text then
						buf[#buf + 1] = " "
						buf[#buf + 1] = entry.text
					elseif entry.user_data then
						buf[#buf + 1] = " "
						buf[#buf + 1] = tostring(entry.user_data)
					end

					return table.concat(buf, "")
				end
			end

		-- Disable documentSymbol on obsidian-ls (marksman provides cleaner rendered symbols)
		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(args)
				local client = vim.lsp.get_client_by_id(args.data.client_id)
				if client and client.name == "obsidian-ls" then
					client.server_capabilities.documentSymbolProvider = false
				end
			end,
		})

		-- Autostart obsidian-ls on markdown buffers inside an Obsidian vault.
		-- obsidian.nvim deprecated its nvim-cmp completion in favour of its
		-- built-in LSP server (lua/obsidian/lsp/init.lua), but the plugin
		-- itself never wires up autostart — you have to opt in. Without this,
		-- wikilink completion inside YAML frontmatter doesn't work, because
		-- marksman (the only other markdown LSP we enable) deliberately
		-- treats the `---...---` block as opaque prose and refuses to emit
		-- completion items for it.
		--
		-- We only start the server when the buffer resolves to a known
		-- workspace, so markdown files outside the vault (READMEs in other
		-- repos, scratch notes, etc.) don't accidentally pull obsidian-ls in.
		-- The LspAttach hook above then runs and disables documentSymbol as
		-- planned, so we don't double up with marksman's symbols.
		--
		-- The LSP entry point is `require("obsidian.lsp").start(buf)`, NOT
		-- `require("obsidian").lsp.start(buf)` — obsidian.nvim exposes its
		-- LSP module as a submodule (see lua/obsidian/init.lua:5-26, which
		-- assigns `obsidian.api`, `obsidian.commands`, etc. but never
		-- `obsidian.lsp`). Calling `.lsp` on the main module returns nil and
		-- throws inside the BufEnter callback.
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "markdown",
			callback = function(args)
				local bufnr = args.buf
				local bufname = vim.api.nvim_buf_get_name(bufnr)
				if bufname == "" then
					return
				end
				local ok, workspace_dir =
					pcall(require("obsidian").api.resolve_workspace_dir, bufname)
				if ok and workspace_dir and workspace_dir ~= "" then
					-- Defer to BufEnter so the buffer is fully loaded (and so
					-- marksman has a chance to attach first if it wants to).
					-- Calling lsp.start too early on a scratch buffer races
					-- with the ftplugin and can leak orphan clients.
					vim.api.nvim_create_autocmd("BufEnter", {
						buffer = bufnr,
						once = true,
						callback = function()
							local lsp_ok, lsp_err = pcall(function()
								require("obsidian.lsp").start(bufnr)
							end)
							if not lsp_ok then
								vim.notify(
									"[obsidian.nvim] failed to start obsidian-ls: " .. tostring(lsp_err),
									vim.log.levels.WARN
								)
							end
						end,
					})
				end
			end,
		})
	end,
}
