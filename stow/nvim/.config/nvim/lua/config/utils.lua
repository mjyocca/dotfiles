local M = {}

M.window_scroll_to = function(target_win, line)
  line = math.max(1, line)
  vim.api.nvim_win_call(target_win, function()
    vim.api.nvim_win_set_cursor(target_win, { line, 0 })
  end)
end

---@param diagnostics vim.Diagnostic[]
---@return table<string, table>
M.get_diagnostics = function(diagnostics)
  local lines = {}
  local entries = {}

  for _, diag in ipairs(diagnostics) do
    local severity = vim.diagnostic.severity[diag.severity] or "Unknown"
    local entry = {
      text = string.format("[%s] Line %d: %s", severity:upper(), diag.lnum + 1, diag.message:gsub("\n", " ")),
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

  return {
    lines = lines,
    entries = entries,
  }
end

return M
