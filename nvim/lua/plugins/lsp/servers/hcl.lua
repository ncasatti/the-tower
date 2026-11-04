-- HCL Language Server Configuration (terraform-ls)
--
-- Covers the three HCL filetypes Neovim detects:
--   *.tf      -> terraform
--   *.tfvars  -> terraform-vars
--   *.hcl     -> hcl
--
-- terraform-ls is the HashiCorp language server. It provides document symbols
-- (so `leader+ss` / Snacks.picker.lsp_symbols() shows the file's blocks as an
-- outline), go-to-definition, hover and diagnostics.
--
-- terraform-ls works without the `terraform` binary installed — it falls back
-- to its own schema handling and still parses/lints the configuration. Installing
-- terraform (or tofu) unlocks provider-backed completion, but is not required
-- for formatting or navigation.
--
-- Formatting is handled by conform.nvim with `hclfmt` (hashicorp/hcl), not by
-- the LSP — terraform-ls does not implement textDocument/formatting.
return {
  name = 'terraform_ls',
  config = function(capabilities, on_attach)
    vim.lsp.config('terraform_ls', {
      cmd = { 'terraform-ls', 'serve' },
      filetypes = { 'terraform', 'terraform-vars', 'hcl' },
      root_markers = { '.terraform', '.git', '*.tf' },
      capabilities = capabilities,
      on_attach = on_attach,
      init_options = {
        experimentalFeatures = {
          validateOnSave = true,
          moduleCalls = true,
          prefillRequiredFields = true,
        },
        terraform = {
          path = '',
          modules = {},
        },
        tofu = {
          path = '',
          modules = {},
        },
      },
    })
  end,
}
