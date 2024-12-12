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
				return require("snacks").git.get_root() ~= nil
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
		gitbrowse = { enabled = true },
		lazygit = {
			enabled = true,
			configure = true,
		},
	},
	init = function()
		vim.api.nvim_create_autocmd("User", {
			pattern = "VeryLazy",
			callback = function()
				Snacks.toggle.diagnostics():map("<leader>ud")
			end,
		})

		vim.api.nvim_create_user_command("ShowDiags", function()
			-- Current Window with diags
			local current_win = vim.api.nvim_get_current_win()
			-- Current Buffer
			local diagnostics = vim.diagnostic.get(0)

			if #diagnostics == 0 then
				vim.notify("No diagnostics found", vim.log.levels.INFO)
				return
			end

			-- Prepare diagnostic entries
			local lines = {}
			local entries = {}
			for _, diag in ipairs(diagnostics) do
				local severity = vim.diagnostic.severity[diag.severity] or "Unknown"
				local entry = {
					text = string.format(
						"[%s] Line %d: %s",
						severity:upper(),
						diag.lnum + 1,
						diag.message:gsub("\n", " ")
					),
					message = diag.message,
					bufnr = diag.bufnr,
					severity = severity:lower(),
					filename = vim.fn.expand("%:p"),
					lnum = diag.lnum + 1,
					col = diag.col + 1,
				}
				table.insert(entries, entry)
				table.insert(lines, entry.text)
			end

			-- No file, temporary
			local diags_buf = vim.api.nvim_create_buf(false, true)
			-- Set buffer lines
			vim.api.nvim_buf_set_lines(diags_buf, 0, -1, false, lines)

			local utils = require("config.utils")

			-- Callback function for selecting a line
			local function on_select()
				local cursor = vim.api.nvim_win_get_cursor(0)
				local line_number = cursor[1]
				local line_text = vim.api.nvim_buf_get_lines(diags_buf, line_number - 1, line_number, false)[1]

				for _, diagnostic in ipairs(entries) do
					if diagnostic.text == line_text then
						utils.window_scroll_to(current_win, diagnostic.lnum)
						return
					end
				end

				print("Diagnostic not found for:", line_text)
			end

			Snacks.win({
				buf = diags_buf,
				relative = "editor",
				position = "bottom",
				height = 0.4,
				width = 0.4,
				minimal = true,
				---@diagnostic disable-next-line: missing-fields
				wo = {
					cursorline = true,
					signcolumn = "yes",
					statuscolumn = " ",
					conceallevel = 3,
				},
				actions = {
					go_to = function()
						on_select()
					end,
				},
				keys = {
					["<C-y>"] = "go_to",
					q = "close",
				},
			})
		end, {})
	end,
}
