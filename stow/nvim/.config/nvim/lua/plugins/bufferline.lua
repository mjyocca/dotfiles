return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  version = "*",
  dependencies = {
    "nvim-tree/nvim-web-devicons", -- Optional for file icons
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("bufferline").setup({
      options = {
        -- Add your options here
        show_buffer_close_icons = true,
        show_close_icon = true,
        separator_style = "thick",
        offsets = {
          {
            filetype = "neo-tree",
            text = "Neo-tree",
            -- highlight = "Dirctory",
            -- text_align = "left",
            padding = 2,
            -- padding = 1
          },
        },
      },
    })
    -- Fix bufferline when restoring a session
    vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
      callback = function()
        vim.schedule(function()
          pcall(nvim_bufferline)
        end)
      end,
    })

    vim.api.nvim_set_keymap("n", "<Tab>", ":bnext<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("n", "<S-Tab>", ":bprevious<CR>", { noremap = true, silent = true })
  end,
}
