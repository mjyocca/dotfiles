return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require('lualine').setup({
      options = {
        -- theme = 'dracula' -- 'dracula' -- 'horizon'
        theme = 'github-dark',-- 'github-dark', -- Your custom theme name
        icons_enabled = true,
        component_separators = ' ',
        section_separators = { left = '', right = '' },
      },
    })
  end
}
