-- Zettelkasten templates — .md → LuaSnip snippets.
--
-- Scans ~/.the-grid/zettelkasten/Templates/*.md and registers a LuaSnip
-- snippet per file. Markers {{name}} become stops; identical names mirror
-- (typing in one updates the other). Edit the .md, save → snippets auto-
-- reload (autocmd wired in the lazy spec). Manual fallback: <leader>owr.
--
-- Caveat: removing a template .md leaves its snippet registered until nvim
-- restart. add_snippets is idempotent for same trigger, so editing a
-- template updates in place — but deletion is not tracked.

local ls -- lazy-required on first reload()

local TEMPLATES_DIR = vim.fn.expand("~/.the-grid/zettelkasten/Templates")

-- { [abs_path] = { mtime = number, content = string } }
local file_cache = {}

local function read_cached(path)
	local uv = vim.uv or vim.loop
	local stat = uv.fs_stat(path)
	if not stat then
		return nil
	end

	local entry = file_cache[path]
	if entry and entry.mtime == stat.mtime then
		return entry.content
	end

	local lines = vim.fn.readfile(path)
	local content = table.concat(lines, "\n")
	file_cache[path] = { mtime = stat.mtime, content = content }
	return content
end

-- LuaSnip text_node expects a TABLE of lines (each element = one line,
-- no embedded \n). A multi-line string passed directly triggers
-- E5108-style errors inside util.lua:put(). Always split before wrapping.
local function text_lines(s)
	if s == "" then
		return ls.text_node({ "" })
	end
	return ls.text_node(vim.split(s, "\n", { plain = true }))
end

local function parse(content)
	local nodes = {}
	local stops = {} -- name -> stop_id (for mirrors)
	local next_id = 0
	local pos = 1

	while pos <= #content do
		local s, e, name = content:find("{{([%w_]+)}}", pos)
		if not s then
			table.insert(nodes, text_lines(content:sub(pos)))
			break
		end

		if s > pos then
			table.insert(nodes, text_lines(content:sub(pos, s - 1)))
		end

		local id = stops[name]
		if not id then
			next_id = next_id + 1
			id = next_id
			stops[name] = id
		end
		table.insert(nodes, ls.insert_node(id))

		pos = e + 1
	end

	table.insert(nodes, ls.insert_node(0))
	return nodes
end

local M = {}

function M.reload()
	ls = require("luasnip")

	local files = vim.fn.readdir(TEMPLATES_DIR)
	if not files then
		vim.notify("Zettelkasten templates: directory not found: " .. TEMPLATES_DIR, vim.log.levels.WARN)
		return
	end

	local count = 0
	for _, fname in ipairs(files) do
		if fname:match("%.md$") then
			local path = TEMPLATES_DIR .. "/" .. fname
			local content = read_cached(path)
			if content then
				local trig = fname:gsub("%.md$", "")
				local nodes = parse(content)
				ls.add_snippets("markdown", {
					ls.snippet({ trig = trig, dscr = "Template: " .. fname, priority = 1000 }, nodes),
				})
				count = count + 1
			end
		end
	end

	vim.notify(string.format("Zettelkasten: %d template(s) loaded", count), vim.log.levels.INFO)
end

return M
