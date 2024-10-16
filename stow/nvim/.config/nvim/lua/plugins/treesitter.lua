return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local config = require("nvim-treesitter.configs")
    config.setup({
      auto_install = true,
      ensure_installed = { "lua", "html", "css", "javascript", "ruby", "python", "go", "rust", "c" },
      sync_install = true,
      highlight = { enabled = true },
      indent = { enabled = true },
    })
  end
}
