return {
	{
		"projekt0n/github-nvim-theme",
		name = "github-theme",
		lazy = false, -- make sure we load this during startup if it is your main colorscheme
		priority = 1000, -- make sure to load this before all the other start plugins
		config = function()
			require("github-theme").setup({
				options = { transparent = true },
			})

			vim.cmd("colorscheme github_dark_default")
			-- Set FloatBorder color (e.g., to light blue)
			vim.cmd("highlight FloatBorder guifg=#5fafff")
			-- Optionally, set the NormalFloat background for floating windows
			vim.cmd("highlight NormalFloat guifg=#5fafff")

			vim.cmd("highlight NeoTreeIndentMarker guifg=#21262d")
			-- vim.cmd("highlight WinSeparator guifg=#21262d")
		end,
	},
}
