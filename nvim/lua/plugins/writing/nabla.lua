return {
  "jbyuki/nabla.nvim",
  keys = {
    {
      "<leader>lp",
      function()
        require("nabla").popup()
      end,
      desc = "LaTeX: Preview (Popup)",
    },
    {
      "<leader>lv",
      function()
        require("nabla").enable_virt()
      end,
      desc = "LaTeX: Enable Virtual Text",
    },
    {
      "<leader>ld",
      function()
        require("nabla").disable_virt()
      end,
      desc = "LaTeX: Disable Virtual Text",
    },
  },
}
