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

			vim.cmd("highlight WinSeparator guifg=#89929b guibg=NONE")

			vim.cmd("highlight NeoTreeWinSeparator guifg=#21262d")
			vim.cmd("highlight NeoTreeIndentMarker guifg=#21262d")
			vim.cmd("highlight SnacksIndent guifg=#21262d")

			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "dapui_scopes", "dapui_breakpoints", "dapui_stacks", "dapui_watches", "dapui_repl" },
				callback = function()
					vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#89929b", bg = "NONE", bold = true })
				end,
			})
		end,
	},
}
