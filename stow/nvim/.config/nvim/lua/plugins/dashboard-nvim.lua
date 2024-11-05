return {
  'nvimdev/dashboard-nvim',
  dependencies = { {'nvim-tree/nvim-web-devicons'} },
  lazy = false,
  priority = 3000,
  -- event = 'VimEnter',
  config = function()
    require('dashboard').setup {
      -- config
      hide = {
        statusline = false
      }
    }
  end,
}
