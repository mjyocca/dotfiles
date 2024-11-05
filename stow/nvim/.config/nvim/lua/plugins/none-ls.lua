return {
  "nvimtools/none-ls.nvim",
  config = function()
    local null_ls = require("null-ls")
    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.prettier,
        null_ls.builtins.formatting.shellharden,
        null_ls.builtins.diagnostics.erb_lint,
        null_ls.builtins.diagnostics.rubocop,
        null_ls.builtins.formatting.rubocop,
        null_ls.builtins.formatting.clang_format,
        null_ls.builtins.formatting.gofmt,
        null_ls.builtins.formatting.goimports,
        null_ls.builtins.formatting.yamlfmt,
      },
    })

    vim.keymap.set("n", "<leader>nf", vim.lsp.buf.format, { desc = "null_ls Format" })
  end,
}
