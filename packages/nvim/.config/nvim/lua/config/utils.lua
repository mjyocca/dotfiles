local M = {}

local print_table = function(tbl, indent)
  indent = indent or 0
  local indent_str = string.rep("  ", indent)

  for key, value in pairs(tbl) do
    if type(value) == "table" then
      print(string.format("%s%s:", indent_str, tostring(key)))
      print_table(value, indent + 1)
    else
      print(string.format("%s%s: %s", indent_str, tostring(key), tostring(value)))
    end
  end
end

M.print_table = print_table

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

--- Returns a list of LSP server names derived from files in `nvim/lsp/*.lua`,
--- filtered to only those known to mason-lspconfig (i.e. mason-installable).
---@return string[]
M.lsp_servers = function()
  local lsp_dir = vim.fn.stdpath("config") .. "/lsp"
  local mason_map = require("mason-lspconfig.mappings").get_mason_map().lspconfig_to_package
  local servers = {}
  for name, type in vim.fs.dir(lsp_dir) do
    if type == "file" and name:match("%.lua$") then
      local server = (name:gsub("%.lua$", ""))
      if mason_map[server] then
        table.insert(servers, server)
      end
    end
  end
  return servers
end

--- Returns a flat list of mason package names collected from all `nvim/tools/*.lua` files.
--- Each file returns a string[] of mason package names for a specific concern (e.g. go, lua).
--- Add a new `tools/<concern>.lua` to register additional non-LSP mason tools.
---@return string[]
M.tools = function()
  local tools_dir = vim.fn.stdpath("config") .. "/tools"
  local result = {}
  for name, entry_type in vim.fs.dir(tools_dir) do
    if entry_type == "file" and name:match("%.lua$") then
      local path = tools_dir .. "/" .. name
      local ok, pkgs = pcall(dofile, path)
      if ok and type(pkgs) == "table" then
        vim.list_extend(result, pkgs)
      end
    end
  end
  return result
end

return M
