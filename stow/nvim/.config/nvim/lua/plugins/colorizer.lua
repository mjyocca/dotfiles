-- high-performance color highlighter
return {
  'norcalli/nvim-colorizer.lua',
  lazy = true,
  event = "VeryLazy",
  config = function()
    require('colorizer').setup()
  end,
}
