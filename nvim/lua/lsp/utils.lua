-- Shared LSP utilities and configuration
local M = {}

-- LSP settings: This function gets run when an LSP connects to a particular buffer
M.on_attach = function(client, bufnr)
  local nmap = function(keys, func, desc)
    if desc then
      desc = 'LSP: ' .. desc
    end
    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end

  nmap('<leader>rn', vim.lsp.buf.rename, '󰏫 [R]e[n]ame')
  nmap('<leader>ca', vim.lsp.buf.code_action, '󰅱 [C]ode [A]ction')
  nmap('gd', vim.lsp.buf.definition, '󰒋 [G]oto [D]efinition')
  nmap('gr', function() Snacks.picker.lsp_references() end, '󰒋 [G]oto [R]eferences')
  nmap('gI', vim.lsp.buf.implementation, '󰒋 [G]oto [I]mplementation')
  nmap('<leader>D', vim.lsp.buf.type_definition, '󰒋 Type [D]efinition')
  nmap('<leader>ds', function() Snacks.picker.lsp_symbols() end, '󰒋 [D]ocument [S]ymbols')
  nmap('<leader>ws', function() Snacks.picker.lsp_workspace_symbols() end, '󰒋 [W]orkspace [S]ymbols')

  -- See `:help K` for why this keymap
  nmap('K', vim.lsp.buf.hover, '󰍉 Hover Documentation')
  nmap('<C-k>', vim.lsp.buf.signature_help, '󰍉 Signature Documentation')

  -- Lesser used LSP functionality
  nmap('gD', vim.lsp.buf.declaration, '󰒋 [G]oto [D]eclaration')
  nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '󰅱 [W]orkspace [A]dd Folder')
  nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '󰅱 [W]orkspace [R]emove Folder')
  nmap('<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, '󰅱 [W]orkspace [L]ist Folders')

  -- Format buffer (handled globally by conform.nvim)
  -- nmap('<leader>ll', vim.lsp.buf.format, '󰅱 Format')

  -- Create a command `:Format` local to the LSP buffer (handled globally by conform.nvim)
  -- vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
  --   vim.lsp.buf.format()
  -- end, { desc = 'Format current buffer with LSP' })
end

-- Get capabilities with nvim-cmp support
M.get_capabilities = function()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
  if ok then
    capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
  end
  return capabilities
end

-- Make runtime files discoverable to Lua LSP
M.get_lua_runtime_path = function()
  local runtime_path = vim.split(package.path, ';')
  table.insert(runtime_path, 'lua/?.lua')
  table.insert(runtime_path, 'lua/?/init.lua')
  return runtime_path
end

return M
