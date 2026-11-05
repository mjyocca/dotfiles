# Neovim Configuration

Configuration lives in `packages/nvim/.config/nvim/`; paths below are relative to
that directory. This is a custom lazy.nvim configuration, not a LazyVim import.
It contains Neovim 0.12-specific code; check the installed version before changing
version-sensitive APIs, and use that version's help rather than copied release notes.

## Where Changes Belong

- `lua/config/` owns shared options, keymaps, autocommands, and helper functions.
- `lua/plugins/` is grouped by **editor concern**, not plugin name. Reuse the
  relevant concern file; create a file only for a genuinely new concern. Inspect
  existing specs rather than keeping a second plugin inventory in documentation.
- `lsp/` contains native per-server configuration; `tools/` registers non-LSP
  Mason packages; `snippets/` holds global VSCode-format snippets.

Prefer Lua APIs (`vim.opt`, `vim.keymap.set`, `vim.api`, `vim.filetype.add`) over
Vimscript equivalents. Give mappings descriptions, use named augroups with
deliberate clearing behavior, and avoid duplicating built-in mappings unless
intentionally overriding them. Check mapping scopes and existing reservations
before changing keys.

## LSP and Tool Registration

Read `lua/config/utils.lua` and `lua/plugins/lsp.lua` when changing registration.

Use native configs in `lsp/`, Mason package names in `tools/`, and the existing
debug-adapter setup in `lua/plugins/debug.lua`. Preserve the shared collectors and
completion capabilities rather than adding parallel installation lists or legacy
lspconfig handlers. A server file alone does not prove installation or enabling;
verify registry support and the actual consumer before promising either.

## Project Configuration and Snippets

- Treat `.nvim.lua` and `NVIM_LOCAL_CONFIG` as executable project code. Preserve
  secure reads and user trust decisions; do not substitute unchecked `dofile` or
  `loadfile` calls.
- Review `templates/` and the `dotf init` scaffolder before changing project setup.
  Generating a template is not authorization to trust Lua or allow direnv.
- Global snippets use `snippets/package.json` plus per-language JSON files, loaded
  in `lua/plugins/coding.lua`. Project snippets can be loaded additively from
  trusted project config.

For startup/cwd changes, inspect `init.lua`, `lua/config/autocmds.lua`, and
`lua/plugins/sessions.lua` together. Verify custom picker behavior and compatibility
workarounds against their consumers before simplifying or removing them.

## Verification and References

Use available Lua syntax checks and focused inspection first. Full startup can
clone plugins or install Mason tools; do not launch it as a read-only check.
When authorized, validate the affected mapping/server/snippet in the installed
editor and report what was actually exercised.

Fetch only the relevant upstream reference:

- [Neovim help](https://neovim.io/doc/user/) — use installed `:help` for version-specific APIs
- [lazy.nvim](https://lazy.folke.io/) — plugin specification and loading
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) — native server configurations
- [mason-lspconfig](https://github.com/mason-org/mason-lspconfig.nvim) — server/package mappings
- [Snacks picker](https://github.com/folke/snacks.nvim/blob/main/docs/picker.md) — picker actions and key scopes
- [LuaSnip](https://github.com/L3MON4D3/LuaSnip) — snippet loader behavior
