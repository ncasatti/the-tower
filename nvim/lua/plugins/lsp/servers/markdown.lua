-- Markdown Language Server Configuration
return {
  name = 'marksman',
  config = function(capabilities, on_attach)
    vim.lsp.config('marksman', {
      cmd = { 'marksman', 'server' },
      filetypes = { 'markdown', 'markdown.mdx' },
      root_markers = { '.git', '.marksman.toml' },
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end
}
