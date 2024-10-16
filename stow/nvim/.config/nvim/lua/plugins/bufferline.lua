return {
  'akinsho/bufferline.nvim',
  version = '*',
  dependencies = 'nvim-tree/nvim-web-devicons', -- Optional for file icons
  config = function()
    require('bufferline').setup {
      options = {
        -- Add your options here
        show_buffer_close_icons = true,
        show_close_icon = true,
        separator_style = "thick",
        --separator_style = "slant", -- or "thick", "thin", etc.
        offsets = { { filetype = "neo-tree", text = "File Explorer", padding = 1 } },
      }
    }

    --vim.api.nvim_set_keymap('n', '<Tab>', ':BufferLineCycleNext<CR>', { noremap = true, silent = true })
    --vim.api.nvim_set_keymap('n', '<S-Tab>', ':BufferLineCyclePrev<CR>', { noremap = true, silent = true })

    vim.api.nvim_set_keymap('n', '<Tab>', ':bnext<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<S-Tab>', ':bprevious<CR>', { noremap = true, silent = true })
    
  end
}
