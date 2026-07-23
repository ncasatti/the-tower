local M = {}

local namespace = vim.api.nvim_create_namespace("markdown_active_scope")
local lifecycle_group = vim.api.nvim_create_augroup("MarkdownActiveScope", { clear = false })
local attached = {}
local windows = {}
local scope_keys = {}
local scope_buffers = {}
local redraw_pending = {}
local provider_started = false
local repeat_linebreak = vim.fn.has("nvim-0.10") == 1

local defaults = {
	per_level = 2,
	skip_level = 0,
	char = "│",
	highlight = "RenderMarkdownIndentActive",
	priority = 200,
	enabled = function()
		return true
	end,
}

---@param level integer
---@param opts? table
---@return integer[]
function M.guide_columns(level, opts)
	opts = vim.tbl_extend("force", defaults, opts or {})
	local visible_levels = math.max(level - opts.skip_level, 0)
	if visible_levels == 0 then
		return {}
	end
	return { (visible_levels - 1) * opts.per_level }
end

local function heading_level(section, buf)
	for child in section:iter_children() do
		local kind = child:type()
		if kind == "atx_heading" then
			local text = vim.treesitter.get_node_text(child, buf)
			local marker = text:match("^(#+)")
			return marker and #marker or nil
		elseif kind == "setext_heading" then
			local text = vim.treesitter.get_node_text(child, buf)
			local underline = text:match("\n([=-]+)%s*$")
			return underline and underline:sub(1, 1) == "=" and 1 or 2
		end
	end
	return nil
end

---@class markdown.active_scope.Scope
---@field level integer
---@field from integer 0-indexed inclusive row
---@field to integer 0-indexed exclusive row

---@param buf integer
---@param row integer 0-indexed row
---@return markdown.active_scope.Scope?
function M.get_scope(buf, row)
	if not vim.api.nvim_buf_is_valid(buf) then
		return nil
	end

	local ok, node = pcall(vim.treesitter.get_node, {
		bufnr = buf,
		pos = { row, 0 },
		ignore_injections = true,
	})
	if not ok then
		return nil
	end

	while node and node:type() ~= "section" do
		node = node:parent()
	end
	if not node then
		return nil
	end

	local level = heading_level(node, buf)
	if not level then
		return nil
	end

	local from, _, to = node:range()
	return { level = level, from = from, to = to }
end

local function scope_key(buf, scope)
	if not scope then
		return string.format("%d:none", buf)
	end
	return string.format("%d:%d:%d:%d", buf, scope.level, scope.from, scope.to)
end

local function clear_window(win)
	windows[win] = nil
	scope_keys[win] = nil
	scope_buffers[win] = nil
	redraw_pending[win] = nil
end

local function clear_window_state(buf)
	for win, active_buf in pairs(scope_buffers) do
		if active_buf == buf then
			clear_window(win)
		end
	end
end

local function start_provider()
	if provider_started then
		return
	end
	provider_started = true

	vim.api.nvim_create_autocmd("WinClosed", {
		group = lifecycle_group,
		callback = function(args)
			local win = tonumber(args.match)
			if win then
				clear_window(win)
			end
		end,
	})

	vim.api.nvim_set_decoration_provider(namespace, {
		on_win = function(_, win, buf)
			local opts = attached[buf]
			local enabled_ok, enabled = pcall(function()
				return opts and opts.enabled(buf, win)
			end)
			if not enabled_ok or not enabled then
				clear_window(win)
				if opts then
					scope_buffers[win] = buf
				end
				return false
			end
			scope_buffers[win] = buf

			local cursor = vim.api.nvim_win_get_cursor(win)
			local scope = M.get_scope(buf, cursor[1] - 1)
			if not scope then
				windows[win] = nil
				return false
			end

			local view = vim.api.nvim_win_call(win, vim.fn.winsaveview)
			windows[win] = {
				buf = buf,
				cursor_row = cursor[1] - 1,
				scope = scope,
				columns = M.guide_columns(scope.level, opts),
				leftcol = view.leftcol,
				opts = opts,
			}
			return true
		end,
		on_line = function(_, win, buf, row)
			local state = windows[win]
			if not state or not attached[buf] then
				return
			end

			local scope = state.scope
			if row == state.cursor_row or row <= scope.from or row >= scope.to then
				return
			end

			for _, column in ipairs(state.columns) do
				local win_column = column - state.leftcol
				if win_column >= 0 then
					vim.api.nvim_buf_set_extmark(buf, namespace, row, 0, {
						ephemeral = true,
						virt_text = { { state.opts.char, state.opts.highlight } },
						virt_text_pos = "overlay",
						virt_text_win_col = win_column,
						hl_mode = "combine",
						priority = state.opts.priority,
						virt_text_repeat_linebreak = repeat_linebreak and vim.wo[win].breakindent and vim.wo[win].wrap
							or nil,
					})
				end
			end
		end,
	})
end

---@param buf integer
---@param opts? table
---@return boolean
function M.attach(buf, opts)
	if not vim.api.nvim_buf_is_valid(buf) then
		return false
	end
	if attached[buf] then
		attached[buf] = vim.tbl_extend("force", defaults, opts or {})
		clear_window_state(buf)
		vim.cmd.redraw()
		return true
	end
	attached[buf] = vim.tbl_extend("force", defaults, opts or {})
	start_provider()
	vim.api.nvim_create_autocmd({ "BufEnter", "CursorMoved", "CursorMovedI", "TextChanged", "TextChangedI" }, {
		group = lifecycle_group,
		buffer = buf,
		callback = function()
			local win = vim.api.nvim_get_current_win()
			if vim.api.nvim_win_get_buf(win) ~= buf then
				return
			end

			local row = vim.api.nvim_win_get_cursor(win)[1] - 1
			scope_buffers[win] = buf
			local key = scope_key(buf, M.get_scope(buf, row))
			if scope_keys[win] == key then
				return
			end
			scope_keys[win] = key
			if redraw_pending[win] then
				return
			end
			redraw_pending[win] = true
			vim.schedule(function()
				redraw_pending[win] = nil
				if attached[buf] and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
					vim.cmd("redraw")
				end
			end)
		end,
	})
	vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
		group = lifecycle_group,
		buffer = buf,
		once = true,
		callback = function()
			attached[buf] = nil
			clear_window_state(buf)
		end,
	})
	vim.cmd.redraw()
	return true
end

---@param buf integer
---@return boolean
function M.is_attached(buf)
	return attached[buf] ~= nil
end

return M
