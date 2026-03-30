-- Nix Language Server Configuration (nil)
return {
  name = 'nil_ls',
  config = function(capabilities, on_attach)
    vim.lsp.config('nil_ls', {
      cmd = { 'nil' },
      filetypes = { 'nix' },
      root_markers = { 'flake.nix', 'default.nix', '.git' },
      capabilities = capabilities,
      on_attach = on_attach,
      settings = {
        ['nil'] = {
          formatting = {
            command = { 'alejandra' },
          },
          nix = {
            maxMemoryMB = 2560,
            flake = {
              autoArchive = true,
            },
          },
        },
      },
    })
  end
}
