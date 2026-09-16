-- nvim/lua/plugins/writing/ideadrop.lua
-- ideadrop.nvim: Visual character-based graph for Obsidian notes and
-- dedicated project-local todo list panel in a right-side split.
--
-- Integration policy:
--   * obsidian.nvim integration is explicitly DISABLED (`obsidian.enabled = false`)
--     to prevent legacy commands and conflicting keybindings from interfering with
--     our native obsidian.lua configuration.
--   * Graph visualization scans the global Zettelkasten vault (~/.the-grid/zettelkasten).
--   * Todo list panel dynamically targets `.todo.md` in the current working directory (`cwd`).
--   * Local Graph mode (<leader>og / :IdeaGraphLocal): Pure radial circular geometry.
--   * Global Graph mode (<leader>oG / :IdeaGraph).
--   * Colemak navigation (u = up, e = down, n = left, i = right) to move node selection.
--   * Pan viewport support (U/E/N/I and Arrow keys) when zoomed in.
--   * 'l' toggles labels cleanly without moving right.
--   * Full Ayu / cool-retro-phosphor color palette matching terminal and neovim-ayu.
--   * Improved line drawing (spaced dots) preventing solid line artifacts in IBM 3270 font.
--   * Smart label positioning (left nodes -> label on left; right nodes -> label on right).
--   * Minimalist header (| note-name | X nodes | Y edges |) without emojis or noisy popups.
--   * Side-note split opened at 35% width with standard buffer editing.

local M = {}

function M.open_local_graph()
	local cur_buf = vim.api.nvim_get_current_buf()
	local cur_file = vim.api.nvim_buf_get_name(cur_buf)

	if cur_file == "" or not cur_file:match("%.md$") then
		vim.notify("Abrí una nota Markdown primero para ver su grafo local", vim.log.levels.WARN)
		return
	end

	local vault_dir = vim.fn.expand("~/.the-grid/zettelkasten"):gsub("/$", "")
	local rel_path = cur_file
	if cur_file:sub(1, #vault_dir) == vault_dir then
		rel_path = cur_file:sub(#vault_dir + 2)
	end
	local note_id = rel_path:gsub("%.md$", "")
	local base_name = vim.fn.fnamemodify(cur_file, ":t:r")

	local graph_mod = require("ideaDrop.ui.graph")

	-- Open graph window silently
	graph_mod.open()

	local graph = graph_mod.get_graph()
	if not graph then
		return
	end

	-- Find target node by ID or basename
	local target_node = graph.nodes[note_id]
	if not target_node then
		local base_lower = base_name:lower()
		for _, n in ipairs(graph.node_list) do
			if n.id:lower() == note_id:lower() or vim.fn.fnamemodify(n.id, ":t:r"):lower() == base_lower then
				target_node = n
				break
			end
		end
	end

	if not target_node then
		vim.notify("Nota no encontrada en el grafo de Zettelkasten: " .. base_name, vim.log.levels.WARN)
		return
	end

	-- Identify direct 1-hop connections (links + backlinks)
	local neighborhood = { [target_node.id] = true }
	for _, edge in ipairs(graph.edges) do
		if edge.source == target_node.id then
			neighborhood[edge.target] = true
		end
		if edge.target == target_node.id then
			neighborhood[edge.source] = true
		end
	end

	local visible_count = 0
	for _, node in ipairs(graph.node_list) do
		local is_neighbor = (neighborhood[node.id] == true)
		node.visible = is_neighbor
		if is_neighbor then
			visible_count = visible_count + 1
		end
	end

	local visible_edges = 0
	for _, edge in ipairs(graph.edges) do
		local is_edge_visible = (neighborhood[edge.source] == true and neighborhood[edge.target] == true)
		edge.visible = is_edge_visible
		if is_edge_visible then
			visible_edges = visible_edges + 1
		end
	end

	local win = vim.api.nvim_get_current_win()
	local width = vim.api.nvim_win_get_width(win) - 2
	local height = vim.api.nvim_win_get_height(win) - 4

	-- Place center node directly in the middle
	target_node.x = width / 2
	target_node.y = height / 2

	local neighbors = {}
	for id, _ in pairs(neighborhood) do
		if id ~= target_node.id and graph.nodes[id] then
			table.insert(neighbors, graph.nodes[id])
		end
	end

	-- Sort neighbors alphabetically so placement is predictable
	table.sort(neighbors, function(a, b)
		return a.name < b.name
	end)

	local n_count = #neighbors
	local radius_x = math.min(width * 0.35, 36)
	local radius_y = math.min(height * 0.36, 11)
	for i, n in ipairs(neighbors) do
		local angle = (i - 1) * (2 * math.pi / math.max(1, n_count))
		n.x = math.floor((width / 2) + radius_x * math.cos(angle) + 0.5)
		n.y = math.floor((height / 2) + radius_y * math.sin(angle) + 0.5)
	end

	-- Set initial selection to center note
	local _, state = debug.getupvalue(graph_mod.is_open, 1)
	local _, update_display = debug.getupvalue(graph_mod.refresh, 4)

	if state and state.view then
		state.view.selected_node = target_node.id
		state.view.offset_x = 0
		state.view.offset_y = 0
		state.view.zoom = 1.0
	end

	if update_display then
		update_display()
	end

	-- Minimalist window header: | note-name | X nodes | Y edges |
	if state and state.win and vim.api.nvim_win_is_valid(state.win) then
		local title =
			string.format(" │ %s │ %d nodes │ %d edges │ ", target_node.name, visible_count, visible_edges)
		vim.api.nvim_win_set_config(state.win, {
			title = title,
			title_pos = "center",
		})
	end
end

return {
	"CarGDev/ideadrop.nvim",
	cmd = {
		"IdeaGraph",
		"IdeaGraphLocal",
		"IdeaGraphFilter",
		"IdeaGraphClearCache",
		"IdeaTodo",
		"IdeaTodoAdd",
	},
	keys = {
		{
			"<leader>og",
			function()
				M.open_local_graph()
			end,
			desc = "Local Graph",
		},
		{ "<leader>oG", "<cmd>IdeaGraph<cr>", desc = "Global Graph" },
		{ "<leader>,", "<cmd>IdeaTodo<cr>", desc = "Todo (.todo.md)" },
	},
	opts = {
		graph = {
			animate = true,
			show_orphans = true,
			show_labels = true,
		},
		todo = {
			file = ".todo.md",
			width = 0.35,
		},
		obsidian = {
			enabled = false,
			auto_keymaps = false,
		},
	},
	config = function(_, opts)
		local config = require("ideaDrop.core.config")
		local renderer = require("ideaDrop.ui.graph.renderer")
		local cache = require("ideaDrop.ui.graph.cache")
		local data = require("ideaDrop.ui.graph.data")
		local constants = require("ideaDrop.utils.constants")
		local sidebar = require("ideaDrop.ui.sidebar")
		local graph_mod = require("ideaDrop.ui.graph")

		local VISUAL = constants.GRAPH_SETTINGS.VISUAL
		local COLORS = constants.GRAPH_SETTINGS.COLORS

		-- Clean title without emoji
		constants.GRAPH_SETTINGS.WINDOW.TITLE = " │ Graph │ "

		-- Side-split for notes: 45% width with standard buffer editing
		sidebar.open_right_side = function(file)
			if not file or file == "" then
				return
			end
			local width = math.floor(vim.o.columns * 0.45)

			local target_win = nil
			for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
				if vim.w[win].is_side_note and vim.api.nvim_win_is_valid(win) then
					target_win = win
					break
				end
			end

			if target_win then
				vim.api.nvim_set_current_win(target_win)
			else
				vim.cmd("botright vsplit")
				target_win = vim.api.nvim_get_current_win()
				vim.w[target_win].is_side_note = true
				vim.api.nvim_win_set_width(target_win, width)
				vim.wo[target_win].winfixwidth = true
			end

			vim.cmd("edit " .. vim.fn.fnameescape(file))
		end

		-- Silence noisy startup notifications and enforce minimalist header on global graph
		local orig_graph_open = graph_mod.open
		graph_mod.open = function(gopts)
			local orig_notify = vim.notify
			vim.notify = function(msg, level, nopts)
				if
					type(msg) == "string"
					and (
						msg:find("🕸️")
						or msg:find("Laying out")
						or msg:find("Graph:")
						or msg:find("Cache:")
						or msg:find("Grafo local")
					)
				then
					return
				end
				return orig_notify(msg, level, nopts)
			end

			orig_graph_open(gopts)
			vim.notify = orig_notify

			local _, state = debug.getupvalue(graph_mod.is_open, 1)
			if state and state.win and vim.api.nvim_win_is_valid(state.win) and state.graph then
				local stats = data.get_statistics(state.graph)
				local title = string.format(
					" │ Zettelkasten │ %d nodes │ %d edges │ %d orphans │ ",
					stats.total_nodes,
					stats.total_edges,
					stats.orphan_nodes
				)
				vim.api.nvim_win_set_config(state.win, {
					title = title,
					title_pos = "center",
				})
			end
		end

		-- Hook setup_highlights to enforce transparent background + Ayu Phosphor palette
		local orig_setup_highlights = renderer.setup_highlights
		renderer.setup_highlights = function()
			orig_setup_highlights()
			vim.api.nvim_set_hl(0, "IdeaDropGraphBackground", { bg = "NONE", ctermbg = "NONE" })
			vim.api.nvim_set_hl(0, "IdeaDropGraphNode", { fg = "#59c2ff", bold = true })
			vim.api.nvim_set_hl(0, "IdeaDropGraphNodeHighDegree", { fg = "#ff8f40", bold = true })
			vim.api.nvim_set_hl(0, "IdeaDropGraphNodeSelected", { fg = "#0a0e14", bg = "#e6b450", bold = true })
			vim.api.nvim_set_hl(0, "IdeaDropGraphEdge", { fg = "#3d4b53" })
			vim.api.nvim_set_hl(0, "IdeaDropGraphLabel", { fg = "#bfbdb6" })
		end

		-- Improved draw_line: Alternate dots on horizontal spans to prevent solid line artifacts in IBM 3270 font
		local function improved_draw_line(canvas, x1, y1, x2, y2, char)
			char = char or "·"
			x1 = math.floor(x1 + 0.5)
			y1 = math.floor(y1 + 0.5)
			x2 = math.floor(x2 + 0.5)
			y2 = math.floor(y2 + 0.5)

			local dx = math.abs(x2 - x1)
			local dy = math.abs(y2 - y1)
			local sx = x1 < x2 and 1 or -1
			local sy = y1 < y2 and 1 or -1
			local err = dx - dy
			local max_iter = math.max(dx, dy) * 2 + 10
			local iter = 0

			while true do
				iter = iter + 1
				if iter > max_iter then
					break
				end

				-- On horizontal slopes, draw every 2nd dot to avoid dash-line merging in monospace fonts
				local draw_this = true
				if dx > dy * 1.3 and (x1 % 2 ~= 0) then
					draw_this = false
				end

				if draw_this and x1 >= 1 and x1 <= canvas.width and y1 >= 1 and y1 <= canvas.height then
					local current = canvas.buffer[y1][x1]
					if current == " " or current == "·" then
						canvas.buffer[y1][x1] = char
						table.insert(canvas.highlights, {
							group = COLORS.EDGE,
							line = y1 - 1,
							col_start = x1 - 1,
							col_end = x1,
						})
					end
				end

				if x1 == x2 and y1 == y2 then
					break
				end
				local e2 = 2 * err
				if e2 > -dy then
					err = err - dy
					x1 = x1 + sx
				end
				if e2 < dx then
					err = err + dx
					y1 = y1 + sy
				end
			end
		end

		-- Improved draw_label: Smart placement (left nodes -> label on left, right nodes -> label on right)
		local function improved_draw_label(canvas, node, view)
			if not node.visible or not view.show_labels then
				return
			end

			local x = math.floor(node.x + 0.5)
			local y = math.floor(node.y + 0.5)

			local is_selected = (node.id == view.selected_node)
			local label = node.name
			if #label > VISUAL.LABEL_MAX_LENGTH then
				label = label:sub(1, VISUAL.LABEL_MAX_LENGTH - 3) .. "..."
			end

			local label_x
			if math.abs(x - canvas.width / 2) < 4 then
				label_x = x + 2
			elseif x < canvas.width / 2 then
				label_x = x - #label - 2
			else
				label_x = x + 2
			end

			local label_y = y
			if label_x < 1 then
				label_x = 1
			end
			if label_x + #label > canvas.width then
				label_x = canvas.width - #label
			end

			local hl_group = is_selected and COLORS.NODE_SELECTED or COLORS.LABEL
			if label_y >= 1 and label_y <= canvas.height then
				for i = 1, #label do
					local char_x = label_x + i - 1
					if char_x >= 1 and char_x <= canvas.width then
						local cur = canvas.buffer[label_y][char_x]
						-- Never overwrite node characters
						if cur ~= "●" and cur ~= "•" then
							canvas.buffer[label_y][char_x] = label:sub(i, i)
							table.insert(canvas.highlights, {
								group = hl_group,
								line = label_y - 1,
								col_start = char_x - 1,
								col_end = char_x,
							})
						end
					end
				end
			end
		end

		-- Inject improved line drawing and label positioning into renderer
		debug.setupvalue(renderer.render, 2, improved_draw_line)
		debug.setupvalue(renderer.render, 4, improved_draw_label)

		-- Patch cache scanning to ignore .stversions, .git, .trash
		local orig_scan = cache.scan_files_fast
		cache.scan_files_fast = function(idea_dir)
			local files = orig_scan(idea_dir)
			local clean = {}
			for _, f in ipairs(files) do
				if not f:find("/%.stversions/") and not f:find("/%.git/") and not f:find("/%.trash/") then
					table.insert(clean, f)
				end
			end
			return clean
		end

		-- Fix resolve_link: handle spaces and hyphens symmetrically
		data.resolve_link = function(link_text, idea_dir, existing_files)
			local raw_lower = link_text:lower():gsub("^%s*(.-)%s*$", "%1")
			local with_hyphens = raw_lower:gsub("%s+", "-")
			local with_spaces = raw_lower:gsub("%-+", " ")

			if existing_files[raw_lower] then
				return existing_files[raw_lower]
			end
			if existing_files[with_hyphens] then
				return existing_files[with_hyphens]
			end
			if existing_files[with_spaces] then
				return existing_files[with_spaces]
			end

			local link_base = vim.fn.fnamemodify(link_text, ":t"):lower():gsub("^%s*(.-)%s*$", "%1")
			local base_hyphens = link_base:gsub("%s+", "-")
			local base_spaces = link_base:gsub("%-+", " ")

			if existing_files[link_base] then
				return existing_files[link_base]
			end
			if existing_files[base_hyphens] then
				return existing_files[base_hyphens]
			end
			if existing_files[base_spaces] then
				return existing_files[base_spaces]
			end

			for name, path in pairs(existing_files) do
				local file_base = vim.fn.fnamemodify(name, ":t:r"):lower()
				if file_base == link_base or file_base == base_hyphens or file_base == base_spaces then
					return path
				end
			end
			return nil
		end

		require("ideaDrop").setup(opts)

		-- Force graph to scan the global Zettelkasten vault
		config.get_idea_dir = function()
			return vim.fn.expand("~/.the-grid/zettelkasten")
		end

		-- Direct Todo list panel to dynamically read/write `.todo.md` in cwd
		rawset(config.options, "idea_dir", nil)
		setmetatable(config.options, {
			__index = function(_, k)
				if k == "idea_dir" then
					return vim.fn.getcwd()
				end
			end,
		})

		-- User command for local graph
		vim.api.nvim_create_user_command("IdeaGraphLocal", function()
			M.open_local_graph()
		end, {
			desc = "Open local graph for current note and its connections",
		})

		-- Graph Buffer Keymaps (Colemak navigation, panning, and label toggle)
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "ideadrop-graph",
			callback = function(args)
				local buf = args.buf

				local _, state = debug.getupvalue(graph_mod.open, 1)
				local _, update_display = debug.getupvalue(graph_mod.open, 9)

				local function pan(dx, dy)
					if state and state.view then
						state.view.offset_x = state.view.offset_x + dx
						state.view.offset_y = state.view.offset_y + dy
						if update_display then
							update_display()
						end
					end
				end

				local function toggle_labels()
					if state and state.view then
						state.view.show_labels = not state.view.show_labels
						if update_display then
							update_display()
						end
					end
				end

				local kopts = { remap = true, buffer = buf, silent = true }

				-- Colemak node navigation
				vim.keymap.set("n", "u", "k", kopts) -- Up
				vim.keymap.set("n", "e", "j", kopts) -- Down
				vim.keymap.set("n", "n", "h", kopts) -- Left
				vim.keymap.set("n", "i", "l", kopts) -- Right

				-- Labels: lowercase 'l' toggles labels ON/OFF directly
				vim.keymap.set("n", "l", toggle_labels, { buffer = buf, silent = true, desc = "Toggle labels" })

				-- Viewport Panning (Colemak uppercase U/E/N/I and Arrow keys)
				vim.keymap.set("n", "U", function()
					pan(0, 3)
				end, { buffer = buf, silent = true, desc = "Pan up" })
				vim.keymap.set("n", "E", function()
					pan(0, -3)
				end, { buffer = buf, silent = true, desc = "Pan down" })
				vim.keymap.set("n", "N", function()
					pan(6, 0)
				end, { buffer = buf, silent = true, desc = "Pan left" })
				vim.keymap.set("n", "I", function()
					pan(-6, 0)
				end, { buffer = buf, silent = true, desc = "Pan right" })

				vim.keymap.set("n", "<Up>", function()
					pan(0, 3)
				end, { buffer = buf, silent = true, desc = "Pan up" })
				vim.keymap.set("n", "<Down>", function()
					pan(0, -3)
				end, { buffer = buf, silent = true, desc = "Pan down" })
				vim.keymap.set("n", "<Left>", function()
					pan(6, 0)
				end, { buffer = buf, silent = true, desc = "Pan left" })
				vim.keymap.set("n", "<Right>", function()
					pan(-6, 0)
				end, { buffer = buf, silent = true, desc = "Pan right" })
			end,
		})
	end,
}
