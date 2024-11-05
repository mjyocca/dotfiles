return {
  {
    "tpope/vim-fugitive",
  },
  -- {
  --   "lewis6991/gitsigns.nvim",
  --   opts = {
  --     signs = {
  --       add = { text = '+' },
  --       change = { text = '~' },
  --       delete = { text = '_' },
  --       topdelete = { text = '‾' },
  --       changedelete = { text = '~' },
  --     },
  --   },
  --   config = function()
  --     require("gitsigns").setup()
  --
  --     vim.keymap.set("n", "<leader>gp", ":Gitsigns preview_hunk<CR>", {})
  --     vim.keymap.set("n", "<leader>gt", ":Gitsigns toggle_current_line_blame<CR>", {})
  --   end,
  -- }
  {
    -- Adds git related signs to the gutter, as well as utilities for managing changes
    -- NOTE: gitsigns is already included in init.lua but contains only the base
    -- config. This will add also the recommended keymaps.
    'lewis6991/gitsigns.nvim',
    opts = {
      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gitsigns.nav_hunk 'next'
          end
        end, { desc = 'Jump to next git [c]hange' })

      vim.keymap.set("n", "<leader>gp", ":Gitsigns preview_hunk<CR>", {})
      vim.keymap.set("n", "<leader>gt", ":Gitsigns toggle_current_line_blame<CR>", {})
    end,
  }
}
