return {
	scope = {
		min_size = 15,
		max_size = 30,
		siblings = true,
	},
	animate = {
		enabled = vim.fn.has("nvim-0.10") == 1,
		easing = "inCirc",
		duration = {
			step = 15, -- ms per step
			total = 300, -- maximum duration
		},
	},
}
