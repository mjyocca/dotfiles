local M = {}

M.server_name = "lua_ls"
M.lspconfig = {
  settings = {
    Lua = {
      completion = {
        callSnippet = "Replace",
      },
    },
  },
}

return M
