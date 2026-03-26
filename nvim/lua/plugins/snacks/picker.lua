return {
  enabled = true,
  layout = {
    reverse = false, -- search bar at top, correct symbol order
    preview = {
      direction = "right", -- preview on the right side
      width = 0.60, -- preview takes 65% of width
    },
    box = "vertical", -- vertical separation
  },
  win = {
    input = {
      keys = {
        ["<C-p>"] = { "toggle_preview", mode = { "n", "i" } },
        -- Close buffer from picker (works in buffer picker)
        ["<C-d>"] = {
          function(picker)
            local item = picker:current()
            if item and item.buf then
              vim.api.nvim_buf_delete(item.buf, { force = false })
              -- Refresh picker after deletion
              picker:update()
            end
          end,
          mode = { "n", "i" },
          desc = "Delete buffer",
        },
      },
    },
  },
}
