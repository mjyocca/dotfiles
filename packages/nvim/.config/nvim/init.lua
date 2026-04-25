-- Capture the raw launch argument before any plugin (e.g. Oil) rewrites argv.
-- Oil transforms `argv(0)` from "/some/dir" to "oil:///some/dir/" before
-- VimEnter fires, so checks against argv(0) later will fail for directories.
-- Stored as a global so sessions.lua and autocmds can both read it.
local _launch_arg = vim.fn.argv(0) --[[@as string]]
vim.g.launch_dir = (_launch_arg ~= "" and vim.fn.isdirectory(_launch_arg) == 1)
  and vim.fn.fnamemodify(_launch_arg, ":p")
  or nil

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

-- FIXES mdx errors
-- Patch vim.glob to handle single-item brace patterns like **/*.{mdx}
-- that mdx_analyzer sends and Neovim 0.12 rejects
local orig_to_lpeg = vim.glob.to_lpeg
vim.glob.to_lpeg = function(pattern)
  -- Collapse {single} → single (no comma = not real brace expansion)
  local fixed = pattern:gsub('{(%w+)}', '%1')
  return orig_to_lpeg(fixed)
end

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

-- Source per-project config from $NVIM_LOCAL_CONFIG (set in .envrc).
-- Placed after lazy.setup so plugins are available, matching exrc/.nvim.lua timing.
autocmds.local_config()
