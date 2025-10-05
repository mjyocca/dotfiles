-- Load Lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Setup configuration options
require("config.options")
local autocmds = require("config.autocmds")
local keymaps = require("config.keymaps")

-- Load general autocmds globally
autocmds.general()
-- Load plugin autocmds
autocmds.plugins()
-- Load general keymaps globally
keymaps.general()
-- Load plugin keymaps
keymaps.plugins()

-- Initialize Lazy
require("lazy").setup({
  spec = {
    {
      import = "plugins",
    },
  },
  ui = {
    border = "single",
    size = {
      width = 0.8,
      height = 0.8,
    }
  }
})
