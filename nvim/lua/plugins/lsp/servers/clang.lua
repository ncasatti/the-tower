-- C/C++ Language Server Configuration
return {
  name = 'clangd',
  config = function(capabilities, on_attach)
    vim.lsp.config('clangd', {
      cmd = { 'clangd' },
      filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
      root_markers = { '.clangd', '.clang-tidy', '.clang-format', 'compile_commands.json', 'compile_flags.txt', 'configure.ac', '.git' },
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end
}
