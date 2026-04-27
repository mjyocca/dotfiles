---@type vim.lsp.Config
return {
  cmd = { "golangci-lint-langserver" },
  filetypes = { "go" },
  root_markers = { ".golangci.yml", ".golangci.yaml", ".golangci.toml", ".golangci.json", "go.mod", ".git" },
  init_options = {
    command = { "golangci-lint", "run", "--output.text.path=stderr", "--show-stats=false", "--issues-exit-code=1" },
  },
}
