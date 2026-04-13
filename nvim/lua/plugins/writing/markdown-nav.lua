-- Markdown Navigation: Jump between headings and callouts
-- This is a local config module, not a plugin.
-- Buffer-local keymaps take priority over the global Snacks.words.jump bindings.

-- Vim regex: matches lines starting with '#' (headings) OR '>' followed by optional
-- whitespace and '[!' (Obsidian callout syntax, including nested blockquotes).
local pattern = [[^\(#\|>\s*\[!\)]]

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("MarkdownNav", { clear = true }),
    pattern = "markdown",
    callback = function(args)
        local opts = { buffer = args.buf, silent = true }

        vim.keymap.set({ "n", "v", "o" }, "]]", function()
            vim.fn.search(pattern, "W")
            vim.cmd("normal! zz")
        end, vim.tbl_extend("force", opts, { desc = "Next heading/callout" }))

        vim.keymap.set({ "n", "v", "o" }, "[[", function()
            vim.fn.search(pattern, "bW")
            vim.cmd("normal! zz")
        end, vim.tbl_extend("force", opts, { desc = "Prev heading/callout" }))
    end,
})

return {}
