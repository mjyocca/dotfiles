return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require('lualine').setup({
      options = {
        -- theme = 'dracula' -- 'dracula' -- 'horizon'
        theme = 'github-dark', -- Your custom theme name
      }
    })
  end
}
