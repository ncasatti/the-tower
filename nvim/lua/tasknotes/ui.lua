-- TaskNotes — shared UI: Snacks picker view, color engine, rank tables.
-- Available to every picker (this is the layer that the old single-file
-- layout could not share with pick_file because it was declared too late).

local api = require("tasknotes.api")
local config = require("tasknotes.config")

local M = {}

-- ──────────────────────────────────────────────────────────────────────
-- Shared Snacks picker view: narrow 0.4 preview + <Tab> dive-into-preview
-- (<Esc>/<S-Tab> back). Reused by pick_file (tasks) AND note_search
-- (whole-vault notes) so both render and navigate identically.
-- ──────────────────────────────────────────────────────────────────────
M.picker_view = {
	layout = {
		layout = {
			box = "horizontal",
			width = 0.92,
			height = 0.9,
			{
				box = "vertical",
				border = "rounded",
				title = "{title}",
				title_pos = "center",
				{ win = "input", height = 1, border = "bottom" },
				{ win = "list", border = "none" },
			},
			{ win = "preview", title = "{preview}", border = "rounded", width = 0.4 },
		},
	},
	win = {
		input = {
			keys = {
				["<Tab>"] = { "focus_preview", mode = { "i", "n" } },
			},
		},
		list = {
			keys = {
				["<Tab>"] = "focus_preview",
			},
		},
		preview = {
			keys = {
				["<Esc>"] = "focus_list",
				["<S-Tab>"] = "focus_list",
			},
		},
	},
}

-- ──────────────────────────────────────────────────────────────────────
-- Rank tables for status/priority display order. Sourced from
-- /api/filter-options. Used by pick_file (pickers) and find_tasks (query).
-- ──────────────────────────────────────────────────────────────────────
function M.get_rank_tables()
	local opts = api.get_filter_options()
	local status_ranks = {}
	local priority_ranks = {}
	if opts and opts.statuses then
		for i, s in ipairs(opts.statuses) do
			status_ranks[s.value] = s.order or i
		end
	end
	if opts and opts.priorities then
		-- High priority first → invert the natural order
		local n = #opts.priorities
		for i, p in ipairs(opts.priorities) do
			priority_ranks[p.value] = n - (p.order or i) + 1
		end
	end
	return status_ranks, priority_ranks
end

-- Builds value→color maps for status and priority from /api/filter-options.
-- Mirrors get_rank_tables; colors are hex strings (or nil when unset).
function M.get_color_tables()
	local opts = api.get_filter_options()
	local status_colors, priority_colors = {}, {}
	if opts and opts.statuses then
		for _, s in ipairs(opts.statuses) do
			status_colors[s.value] = s.color
		end
	end
	if opts and opts.priorities then
		for _, p in ipairs(opts.priorities) do
			priority_colors[p.value] = p.color
		end
	end
	return status_colors, priority_colors
end

-- Resolves the status glyph from config.status_icons (user-tunable),
-- falling back to config.default_icon for unmapped statuses.
function M.icon_for_status(value)
	return (value and config.status_icons[value]) or config.default_icon
end

-- ──────────────────────────────────────────────────────────────────────
-- Color engine (live from /api/filter-options colors).
-- ──────────────────────────────────────────────────────────────────────

-- Defines (or refreshes) a vim highlight group for a status/priority color
-- and returns its name. Color is a hex string like "#1029e5".
function M.ensure_color_hl(prefix, value, color)
	if not color then
		return "Normal"
	end
	local name = prefix .. "_" .. value:gsub("[^%w]", "_")
	vim.api.nvim_set_hl(0, name, { fg = color })
	return name
end

-- Builds picker items for a list of filter-option entries
-- (each entry has value/label/color/order/icon/isCompleted).
function M.build_option_items(prefix, options, current)
	local items = {}
	for i, opt in ipairs(options) do
		local marker = (opt.value == current) and "● " or "  "
		local hl = M.ensure_color_hl(prefix, opt.value, opt.color)
		table.insert(items, {
			idx = i,
			text = marker .. opt.label,
			value = opt.value,
			label = opt.label,
			color = opt.color,
			hl = hl,
			order = opt.order or i,
		})
	end
	table.sort(items, function(a, b)
		return (a.order or 99) < (b.order or 99)
	end)
	for i, item in ipairs(items) do
		item.idx = i
	end
	return items
end

-- Snacks format function that colorizes the entire item text using
-- the precomputed hl group on item.hl. Safe with multi-byte markers (●).
function M.color_format(item, _picker)
	return { { item.text, item.hl or "Normal" } }
end

-- Snacks format for task rows: <status icon> <priority dot>  <title> <due>.
-- The icon and both colors are precomputed onto the item at build time
-- (item.icon / status_hl / priority_hl / time_hl) so this stays a pure,
-- per-redraw-cheap renderer that does not touch the API or define hl groups.
function M.task_row_format(item, _picker)
	local out = {
		{ item.icon or config.default_icon, item.status_hl or "Normal" },
		{ " " },
		{ config.priority_icon, item.priority_hl or "Comment" },
		{ "  " },
		{ item.title or item.text or "", "Normal" },
	}
	if item.time_info and item.time_info ~= "" then
		out[#out + 1] = { item.time_info, item.time_hl or "Comment" }
	end
	return out
end

return M
