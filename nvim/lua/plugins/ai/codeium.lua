return {
  'Exafunction/windsurf.vim',
  event = "InsertEnter",
  config = function()
    vim.keymap.set('i', '<C-y>', function() return vim.fn['codeium#Accept']() end, { expr = true, silent = true, desc = "Accept Codeium suggestion" })
    vim.keymap.set('i', '<C-/>', function() return vim.fn['codeium#Complete']() end, { expr = true, silent = true, desc = "Trigger Codeium suggestions" })
    vim.keymap.set('i', '<C-i>', function() return vim.fn['codeium#CycleCompletions'](1) end, { expr = true, silent = true, desc = "Next Codeium completion" })
    vim.keymap.set('i', '<C-n>', function() return vim.fn['codeium#CycleCompletions'](-1) end, { expr = true, silent = true, desc = "Previous Codeium completion" })
    vim.keymap.set('i', '<C-x>', function() return vim.fn['codeium#Clear']() end, { expr = true, silent = true, desc = "Clear Codeium suggestions" })
  end,
}
