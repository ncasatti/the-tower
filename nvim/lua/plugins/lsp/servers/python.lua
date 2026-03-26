-- Python Language Server Configuration
return {
  name = 'pyright',
  config = function(capabilities, on_attach)
    vim.lsp.config('pyright', {
      cmd = { 'pyright-langserver', '--stdio' },
      filetypes = { 'python' },
      root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', 'pyrightconfig.json', '.git' },
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end
}
