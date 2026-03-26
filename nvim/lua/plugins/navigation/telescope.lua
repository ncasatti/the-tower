return {
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local previewers = require('telescope.previewers')

      local glow_previewer = previewers.new_termopen_previewer({
        get_command = function(entry)
          local path = entry.path or entry.filename
          if path and path:match('%.md$') then
            return { 'glow', '-s', 'dark', path }
          end
          return { 'bat', '--style=numbers', '--color=always', path }
        end,
      })

      require('telescope').setup({
        defaults = {
          sorting_strategy = 'ascending',
          layout_config = {
            horizontal = {
              preview_width = 0.5,
              prompt_position = 'top',
            },
          },
          file_previewer = function(opts) return glow_previewer end,
          grep_previewer = function(opts) return glow_previewer end,
        },
      })
    end
  },
  {
    'nvim-telescope/telescope-symbols.nvim',
  },
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    build = 'make',
    cond = vim.fn.executable 'make' == 1
  },
}


