for _, candidate in ipairs(vim.api.nvim_get_runtime_file("render-markdown.nvim/lua/render-markdown/init.lua", false)) do
	local dir = vim.fn.fnamemodify(candidate, ":h:h:h")
	package.path = table.concat({
		dir .. "/?.lua",
		dir .. "/?/init.lua",
		package.path,
	}, ";")
	break
end
for _, candidate in ipairs(vim.api.nvim_get_runtime_file("render-markdown.nvim/lua/render-markdown/init.lua", false)) do
	local dir = vim.fn.fnamemodify(candidate, ":h:h:h")
	package.path = table.concat({
		dir .. "/?.lua",
		dir .. "/?/init.lua",
		package.path,
	}, ";")
	break
end
local active_scope = require("markdown.active-scope")

local function assert_equal(actual, expected, label)
	if actual ~= expected then
		error(string.format("%s: expected %s, got %s", label, vim.inspect(expected), vim.inspect(actual)))
	end
end

local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(buf)
vim.bo[buf].filetype = "markdown"
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
	"# Root",
	"",
	"Root body",
	"## Workflow",
	"",
	"Workflow body",
	"### Tracer bullets",
	"",
	"Active body",
	"## Next section",
	"",
	"Next body",
})

vim.treesitter.get_parser(buf, "markdown"):parse()

local scope = assert(active_scope.get_scope(buf, 8), "expected an active Markdown scope")
assert_equal(scope.level, 3, "heading level")
assert_equal(scope.from, 6, "section start row")
assert_equal(scope.to, 9, "section end row")

local columns = active_scope.guide_columns(scope.level, { per_level = 2, skip_level = 0 })
assert_equal(vim.inspect(columns), vim.inspect({ 4 }), "deepest active guide column")

assert(active_scope.attach(buf), "first attachment should succeed")
assert(active_scope.attach(buf), "repeated attachment should be idempotent")
assert(active_scope.is_attached(buf), "buffer should report active-scope attachment")
local cursor_listeners = vim.api.nvim_get_autocmds({
	group = "MarkdownActiveScope",
	buffer = buf,
	event = "CursorMoved",
})
assert_equal(#cursor_listeners, 1, "scope-change cursor listener")

local original_cmd = vim.cmd
local redraws = 0
vim.cmd = function(command)
	if command == "redraw" then
		redraws = redraws + 1
		return
	end
	return original_cmd(command)
end

vim.api.nvim_win_set_cursor(0, { 9, 0 })
vim.api.nvim_exec_autocmds("CursorMoved", { buffer = buf })
vim.wait(20)
assert_equal(redraws, 1, "first scope redraw")

vim.api.nvim_exec_autocmds("CursorMoved", { buffer = buf })
vim.wait(20)
assert_equal(redraws, 1, "same scope does not redraw")

vim.api.nvim_win_set_cursor(0, { 6, 0 })
vim.api.nvim_exec_autocmds("CursorMoved", { buffer = buf })
vim.wait(20)
assert_equal(redraws, 2, "new scope redraw")
vim.cmd = original_cmd

local disposable = vim.api.nvim_create_buf(true, false)
assert(active_scope.attach(disposable), "disposable buffer should attach")
vim.api.nvim_buf_delete(disposable, { force = true })
assert(not active_scope.is_attached(disposable), "deleted buffer should release active-scope state")

local plugin_path = assert(
	vim.api.nvim_get_runtime_file("lua/plugins/writing/render-markdown.lua", false)[1],
	"render-markdown plugin spec should be available"
)
local plugin = dofile(plugin_path)
assert_equal(plugin.opts.indent.enabled, false, "vault indentation is globally disabled")
assert_equal(plugin.opts.indent.render_modes, true, "indent renders in all modes when vault_indent is on")

local disabled_buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(disabled_buf, vim.fn.expand("~/.the-grid/zettelkasten/disabled-test.md"))
require("render-markdown").setup(plugin.opts)
require("render-markdown.state").get(disabled_buf)
plugin.opts.on.attach({ buf = disabled_buf })
assert(not active_scope.is_attached(disabled_buf), "disabled experiment must not attach to vault buffers")

local indent_buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(indent_buf)
vim.api.nvim_buf_set_name(indent_buf, vim.fn.expand("~/.the-grid/zettelkasten/indent-only.md"))
vim.bo[indent_buf].filetype = "markdown"
vim.api.nvim_buf_set_lines(indent_buf, 0, -1, false, { "# H1", "", "## H2", "", "Body" })
vim.treesitter.get_parser(indent_buf, "markdown"):parse()
require("render-markdown.state").get(indent_buf)
plugin.opts.on.attach({ buf = indent_buf })

local config = require("render-markdown.state").get(indent_buf)
assert_equal(config.indent.enabled, true, "indent must enable on vault attach")
assert_equal(config.indent.render_modes, true, "indent must render in all modes")
assert_equal(config.pipe_table.border_virtual, false, "vault attach must NOT touch pipe_table.border_virtual")
assert_equal(vim.b[indent_buf].snacks_indent, nil, "indent-only mode leaves snacks_indent alone")
assert(not active_scope.is_attached(indent_buf), "active scope stays off by default")

-- Lock the code-block padding contract. The fenced-code renderer derives
-- `data.padding` and `data.margin` from `config.left_pad` and `config.left_margin`
-- (render/markdown/code.lua:53-55). At non-zero defaults each interior row gets
-- `line:pad(padding, RenderMarkdownCode)` injected as virt_text, and because
-- `RenderMarkdownCode → ColorColumn` by default that padding shows up as a
-- single-character vertical bar on the left of every fenced block. We keep all
-- three at zero so fenced code blocks visually hug the source text.
local global_config = require("render-markdown.state").get(0)
assert_equal(global_config.code.left_pad, 0, "code left_pad must stay zero to avoid phantom ColorColumn")
assert_equal(global_config.code.right_pad, 0, "code right_pad must stay zero to avoid phantom ColorColumn")
assert_equal(global_config.code.left_margin, 0, "code left_margin must stay zero to avoid phantom ColorColumn")

print("markdown active scope: ok")
