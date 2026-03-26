-- Go Language Server Configuration
return {
  name = 'gopls',
  config = function(capabilities, on_attach)
    vim.lsp.config('gopls', {
      cmd = { 'gopls' },
      filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
      root_markers = { 'go.work', 'go.mod', '.git' },
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end
}
