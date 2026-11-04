-- HCL Language Server Configuration (terraform-ls)
--
-- Covers the Terraform filetypes:
--   *.tf      -> terraform
--   *.tfvars  -> terraform-vars
--
-- Generic .hcl files (Packer, Vault, Consul, Nomad policies) are NOT served by
-- terraform-ls — it has no feature for that language id. They are formatted by
-- conform with hclfmt; there is no mason server for generic HCL.
--
-- terraform-ls provides document symbols (so `leader+ss` /
-- Snacks.picker.lsp_symbols() shows the file's blocks as an outline),
-- go-to-definition, hover and diagnostics.
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
      -- terraform-ls implements the `terraform` and `terraform-vars` language
      -- ids only. Registering the generic `hcl` filetype here makes the client
      -- attach with languageId=hcl and then every request fails with
      -- "no feature found for language hcl" — so it is deliberately absent.
      -- Generic .hcl files (Packer, Vault, Consul, Nomad policies) are still
      -- formatted by hclfmt; there is no mason server for generic HCL.
      filetypes = { 'terraform', 'terraform-vars' },
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
