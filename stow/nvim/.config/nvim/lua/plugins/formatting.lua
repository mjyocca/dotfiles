return {
  {
    "nvimtools/none-ls.nvim",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = { ensure_installed = { "gomodifytags", "goimports", "gofmt", "impl" } },
      },
    },
    config = function()
      local null_ls = require("null-ls")
      local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

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
          null_ls.builtins.code_actions.gomodifytags,
          null_ls.builtins.code_actions.impl,
          null_ls.builtins.formatting.yamlfmt,
        },
        on_attach = function(client, bufnr)
          -- Specify filetypes where formatting should be disabled
          local disabled_filetypes = { "ruby" }

          -- Check if current filetype is in the disabled list
          local filetype = vim.bo.filetype -- vim.api.nvim_buf_get_option(bufnr, "filetype")
          if vim.tbl_contains(disabled_filetypes, filetype) then
            return
          end

          if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({
              group = augroup,
              buffer = bufnr,
            })
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup,
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({ bufnr = bufnr })
              end,
            })
          end
        end,
      })

      vim.keymap.set("n", "<leader>nf", vim.lsp.buf.format, { desc = "null_ls Format" })
    end,
  },
}
