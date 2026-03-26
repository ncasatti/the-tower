-- Kotlin Language Server Configuration
return {
  name = 'kotlin_language_server',
  config = function(capabilities, on_attach)
    vim.lsp.config('kotlin_language_server', {
      cmd = { 'kotlin-language-server' },
      filetypes = { 'kotlin' },
      root_markers = {
        -- Android project markers
        'settings.gradle',
        'settings.gradle.kts',
        -- Standard Kotlin project markers
        'gradlew',
        '.git',
        'mvnw',
        'pom.xml',
        'build.gradle',
        'build.gradle.kts',
      },
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end
}
