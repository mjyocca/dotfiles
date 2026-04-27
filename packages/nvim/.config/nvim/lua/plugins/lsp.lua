return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "luvit-meta/library", words = { "vim%.uv" } },
      },
    },
  },
  { "Bilal2453/luvit-meta", lazy = true },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "williamboman/mason.nvim",
        config = true,
        opts = {
          ui = {
            border = "single",
            backdrop = 40,
          },
        },
      }, -- NOTE: Must be loaded before dependants
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "jay-babu/mason-null-ls.nvim",

      -- Useful status updates for LSP.
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { "j-hui/fidget.nvim", opts = {} },

      -- Allows extra capabilities provided by nvim-cmp
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      -- Register LSP AutoCmds
      require("config.autocmds").lsp({
        callback = function(event)
          -- Register LSP KeyMaps
          require("config.keymaps").lsp(event)
        end,
      })

      -- Broadcast cmp_nvim_lsp capabilities to all servers globally.
      -- Replaces the old per-server capabilities merge that was done via mason-lspconfig handlers.
      vim.lsp.config("*", {
        capabilities = vim.tbl_deep_extend(
          "force",
          vim.lsp.protocol.make_client_capabilities(),
          require("cmp_nvim_lsp").default_capabilities()
        ),
      })

      local utils = require("config.utils")
      local lsp_servers = utils.lsp_servers()
      local all_tools = vim.list_extend(vim.list_extend({}, lsp_servers), utils.tools())

      require("mason-null-ls").setup({
        automatic_installation = {},
      })

      --  NOTE: You can press `g?` for help in this menu.
      require("mason").setup()

      -- mason-tool-installer gets everything: LSP servers + non-LSP tools
      require("mason-tool-installer").setup({
        ensure_installed = all_tools,
      })

      -- mason-lspconfig gets LSP servers only — passing non-LSP names here causes warnings
      require("mason-lspconfig").setup({
        ensure_installed = lsp_servers,
        automatic_installation = true,
        automatic_enable = true,
      })
    end,
  },

  {
    "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    config = function()
      require("lsp_lines").setup()
      vim.diagnostic.config({ virtual_lines = true })
    end,
  },
}
