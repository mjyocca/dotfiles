return {
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false,  -- make sure we load this during startup if it is your main colorscheme
    priority = 2000, -- make sure to load this before all the other start plugins
    config = function()
      require("github-theme").setup({
        options = {
          transparent = true,
          terminal_colors = true,
          dev = true,
        },
        groups = {
          all = {
            -- Set FloatBorder color (e.g., to light blue)
            FloatBorder = { fg = "#5fafff" },
            -- Optionally, set the NormalFloat background for floating windows
            NormalFloat = { fg = "#5fafff" },
            WinSeparator = { fg = "#89929b", bg = "NONE" },

            SnacksIndent = { fg = "#21262d" },
            NeoTreeIndentMarker = { fg = "#21262d" },
            NeoTreeWinSeparator = { fg = "#21262d" },

            -- BufferLine transparent fix after upgrade to nvim v0.11.0
            TabLineFill = { bg = "NONE" },
            -- Lualine transparent fix after upgrade to nvim v0.11.0
            StatusLine = { bg = "NONE" },
            StatusLineNC = { bg = "NONE" },
          },
        },
      })

      vim.cmd("colorscheme github_dark_default")

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "dapui_scopes", "dapui_breakpoints", "dapui_stacks", "dapui_watches", "dapui_repl" },
        callback = function()
          vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#89929b", bg = "NONE", bold = true })
        end,
      })
    end,
  },
}
