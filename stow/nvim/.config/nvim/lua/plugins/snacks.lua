local dashboard = {
	enabled = true,
	pane_gap = 8,
	sections = {
		{ section = "header" },
		{ section = "keys", gap = 1, padding = 1 },
		{
			pane = 2,
			icon = " ",
			title = "Recent Files",
			section = "recent_files",
			limit = 8,
			indent = 2,
			padding = 1,
		},
		{
			pane = 2,
			icon = " ",
			title = "Projects",
			section = "projects",
			limit = 8,
			indent = 2,
			padding = 1,
		},
		-- {
		-- 	pane = 2,
		-- 	icon = " ",
		-- 	title = "Git Status",
		-- 	section = "terminal",
		-- 	enabled = function()
		-- 		return require("snacks").git.get_root() ~= nil
		-- 	end,
		-- 	cmd = "git status --short --branch --renames",
		-- 	height = 5,
		-- 	padding = 1,
		-- 	ttl = 5 * 60,
		-- 	indent = 2,
		-- },
		{ section = "startup" },
	},
}

return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		notifier = { enabled = true },
		dashboard = dashboard,
		scroll = { enabled = true },
		statuscolumn = { enabled = true },
		indent = {
			enabled = true,
			only_scope = true,
			only_current = true,
		},
		scope = { enabled = true },
		toggle = { enabled = true },
		scratch = { enabled = true },
		debug = { enabled = true },
		terminal = { enabled = true },
		git = { enabled = true },
		words = {},
		gitbrowse = { enabled = true },
		lazygit = {
			enabled = true,
			configure = true,
		},
	},
	init = function()
		require("config.autocmds").snacks({})
	end,
}
