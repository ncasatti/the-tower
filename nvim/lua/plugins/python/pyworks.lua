-- Pyworks.nvim - Jupyter Notebook Integration
-- Provides Molten (code execution), Jupytext (notebook conversion), and Image rendering
return {
  {
    "jeryldev/pyworks.nvim",
    dependencies = {
      {
        "GCBallesteros/jupytext.nvim",
        config = function()
          require("jupytext").setup({
            style = "percent", -- Use # %% format for cells
            output_extension = "auto", -- Auto-detect output format
            force_ft = "python", -- Force Python filetype for .ipynb
            custom_language_formatting = {
              python = {
                extension = "py",
                style = "percent", -- # %% cells
                force_ft = "python",
              },
            },
          })
          
          -- Prevent auto-write to .ipynb when opening
          -- Only sync when explicitly saved with :w!
          vim.api.nvim_create_autocmd("BufReadPost", {
            pattern = "*.ipynb",
            callback = function()
              -- Disable auto-write
              vim.bo.autowrite = false
              vim.bo.autowriteall = false
              
              -- Warn user to save manually
              vim.notify(
                "Editing .ipynb as .py. Use :w to sync, or :JupytextPair to create paired .py",
                vim.log.levels.INFO
              )
            end,
          })
          
          -- Command to pair current .ipynb with .py
          vim.api.nvim_create_user_command("JupytextPair", function()
            local file = vim.fn.expand("%:p")
            if file:match("%.ipynb$") then
              vim.cmd("!jupytext --set-formats ipynb,py:percent " .. vim.fn.shellescape(file))
              vim.notify("Paired with " .. file:gsub("%.ipynb$", ".py"), vim.log.levels.INFO)
              -- Reload to switch to .py
              vim.cmd("edit " .. file:gsub("%.ipynb$", ".py"))
            else
              vim.notify("Current file is not .ipynb", vim.log.levels.ERROR)
            end
          end, { desc = "Pair .ipynb with .py file" })
        end,
      },
      {
        "benlubas/molten-nvim",
        build = ":UpdateRemotePlugins",
      },
      "3rd/image.nvim",
    },
    ft = { "python", "jupyter" }, -- Load for Python and Jupyter files
    event = { "BufReadPre *.ipynb" }, -- Also load when opening .ipynb files
    config = function()
      require("pyworks").setup({
        python = {
          use_uv = false, -- Set to true if you use uv for package management
        },
        image_backend = "kitty", -- "kitty" for Kitty terminal, "ueberzug" for others
        
        -- Pyworks auto-configures Molten, Jupytext, and Image.nvim
        skip_molten = false,
        skip_jupytext = false,
        skip_image = false,
        skip_keymaps = true, -- We'll set custom keymaps
      })
      
      -- Custom keybindings for Molten (Jupyter-style execution)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "python", "jupyter" },
        callback = function()
          local opts = { buffer = true, silent = true }
          
          -- Molten: Initialize/manage kernels
          vim.keymap.set("n", "<leader>mi", ":MoltenInit<CR>",
            vim.tbl_extend("force", opts, { desc = "Molten: Initialize kernel" }))
          
          vim.keymap.set("n", "<leader>mD", ":MoltenDeinit<CR>",
            vim.tbl_extend("force", opts, { desc = "Molten: Deinitialize kernel" }))
          
          vim.keymap.set("n", "<leader>mk", ":MoltenShowOutput<CR>",
            vim.tbl_extend("force", opts, { desc = "Molten: Show output" }))
          
          vim.keymap.set("n", "<leader>mh", ":MoltenHideOutput<CR>",
            vim.tbl_extend("force", opts, { desc = "Molten: Hide output" }))
          
          -- Molten: Execute code
          vim.keymap.set("n", "<leader>me", ":MoltenEvaluateOperator<CR>",
            vim.tbl_extend("force", opts, { desc = "Molten: Evaluate operator" }))
          
          vim.keymap.set("n", "<leader>ml", ":MoltenEvaluateLine<CR>",
            vim.tbl_extend("force", opts, { desc = "Molten: Evaluate line" }))
          
          vim.keymap.set("v", "<leader>me", ":<C-u>MoltenEvaluateVisual<CR>gv",
            vim.tbl_extend("force", opts, { desc = "Molten: Evaluate selection" }))
          
          vim.keymap.set("n", "<leader>mc", ":MoltenReevaluateCell<CR>",
            vim.tbl_extend("force", opts, { desc = "Molten: Re-evaluate cell" }))
          
          -- Molten: Navigation
          vim.keymap.set("n", "[m", ":MoltenPrev<CR>",
            vim.tbl_extend("force", opts, { desc = "Molten: Previous cell" }))
          
          vim.keymap.set("n", "]m", ":MoltenNext<CR>",
            vim.tbl_extend("force", opts, { desc = "Molten: Next cell" }))
          
          -- Molten: Delete output
          vim.keymap.set("n", "<leader>md", ":MoltenDelete<CR>",
            vim.tbl_extend("force", opts, { desc = "Molten: Delete cell output" }))
          
          vim.keymap.set("n", "<leader>mx", ":MoltenInterrupt<CR>",
            vim.tbl_extend("force", opts, { desc = "Molten: Interrupt execution" }))
        end,
      })
    end,
  },
}
