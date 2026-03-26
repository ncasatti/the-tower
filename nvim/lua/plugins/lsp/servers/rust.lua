-- Rust Language Server Configuration
return {
  name = 'rust_analyzer',
  config = function(capabilities, on_attach)
    vim.lsp.config('rust_analyzer', {
      cmd = { 'rust-analyzer' },
      filetypes = { 'rust' },
      root_markers = { 'Cargo.toml', 'rust-project.json' },
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end
}
