return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "j-hui/fidget.nvim",
    "hrsh7th/cmp-nvim-lsp",
    "neovim/nvim-lspconfig",
  },
  config = function()
    -- Diagnostic keymaps
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = "Diagnostic goto prev" })
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = "Diagnostic goto next" })
    vim.keymap.set('n', '<leader>le', vim.diagnostic.open_float, { desc = "Diagnostic float" })
    vim.keymap.set('n', '<leader>lq', vim.diagnostic.setloclist, { desc = "Diagnostic setloclist" })

    -- Setup mason so it can manage external tooling
    require('mason').setup()

    -- Language servers to auto-install via Mason
    local servers = {
      'clangd',
      'rust_analyzer',
      'pyright',
      'ts_ls',
      'gopls',
      'lua_ls',
      'jdtls',
      'kotlin_language_server',
      'jsonls',
      'yamlls',
      'bashls',
      'nil_ls',
      -- mason-lspconfig resolves these through the mason registry's
      -- `neovim.lspconfig` field: the package is `terraform-ls` but the
      -- lspconfig server name is `terraformls`. A package name here is
      -- rejected with "not a valid entry in ensure_installed".
      'terraformls',
    }

    -- Ensure the servers are installed
    require('mason-lspconfig').setup {
      ensure_installed = servers,
      -- mason-lspconfig auto-enables every installed mason package that maps
      -- to an lspconfig server, which would enable the builtin `terraformls`
      -- alongside our own `terraform_ls` config in servers/hcl.lua — two
      -- clients on the same binary, duplicated diagnostics. Ours is the one
      -- that covers all three HCL filetypes, so exclude the builtin.
      automatic_enable = {
        exclude = { 'terraformls' },
      },
    }

    -- Turn on LSP status information
    require('fidget').setup()

    -- Load shared utilities
    local utils = require('lsp.utils')
    local capabilities = utils.get_capabilities()
    local on_attach = utils.on_attach

    -- Load and configure all language servers from the servers/ directory
    local server_configs = {
      'clang',
      'rust',
      'python',
      'typescript',
      'go',
      'lua',
      'java',
      'kotlin',
      'json',
      'yaml',
      'markdown',
      'bash',
      'nix',
      'hcl',
    }

    -- Configure each server
    for _, server_name in ipairs(server_configs) do
      local ok, server_module = pcall(require, 'plugins.lsp.servers.' .. server_name)
      if ok then
        server_module.config(capabilities, on_attach)
      else
        vim.notify(
          string.format("Failed to load LSP server config: %s", server_name),
          vim.log.levels.WARN
        )
      end
    end

    -- Enable all configured servers
    vim.lsp.enable('clangd')
    vim.lsp.enable('rust_analyzer')
    vim.lsp.enable('pyright')
    vim.lsp.enable('ts_ls')
    vim.lsp.enable('gopls')
    vim.lsp.enable('lua_ls')
    vim.lsp.enable('jdtls')
    vim.lsp.enable('kotlin_language_server')
    vim.lsp.enable('jsonls')
    vim.lsp.enable('yamlls')
    vim.lsp.enable('marksman')
    vim.lsp.enable('bashls')
    vim.lsp.enable('nil_ls')
    vim.lsp.enable('terraform_ls')
  end,
}
