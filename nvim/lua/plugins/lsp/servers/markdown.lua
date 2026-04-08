-- Markdown Language Server Configuration
return {
  name = 'marksman',
  config = function(capabilities, on_attach)
    vim.lsp.config('marksman', {
      cmd = { 'marksman', 'server' },
      filetypes = { 'markdown', 'markdown.mdx' },
      root_markers = { '.git', '.marksman.toml' },
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        -- Disable hover provider to prevent annoying popups in LaTeX blocks
        client.server_capabilities.hoverProvider = false
        if on_attach then
          on_attach(client, bufnr)
        end
      end,
    })
  end
}
