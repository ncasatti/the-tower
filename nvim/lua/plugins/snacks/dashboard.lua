return {
  enabled = true,
  preset = {
    keys = {
      { icon = "󰈞", key = "t", desc = "Find File", action = ":lua Snacks.picker.files()" },
      { icon = "", key = "n", desc = "New File", action = ":enew" },
      { icon = "󱩽", key = "g", desc = "Find Text", action = ":lua Snacks.picker.grep()" },
      { icon = "", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent({ filter = { cwd = true } })" },
      { icon = "", key = "e", desc = "Explore Files", action = ":Oil --float" },
      { icon = "", key = "c", desc = "Config", action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })" },
      { icon = "󰒲", key = "s", desc = "Restore Session", section = "session" },
      { icon = " ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
      { icon = "", key = "q", desc = "Quit", action = ":qa" },
    },
    header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ██╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗  ██║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔██╗ ██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╗██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚████║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝  ╚═══╝]],
  },
  sections = {
    { section = "header" },
    { section = "keys",   gap = 1, padding = 1 },
    { section = "startup" },
  },
}
