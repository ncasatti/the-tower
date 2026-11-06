-- HCL outline: list the blocks of a .hcl file as a pickable index.
--
-- Why this exists: terraform-ls implements the `terraform` and `terraform-vars`
-- language ids only. A generic .hcl file — the kind pylon manifests use, with
-- `system "x" { }` and `capability "y" { }` blocks — gets no LSP at all, so
-- `leader+ss` (Snacks.picker.lsp_symbols) finds nothing. The file still has a
-- clear structure, and the tree-sitter-hcl grammar exposes it: a `block` node
-- carries an `identifier` (the block type) and usually a `string_lit` (the
-- block's label).
--
-- This module reads that structure directly from the parse tree and feeds it
-- to a Snacks picker, so the outline works on any HCL file regardless of
-- whether an LSP is attached.
--
-- `<leader>ss` is overridden buffer-locally in HCL buffers: here it is the
-- treesitter outline, elsewhere it stays the LSP symbols picker. One key, and
-- it means "show me the index of this file" in every filetype.
local M = {}

---@class hcl.outline.Item
---@field text string
---@field kind string
---@field label string?
---@field depth integer
---@field lnum integer

---Collect the blocks of an HCL buffer, in document order.
---@param bufnr integer
---@return hcl.outline.Item[]?, string? items, err
function M.collect_blocks(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "hcl")
  if not ok or not parser then
    return nil, "no hcl parser available"
  end

  local trees = parser:parse()
  local tree = trees and trees[1]
  if not tree then
    return nil, "no parse tree"
  end

  local items = {}

  ---@param node TSNode
  ---@param depth integer
  local function walk(node, depth)
    if node:type() == "block" then
      local kind, label, kind_row
      for child in node:iter_children() do
        local t = child:type()
        if t == "identifier" and not kind then
          kind = vim.treesitter.get_node_text(child, bufnr)
          kind_row = child:start()
        elseif t == "string_lit" and not label then
          -- The label is the first string literal that is a DIRECT child of the
          -- block. A string literal nested in an attribute's expression is not
          -- a label.
          label = vim.treesitter.get_node_text(child, bufnr)
          label = label:gsub('^"', ""):gsub('"$', "")
        end
      end

      if kind then
        local text = kind
        if label and label ~= "" then
          text = kind .. ' "' .. label .. '"'
        end
        table.insert(items, {
          text = text,
          kind = kind,
          label = label,
          depth = depth,
          lnum = kind_row,
        })
      end
    end

    for child in node:iter_children() do
      -- A block's contents live in its `body` child; descending into it
      -- increases the depth so nested blocks read as children of their parent.
      local child_depth = depth
      if node:type() == "block" and child:type() == "body" then
        child_depth = depth + 1
      end
      walk(child, child_depth)
    end
  end

  walk(tree:root(), 0)
  return items
end

---Open the outline picker for a buffer.
---@param opts? snacks.picker.Config
function M.outline(opts)
  opts = opts or {}
  local bufnr = opts.buf or vim.api.nvim_get_current_buf()

  local items, err = M.collect_blocks(bufnr)
  if not items or #items == 0 then
    -- Fall back to the LSP picker: in a buffer with a documentSymbol provider
    -- (terraform files, markdown) that is the better index anyway.
    local has_lsp = false
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
      if client.server_capabilities.documentSymbolProvider then
        has_lsp = true
        break
      end
    end
    if has_lsp then
      vim.notify("HCL outline: no HCL blocks, using LSP symbols", vim.log.levels.INFO)
      return Snacks.picker.lsp_symbols(vim.tbl_extend("force", opts, { buf = bufnr }))
    end
    vim.notify(
      "HCL outline: " .. (err or "no blocks found") .. " — is the hcl parser installed?",
      vim.log.levels.WARN
    )
    return
  end

  return Snacks.picker.pick({
    items = items,
    -- snacks' format returns a list of { text, hl } entries, not a bare string.
    format = function(item)
      -- Indent by depth so nested blocks read as a tree.
      return { { string.rep("  ", item.depth) .. item.text } }
    end,
    layout = { preset = "select" },
    title = "HCL outline",
    preview = "none",
    confirm = function(picker, item)
      picker:close()
      if item and item.lnum then
        pcall(vim.api.nvim_win_set_cursor, 0, { item.lnum + 1, 0 })
        vim.cmd("normal! zz")
      end
    end,
  })
end

---Override `<leader>ss` in HCL buffers with the treesitter outline.
---
-- Registered on FileType rather than on LSP attach: a generic .hcl file never
-- gets an LSP, so an attach-time hook would never run for it.
function M.setup()
  local group = vim.api.nvim_create_augroup("HclOutline", { clear = true })

  local function apply(bufnr)
    vim.keymap.set("n", "<leader>ss", function()
      require("lsp.hcl-outline").outline({ buf = bufnr })
    end, { buffer = bufnr, desc = "HCL outline (blocks)" })
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "hcl", "terraform", "terraform-vars" },
    callback = function(args)
      apply(args.buf)
    end,
  })

  -- The plugin that calls setup() may load AFTER a buffer was already opened
  -- (lazy.nvim defers plugin loading, and a file passed on the command line is
  -- opened during startup). Those buffers never fire FileType again, so apply
  -- the map to them now.
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
      if ft == "hcl" or ft == "terraform" or ft == "terraform-vars" then
        apply(bufnr)
      end
    end
  end
end

return M
