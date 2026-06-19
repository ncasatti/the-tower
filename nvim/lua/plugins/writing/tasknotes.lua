-- TaskNotes — lazy.nvim spec.
--
-- The implementation lives under lua/tasknotes/ as a real, require-able module
-- tree (api/cache/ui/pickers/task_ops/query/pomodoro/config/init) — kept out of
-- lua/plugins/writing/ so lazy's `{ import = "plugins.writing" }` does not try to
-- load the modules as plugin specs. See docs/TASKNOTES.md.
return {
	dir = vim.fn.stdpath("config") .. "/lua/plugins/writing",
	name = "tasknotes",
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"folke/snacks.nvim",
	},
	config = function()
		require("tasknotes").setup()
	end,
}
