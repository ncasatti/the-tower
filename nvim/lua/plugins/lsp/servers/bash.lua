-- Bash Language Server Configuration
return {
  name = 'bashls',
  config = function(capabilities, on_attach)
    vim.lsp.config('bashls', {
      cmd = { 'bash-language-server', 'start' },
      filetypes = { 'sh' },
      root_markers = { '.git' },
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end
}
