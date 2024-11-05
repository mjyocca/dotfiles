return {
  {
    'nvim-lualine/lualine.nvim',
    event = "VeryLazy",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    init = function()
      vim.g.lualine_laststatus = vim.o.laststatus
      if vim.fn.argc(-1) > 0 then
        -- set an empty statusline till lualine loads
        vim.o.statusline = " "
      else
        -- hide the statusline on the starter page
        vim.o.laststatus = 0
      end
    end,
    config = function()
      -- vim.cmd('colorscheme github_dark_default')
      require('lualine').setup({
        options = {
          -- theme = 'dracula' -- 'dracula' -- 'horizon'
          theme = 'github-dark', -- Your custom theme name
          icons_enabled = true,
          component_separators = ' ',
          section_separators = { left = '', right = '' },
          disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter" } },
        },
      })
    end
  }
}
