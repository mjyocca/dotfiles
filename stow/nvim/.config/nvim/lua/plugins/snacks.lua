local ascii_art = [[
=================     ===============     ===============   ========  ========
\\ . . . . . . .\\   //. . . . . . .\\   //. . . . . . .\\  \\. . .\\// . . //
||. . ._____. . .|| ||. . ._____. . .|| ||. . ._____. . .|| || . . .\/ . . .||
|| . .||   ||. . || || . .||   ||. . || || . .||   ||. . || ||. . . . . . . ||
||. . ||   || . .|| ||. . ||   || . .|| ||. . ||   || . .|| || . | . . . . .||
|| . .||   ||. _-|| ||-_ .||   ||. . || || . .||   ||. _-|| ||-_.|\ . . . . ||
||. . ||   ||-'  || ||  `-||   || . .|| ||. . ||   ||-'  || ||  `|\_ . .|. .||
|| . _||   ||    || ||    ||   ||_ . || || . _||   ||    || ||   |\ `-_/| . ||
||_-' ||  .|/    || ||    \|.  || `-_|| ||_-' ||  .|/    || ||   | \  / |-_.||
||    ||_-'      || ||      `-_||    || ||    ||_-'      || ||   | \  / |  `||
||    `'         || ||         `'    || ||    `'         || ||   | \  / |   ||
||            .===' `===.         .==='.`===.         .===' /==. |  \/  |   ||
||         .=='   \_|-_ `===. .==='   _|_   `===. .===' _-|/   `==  \/  |   ||
||      .=='    _-'    `-_  `='    _-'   `-_    `='  _-'   `-_  /|  \/  |   ||
||   .=='    _-'          '-__\._-'         '-_./__-'         `' |. /|  |   ||
||.=='    _-'                                                     `' |  /==.||
=='    _-'                        N E O V I M                         \/   `==
\   _-'                                                                `-_   /
 `''                                                                      ``'
]]

local dashboard = {
	enabled = true,
	pane_gap = 8,
	-- preset = {
	-- 	header = ascii_art,
	-- },
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
		{
			pane = 2,
			icon = " ",
			title = "Git Status",
			section = "terminal",
			enabled = function()
				return Snacks.git.get_root() ~= nil
			end,
			cmd = "git status --short --branch --renames",
			height = 5,
			padding = 1,
			ttl = 5 * 60,
			indent = 3,
		},
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
		gitbrowse = {
			enabled = true,
		},
		lazygit = {
			enabled = true,
			configure = true,
		},
	},
}
