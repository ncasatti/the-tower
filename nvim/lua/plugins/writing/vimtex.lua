-- nvim/lua/plugins/writing/vimtex.lua
-- LaTeX environment: latexmk (pdflatex) + zathura via DBus.
-- Forward/inverse SyncTeX handled automatically when vimtex launches zathura.

return {
  "lervag/vimtex",
  ft = { "tex", "latex", "plaintex", "bib" },
  init = function()
    -- Viewer: zathura (Wayland-native, DBus inverse search)
    vim.g.vimtex_view_method = "zathura"
    vim.g.vimtex_view_automatic = 1

    -- Compiler: latexmk with pdflatex engine
    vim.g.vimtex_compiler_method = "latexmk"
    vim.g.vimtex_compiler_latexmk = {
      aux_dir = "build",
      out_dir = "build",
      callback = 1,
      continuous = 1,
      executable = "latexmk",
      hooks = {},
      options = {
        "-verbose",
        "-file-line-error",
        "-synctex=1",
        "-interaction=nonstopmode",
        "-pdf",
      },
    }

    -- Silent quickfix on warnings; ignore noise from analysis-math packages
    vim.g.vimtex_quickfix_open_on_warning = 0
    vim.g.vimtex_quickfix_ignore_filters = {
      "Underfull",
      "Overfull",
      "specifier changed to",
      "Token not allowed in a PDF string",
      "Marginpar on page",
    }

    -- Suppress zathura option-check warnings
    vim.g.vimtex_view_zathura_check_libsynctex = 0
  end,
}
