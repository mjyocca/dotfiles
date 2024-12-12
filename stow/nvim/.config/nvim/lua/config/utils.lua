local M = {}

M.window_scroll_to = function(target_win, line)
	line = math.max(1, line)
	vim.api.nvim_win_call(target_win, function()
		vim.api.nvim_win_set_cursor(target_win, { line, 0 })
	end)
end

return M
