-- YAML Language Server Configuration
return {
  name = 'yamlls',
  config = function(capabilities, on_attach)
    vim.lsp.config('yamlls', {
      cmd = { 'yaml-language-server', '--stdio' },
      filetypes = { 'yaml', 'yaml.docker-compose', 'yaml.gitlab' },
      root_markers = { '.git' },
      capabilities = capabilities,
      on_attach = on_attach,
      settings = {
        yaml = {
          schemas = {
            ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
            ["https://json.schemastore.org/gitlab-ci.json"] = "*/.gitlab-ci.yml",
          },
        },
      },
    })
  end
}
