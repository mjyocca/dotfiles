# Vim

# Nvim

## Telescope

```lua
vim.keymap.set("n", "<C-p>", builtin.find_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
vim.keymap.set("n", "<leader><leader>", builtin.oldfiles, {})
```

## Neo-Tree

```lua
vim.keymap.set('n', '<C-n>', ':Neotree filesystem reveal left<CR>', {})
vim.keymap.set("n", "<leader>bf", ":Neotree buffers reveal float<CR>", {})
```

## Other/Misc


