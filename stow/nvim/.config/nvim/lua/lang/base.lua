local M = {}

local language_files = {
  "lua",
  "c",
  "rust",
  "golang",
  "typescript",
  "ruby",
  "sorbet",
  "terraform",
  "bash",
  "markdown",
}

local server_mappings = {}

for _, lang in ipairs(language_files) do
  local ok, conf = pcall(require, "lang." .. lang)
  if not ok then
    vim.notify("Failed to load Language configuration for " .. lang, vim.log.levels.WARN)
  else
    server_mappings[conf.server_name] = conf.lspconfig
  end
end

M.lsp_servers = server_mappings

return M
