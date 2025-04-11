return {
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false,  -- make sure we load this during startup if it is your main colorscheme
    priority = 2000, -- make sure to load this before all the other start plugins
    config = function()
      local theme = "github_dark_default"
      local palette = require("github-theme.palette").load(theme)

      -- Reference
      -- print(vim.inspect(palette))

      require("github-theme").setup({
        options = {
          transparent = true,
          terminal_colors = true,
          dev = true,
        },
        groups = {
          all = {
            -- Set FloatBorder color (e.g., to light blue)
            FloatBorder = { fg = palette.blue.base },
            -- Optionally, set the NormalFloat background for floating windows
            NormalFloat = { fg = palette.blue.base },
            WinSeparator = { fg = palette.fg.default, bg = "NONE" },

            SnacksIndent = { fg = palette.border.muted },
            NeoTreeIndentMarker = { fg = palette.border.muted },
            NeoTreeWinSeparator = { fg = palette.border.muted },
            NeoTreeExpander = { fg = palette.fg.muted },
            -- NeoTreeFileIcon = { bg = palette.accent.subtle },
            NeoTreeDirectoryIcon = { fg = palette.fg.muted },

            -- BufferLine transparent fix after upgrade to nvim v0.11.0
            TabLineFill = { bg = "NONE" },
            -- Lualine transparent fix after upgrade to nvim v0.11.0
            StatusLine = { bg = "NONE" },
            StatusLineNC = { bg = "NONE" },
            -- nvim-cmp transparent highlight group
            CmpPopupMenuTransparent = { bg = "NONE" },
            CmpPopupMenuBorder = { fg = palette.fg.default },
          },
        },
      })

      vim.cmd("colorscheme " .. theme)

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "dapui_scopes", "dapui_breakpoints", "dapui_stacks", "dapui_watches", "dapui_repl" },
        callback = function()
          vim.api.nvim_set_hl(0, "WinSeparator", { fg = palette.fg.subtle, bg = "NONE", bold = true })
        end,
      })
    end,
  },
}
