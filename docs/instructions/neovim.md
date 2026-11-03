# Neovim Configuration

Configuration lives in `packages/nvim/.config/nvim/`; paths below are relative to
that directory. This is a custom lazy.nvim configuration, not a LazyVim import.
It contains Neovim 0.12-specific code; check the installed version before changing
version-sensitive APIs, and use that version's help rather than copied release notes.

## Where Changes Belong

- `init.lua` bootstraps lazy.nvim, loads options/keymaps/autocommands, imports
  `lua/plugins/`, then invokes the trusted local-config loader.
- `lua/config/` owns shared options, keymaps, autocommands, and helper functions.
- `lua/plugins/` is grouped by **editor concern**, not plugin name. Reuse the
  relevant concern file; create a file only for a genuinely new concern. Inspect
  existing specs rather than keeping a second plugin inventory in documentation.
- `lsp/` contains native per-server configuration; `tools/` registers non-LSP
  Mason packages; `snippets/` holds global VSCode-format snippets.

Prefer Lua APIs (`vim.opt`, `vim.keymap.set`, `vim.api`, `vim.filetype.add`) over
Vimscript equivalents. Give mappings descriptions, use named augroups with
deliberate clearing behavior, and avoid duplicating built-in mappings unless
intentionally overriding them. Preserve the existing normal-mode Tab reservation;
picker-local Tab selection is a separate concern.

## LSP and Tool Registration

Read `lua/config/utils.lua` and `lua/plugins/lsp.lua` when changing registration.

| Type | Register in | Consumer |
|---|---|---|
| LSP server | `lsp/<server>.lua` returning native config | `utils.lsp_servers()` filters filenames through the mason-lspconfig registry |
| Formatter, linter, CLI | `tools/<concern>.lua` returning Mason package-name strings | `utils.tools()` collects the lists |
| Debug adapter | `lua/plugins/debug.lua` | Existing mason-nvim-dap setup |

`mason-tool-installer` receives the merged LSP/tool lists; `mason-lspconfig`
receives only LSP names and enables servers automatically. Servers absent from
the Mason map are skipped by the scanner: adding a file does not install or enable
those servers. Inspect external provisioning/enabling before promising support.

Global completion capabilities are configured once through `vim.lsp.config("*", …)`
in `lua/plugins/lsp.lua`. Add server-specific overrides only where needed. Do not
restore the old `lua/lang/` layout, manual lspconfig setup handlers, private LSP
state inspection, or hardcoded installation lists in formatting/LSP specs.
Do not use Mason core's `opts.ensure_installed` as a substitute for the collectors.

## Project Configuration and Snippets

- `lua/config/options.lua` enables `exrc` for `.nvim.lua`. Treat project Lua as
  executable code: leave trust decisions to the user, not automatic approval.
- `NVIM_LOCAL_CONFIG` is the alternative for projects that cannot use a root
  `.nvim.lua`. `autocmds.local_config()` resolves it against the current directory,
  reads it through `vim.secure.read`, and reloads on `DirChanged`. Preserve this
  trust boundary; do not replace it with unchecked `dofile`/`loadfile`.
- `templates/.envrc.template` and `templates/.nvim.lua.template` contain local
  examples. The repository's `dotf init` scaffolder offers templates and skips
  existing files; template generation is not authorization to trust Lua or allow
  direnv. Review the actual scaffolder before changing its behavior.
- Global snippets use `snippets/package.json` plus per-language JSON files, loaded
  in `lua/plugins/coding.lua`. Project snippets can be loaded additively from
  trusted project config. Existing snippet navigation uses Ctrl-l / Ctrl-h.

## Local Behavior to Preserve

- `init.lua` captures the launch directory before plugins rewrite arguments;
  `lua/config/autocmds.lua` and `lua/plugins/sessions.lua` coordinate directory
  launches and session behavior. Inspect them together for startup/cwd changes.
- The single-brace glob workaround in `init.lua` accommodates mdx-analyzer
  patterns. Remove it only after verifying the upstream issue no longer applies;
  do not reproduce its implementation here.
- `lua/plugins/snacks.lua` implements floating explorer and `pick_win_stay`
  behavior: selected files are assigned one at a time while the picker remains
  open; the single-file path closes it. Inspect input/list key scopes and focus
  handling before changing mappings or replacing this action with a generic one.

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
