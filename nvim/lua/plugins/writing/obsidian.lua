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
		{ "<leader>og", "<cmd>Obsidian grep<cr>", desc = "Grep Notes" },

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
		{ "<leader>oi", "<cmd>Obsidian paste_img<cr>", desc = "Paste Image" },
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
			ui = { enable = true },

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

		-- Disable documentSymbol on obsidian-ls (marksman provides cleaner rendered symbols)
		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(args)
				local client = vim.lsp.get_client_by_id(args.data.client_id)
				if client and client.name == "obsidian-ls" then
					client.server_capabilities.documentSymbolProvider = false
				end
			end,
		})
	end,
}
