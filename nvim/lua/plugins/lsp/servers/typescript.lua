-- TypeScript/JavaScript Language Server Configuration
return {
  name = 'ts_ls',
  config = function(capabilities, on_attach)
    vim.lsp.config('ts_ls', {
      cmd = { 'typescript-language-server', '--stdio' },
      filetypes = { 'javascript', 'javascriptreact', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx' },
      root_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json', '.git' },
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end
}
