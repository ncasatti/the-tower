-- TaskNotes — hidden frontmatter (leaf view).
--
-- Conceals the frontmatter rows of a task note with a `conceal_lines`
-- extmark in its own namespace (`tasknotes_frontmatter`), so the note
-- opens on its body instead of on its YAML block (ADR-010).
--
-- The closing `---` fence stays VISIBLE: concealing it would also hide
-- the inline card, whose virtual lines are anchored on that row. Only
-- the rows above the fence are concealed (rows 0 .. fm_end_row - 1).
--
-- The buffer text is never touched: the extmark hides rows without
-- changing a single character, `modified` stays false and 'conceallevel'
-- is never lowered (ADR-010).
--
-- Like the card, this module is a leaf: it reads the in-memory cache
-- only and never performs a request. It must not require
-- `tasknotes.api`, `tasknotes.task_ops` or `plenary.curl` directly.

local card = require("tasknotes.card")
local config = require("tasknotes.config")

local M = {}

-- Dedicated namespace: clearing it reveals the frontmatter again and
-- touches nothing else.
M.ns = vim.api.nvim_create_namespace("tasknotes_frontmatter")

-- Global, session-scoped switch (on by default). `<leader>oh` flips it.
M.hidden = config.frontmatter_hidden ~= false

-- ──────────────────────────────────────────────────────────────────────
-- Buffer helpers
-- ──────────────────────────────────────────────────────────────────────

-- True when a buffer is a markdown file inside the vault.
local function is_vault_markdown(buf)
	local name = vim.api.nvim_buf_get_name(buf)
	if name == "" or not name:match("%.md$") then
		return false
	end
	local vault = vim.fs.normalize(config.vault_path)
	local abs = vim.fs.normalize(name)
	return abs:sub(1, #vault + 1) == vault .. "/"
end

-- Every loaded buffer that can carry a concealed frontmatter (a vault
-- markdown note).
local function vault_buffers()
	local out = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and is_vault_markdown(buf) then
			out[#out + 1] = buf
		end
	end
	return out
end

-- ──────────────────────────────────────────────────────────────────────
-- Public API
-- ──────────────────────────────────────────────────────────────────────

-- Conceals (or reveals) the frontmatter of a buffer.
--
-- The namespace is cleared first, so a stale conceal never survives a
-- redraw. A buffer that is not a task note — no context, no frontmatter
-- fence — is simply left alone.
function M.apply(buf)
	buf = buf or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)

	if not M.hidden then
		return
	end

	local ctx = card.context_for(buf)
	if not ctx or ctx.fm_end_row == nil then
		return
	end

	-- `end_row` is inclusive: the mark covers the rows 0 .. fm_end_row - 1,
	-- that is everything above the closing fence. The fence row itself is
	-- left visible so the inline card keeps its anchor.
	vim.api.nvim_buf_set_extmark(buf, M.ns, 0, 0, {
		end_row = ctx.fm_end_row - 1,
		end_col = 0,
		conceal_lines = "",
	})
end

-- Global toggle: flips the switch for the whole session and re-applies
-- it to every loaded vault buffer. Returns the new state.
function M.toggle()
	M.hidden = not M.hidden

	for _, buf in ipairs(vault_buffers()) do
		M.apply(buf)
	end

	vim.notify(
		string.format("TaskNotes: frontmatter %s", M.hidden and "hidden" or "shown"),
		vim.log.levels.INFO
	)

	return M.hidden
end

-- ──────────────────────────────────────────────────────────────────────
-- Autocmd wiring
--
-- The conceal follows the fence while the note is edited, is re-applied
-- on save, when the note is entered and whenever the task cache is
-- refreshed (the cache may land after the note was opened).
-- ──────────────────────────────────────────────────────────────────────
local DEBOUNCE_MS = 200

-- Debounce tokens, one per buffer.
local pending = {}

local function debounced_apply(buf)
	pending[buf] = (pending[buf] or 0) + 1
	local token = pending[buf]
	vim.defer_fn(function()
		if pending[buf] == token then
			pending[buf] = nil
			M.apply(buf)
		end
	end, DEBOUNCE_MS)
end

-- Registers the augroup that keeps the conceal in sync. Called once,
-- after the API health gate has passed.
--
-- The group is created with `clear = false`: the card and the panel
-- share it, and this module attaches after them.
function M.attach()
	local group = vim.api.nvim_create_augroup("TaskNotesViews", { clear = false })

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "BufWritePost" }, {
		group = group,
		pattern = "*.md",
		callback = function(ev)
			if is_vault_markdown(ev.buf) then
				M.apply(ev.buf)
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = group,
		pattern = "*.md",
		callback = function(ev)
			if is_vault_markdown(ev.buf) then
				debounced_apply(ev.buf)
			end
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "TaskNotesCacheRefreshed",
		callback = function()
			for _, buf in ipairs(vault_buffers()) do
				M.apply(buf)
			end
		end,
	})
end

return M
