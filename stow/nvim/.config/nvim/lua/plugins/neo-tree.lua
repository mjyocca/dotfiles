return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("neo-tree").setup({
      enable_git_status = true,
      filesystem = {
        follow_current_file = {
          enabled = true,         -- This will find and focus the file in the active buffer every time
          --               -- the current file is changed while the tree is open.
          leave_dirs_open = true, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
        },
        -- follow_current_file = { enabled = true }, -- This ensures that Neo-tree will expand to show the current file
        group_empty_dirs = false,               -- Set to true to group empty directories together
        hijack_netrw_behavior = "open_default", -- Replace netrw with Neo-tree
        use_libuv_file_watcher = true,          -- Automatically updates the tree when files change
        window = {
          position = "left",
          mappings = {
            -- Add a custom mapping to expand all directories recursively
            -- ["E"] = "expand_all_nodes", -- Press 'E' to expand all nodes under the current one
            ["Z"] = "expand_all_nodes",
            ["z"] = "close_all_nodes",
            ["q"] = "close_window",
          },
        },
        filtered_items = {
          visible = false, -- when true, they will just be displayed differently than normal items
          hide_dotfiles = false,
          hide_by_pattern = {
            ".git",
          },
        },
        -- Automatically expand all folders
        auto_expand = true,
      },
    })
    vim.keymap.set('n', '<C-n>', ':Neotree filesystem reveal left<CR>', {
      desc = 'NeoTree reveal', silent = true
    })
    vim.keymap.set("n", "<leader>bf", ":Neotree buffers reveal float<CR>", { 
      desc = 'NeoTree Buffer Reveal', silent = true 
    })
  end
}
