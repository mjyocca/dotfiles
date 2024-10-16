return {
  {
    "nvim-telescope/telescope-ui-select.nvim",
  },
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        defaults = {
          file_ignore_patterns = { ".git/.*" },
        }, 
        pickers = {
          find_files = {
            hidden = true,
            theme = "ivy",
          },
        },
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
      })
      
      local builtin = require("telescope.builtin")

      vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "Telescope find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      vim.keymap.set("n", "<leader><leader>", builtin.oldfiles, {})
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})

      require("telescope").load_extension("ui-select")
    end,
  },
}
