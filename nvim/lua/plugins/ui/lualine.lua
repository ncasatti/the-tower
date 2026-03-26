return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    -- local custom_theme = require('lualine.themes.iceberg_dark')

    require('lualine').setup {
      options = {
        icons_enabled = true,
        component_separators = '|',
        section_separators = '',
        theme = 'auto',
      },
      tabline = {
        lualine_a = {
          {
            require("noice").api.statusline.mode.get,
            cond = require("noice").api.statusline.mode.has, -- color = { fg = "#ff9e64" },
          },
          {
            require("noice").api.status.command.get,
            cond = require("noice").api.status.command.has, -- color = { fg = "#ff9e64" },
          },
        },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = { 'buffers' }
      },
      sections = {
        lualine_a = {
          'branch',
          'diff'
        },
        lualine_b = { 'diagnostics' },
        lualine_c = {},
        lualine_x = {},
        lualine_y = {
          'searchcount',
          'selectioncount'
        },
        lualine_z = { 'progress', 'location' }
      },
      extensions = { 'fzf', 'lazy', 'oil', 'mason' }
    }
  end
}
