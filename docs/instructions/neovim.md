# Neovim & Lua Agent Instructions

Instructions and best practices for configuring Neovim 0.12+. This config uses
[LazyVim](https://www.lazyvim.org/) as a base with [lazy.nvim](https://github.com/folke/lazy.nvim)
as the plugin manager. All Lua lives under `packages/nvim/.config/nvim/`.

---

## Config Structure

```
packages/nvim/.config/nvim/
  init.lua              # Entry point: bootstraps lazy.nvim, loads config modules
  lsp/                  # Per-server LSP configs (native vim.lsp.config, 0.10+)
  snippets/             # Global VSCode-format snippets (LuaSnip)
  lua/
    config/
      options.lua       # vim.opt, vim.g, vim.o settings
      keymaps.lua       # Keymap definitions (general, lsp, plugins)
      autocmds.lua      # Autocommand definitions (general, lsp, plugins)
      utils.lua         # Shared utility functions (includes lsp_servers())
    plugins/            # lazy.nvim plugin specs — one file per editor concern (see below)
    lualine/            # lualine component overrides
```

### `lua/plugins/` — concern-based layout

Each file groups plugins by the editor concern they address, not by plugin name.
When adding or modifying a plugin, place it in the file whose concern it belongs
to. Do not create new files unless a genuinely new concern is being introduced.

| File | Concern | Key plugins |
|---|---|---|
| `ai.lua` | AI / copilot integration | `folke/sidekick.nvim` |
| `coding.lua` | Completion, snippets, language-aware editing | `nvim-cmp`, `LuaSnip`, `nvim-autopairs`, `gopher.nvim` |
| `colorscheme.lua` | Color theme | `github-nvim-theme` |
| `debug.lua` | DAP debugger UI and adapters | `nvim-dap`, `nvim-dap-ui`, `mason-nvim-dap`, Go/Ruby adapters |
| `editor.lua` | Core editing experience | `telescope.nvim`, `which-key.nvim`, `gitsigns.nvim`, `Comment.nvim`, `todo-comments.nvim`, `nvim-colorizer.lua`, `render-markdown.nvim` |
| `formatting.lua` | Code formatting | `none-ls.nvim` (null-ls fork) |
| `integrations.lua` | External tool integrations | `nvim-tmux-navigation`, `vim-dadbod` + UI |
| `linting.lua` | Linting | `nvim-lint` |
| `lsp.lua` | LSP client, Mason, capabilities | `nvim-lspconfig`, `mason.nvim`, `mason-lspconfig.nvim`, `fidget.nvim`, `lsp_lines.nvim`, `lazydev.nvim` |
| `sessions.lua` | Session save/restore | `auto-session` |
| `snacks.lua` | Snacks.nvim — picker, lazygit, git browse, notifications, diagnostics | `folke/snacks.nvim` |
| `testing.lua` | Test runners | *(empty — reserved for neotest etc.)* |
| `ui.lua` | Visual chrome | `lualine.nvim`, `incline.nvim`, `noice.nvim`, `nvim-treesitter` (highlight/indent) |

---

## Lua API Conventions

### Always prefer high-level Lua APIs over Vimscript

| Avoid | Prefer |
|---|---|
| `vim.cmd("set foo=bar")` | `vim.opt.foo = bar` |
| `vim.cmd("set expandtab")` | `vim.opt.expandtab = true` |
| `vim.api.nvim_set_keymap(...)` | `vim.keymap.set(...)` |
| `vim.cmd("autocmd ...")` | `vim.api.nvim_create_autocmd(...)` |
| `vim.cmd("hi MyGroup ...")` | `vim.api.nvim_set_hl(0, "MyGroup", {})` |
| `autocmd BufRead + set ft=` | `vim.filetype.add({ filename = {...} })` |
| `nvim_treesitter#foldexpr()` | `v:lua.vim.treesitter.foldexpr()` |

### Keymaps

Use `vim.keymap.set` — it accepts Lua functions directly, supports `desc`, and
is the idiomatic 0.10+ API. Do not use `vim.api.nvim_set_keymap` for new code.

```lua
-- Correct
vim.keymap.set("n", "<leader>ff", function()
  require("snacks").picker.files()
end, { desc = "Find Files" })

-- Avoid
vim.api.nvim_set_keymap("n", "<leader>ff", ":Telescope find_files<CR>", { noremap = true, silent = true })
```

### Options

```lua
-- Correct
vim.opt.tabstop     = 2
vim.opt.shiftwidth  = 2
vim.opt.expandtab   = true

-- Avoid
vim.cmd("set tabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("set expandtab")
```

### Filetype detection

Use `vim.filetype.add` — do not create `BufRead`/`BufNewFile` autocmds just to
set a filetype.

```lua
vim.filetype.add({
  extension = { tsx = "typescriptreact" },
  filename  = { [".env"] = "sh", [".envrc"] = "sh" },
  pattern   = { ["%.env%..+"] = "sh" },
})
```

### Autocommands

Always assign autocommands to a named augroup with `clear = true` to prevent
duplication on re-source.

```lua
local group = vim.api.nvim_create_augroup("my-feature", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
  group    = group,
  pattern  = "*.lua",
  callback = function() end,
})
```

---

## Diagnostics (0.10+ API — required in 0.12)

`vim.diagnostic.disable()` was **removed** in 0.12. Use the unified `enable()`
API with a boolean first argument.

```lua
-- Enable diagnostics for current buffer
vim.diagnostic.enable(true, { bufnr = 0 })

-- Disable diagnostics for current buffer
vim.diagnostic.enable(false, { bufnr = 0 })

-- Configure signs through vim.diagnostic.config only
-- (sign_define / :sign-define for diagnostic signs was removed in 0.12)
vim.diagnostic.config({
  virtual_text  = false,
  virtual_lines = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN]  = "",
      [vim.diagnostic.severity.INFO]  = "",
      [vim.diagnostic.severity.HINT]  = "",
    },
  },
})
```

---

## LSP

### Config pattern (native `lsp/` directory)

Per-server config lives in `lsp/<server_name>.lua` at the config root (sibling
of `lua/`, not inside it). Neovim 0.10+ auto-loads these via `vim.lsp.config`
when the filename matches a known server name. nvim-lspconfig provides default
configs for most servers under the same `lsp/` convention — your file is merged
on top, with your values taking precedence.

```lua
-- lsp/gopls.lua
---@type vim.lsp.Config
return {
  settings = {
    gopls = { staticcheck = true },
  },
}
```

The `lsp/` filenames must match the server names as defined in
[nvim-lspconfig/lsp](https://github.com/neovim/nvim-lspconfig/tree/master/lsp).

**Do not use `lua/lang/` files or `lang/base.lua`** — that pattern is removed.
The old `mason-lspconfig` handlers loop that called `require("lspconfig")[name].setup()`
is also removed; `automatic_enable = true` replaces it.

### Capabilities — global wildcard

Broadcast `cmp_nvim_lsp` capabilities to all servers once via the `"*"` wildcard
in `plugins/lsp.lua`. Do not repeat this in individual `lsp/*.lua` files unless
overriding a specific capability for that server.

```lua
-- plugins/lsp.lua (done once, applies to all servers)
vim.lsp.config("*", {
  capabilities = vim.tbl_deep_extend(
    "force",
    vim.lsp.protocol.make_client_capabilities(),
    require("cmp_nvim_lsp").default_capabilities()
  ),
})
```

To override or extend capabilities for a single server, include a `capabilities`
key in that server's `lsp/<name>.lua`. It will be deep-merged on top of the
wildcard:

```lua
-- lsp/ts_ls.lua
---@type vim.lsp.Config
return {
  capabilities = vim.tbl_deep_extend(
    "force",
    vim.lsp.protocol.make_client_capabilities(),
    require("cmp_nvim_lsp").default_capabilities(),
    {
      workspace = { didChangeWatchedFiles = { dynamicRegistration = false } },
    }
  ),
}
```

### Mason `ensure_installed` — two-directory convention

There are two source directories. Use the correct one based on the tool type:

| Directory | Purpose | Scanner |
|---|---|---|
| `lsp/` | LSP servers only (must be in mason-lspconfig registry) | `require("config.utils").lsp_servers()` |
| `tools/` | Non-LSP mason packages: formatters, linters, DAP adapters, CLIs | `require("config.utils").tools()` |

Both lists are merged and passed to `mason-tool-installer` in `plugins/lsp.lua`.

**`lsp/` — LSP servers**

`lsp_servers()` scans `lsp/*.lua` at startup and filters the result against
mason-lspconfig's live registry map. Servers without a mason package (e.g.
`sorbet`, `ember`, `glint`) are silently skipped.

Adding a new `lsp/<name>.lua` file is sufficient — no other registration needed
as long as the server name is mason-installable.

**`tools/` — non-LSP mason packages**

`tools()` scans `tools/*.lua` at startup. Each file returns a `string[]` of
mason package names grouped by concern (one file per language or tool category):

```
tools/
  go.lua    -- gofumpt, goimports, gomodifytags, impl, golangci-lint
  lua.lua   -- stylua
```

Each file must return a plain table of mason package name strings:

```lua
-- tools/go.lua
return {
  "gofumpt",
  "goimports",
}
```

Adding a new `tools/<concern>.lua` file is sufficient — no other registration
needed.

**Never use `mason.nvim`'s `opts.ensure_installed`** — `mason.nvim` does not
have this option. It is silently ignored. All installation must go through
`mason-tool-installer` (via `lsp_servers()` + `tools()`) or `mason-nvim-dap`
(for DAP adapters managed in `plugins/debug.lua`).

**Decision guide — where to register a new tool:**

| Tool type | Example | Where |
|---|---|---|
| LSP server (in mason-lspconfig registry) | `gopls`, `golangci_lint_ls` | `lsp/<name>.lua` |
| Formatter / linter / CLI | `gofumpt`, `stylua`, `golangci-lint` | `tools/<concern>.lua` |
| DAP debug adapter | `delve`, `rdbg` | `mason-nvim-dap` `ensure_installed` in `plugins/debug.lua` |

To check whether a server name is in the mason-lspconfig registry before
creating an `lsp/` file, look it up in
[nvim-lspconfig/lsp](https://github.com/neovim/nvim-lspconfig/tree/master/lsp)
and cross-reference with mason-lspconfig's registry map.

### Semantic tokens

`semantic_tokens.start()`/`stop()` were renamed to `enable()` in 0.12.

```lua
vim.lsp.semantic_tokens.enable(true,  bufnr, client_id)
vim.lsp.semantic_tokens.enable(false, bufnr, client_id)
```

### JSON null values

In 0.12, JSON `"null"` from LSP messages is represented as `vim.NIL`, not `nil`.
Missing fields are still `nil`. When inspecting LSP response tables, check
explicitly:

```lua
if value == vim.NIL then
  -- field was explicitly null in JSON
end
```

### Built-in LSP keymaps (0.12 defaults — do not remap unless needed)

| Key | Action |
|---|---|
| `grn` | `vim.lsp.buf.rename()` |
| `grr` | `vim.lsp.buf.references()` |
| `gri` | `vim.lsp.buf.implementation()` |
| `gra` | `vim.lsp.buf.code_action()` |
| `grt` | `vim.lsp.buf.type_definition()` *(new in 0.12)* |
| `grx` | `vim.lsp.codelens.run()` *(new in 0.12)* |
| `K`   | `vim.lsp.buf.hover()` |

Avoid re-defining these in `LspAttach` unless overriding with a picker (e.g.
Snacks or Telescope). Remove any custom mappings that duplicate the defaults.

### `:lsp` command (new in 0.12)

Use `:lsp` to interactively inspect and manage active LSP clients. Prefer this
over `:LspInfo` (mason-lspconfig) for debugging attach issues.

### `:checkhealth vim.lsp` (new in 0.12)

Runs a health check showing which LSP features are attached to which buffers.
Use before filing LSP-related bug reports.

---

## Treesitter

### Folding

Use the native Lua foldexpr — no plugin dependency required.

```lua
vim.opt.foldmethod = "expr"
vim.opt.foldexpr   = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel  = 99
```

Do **not** use `nvim_treesitter#foldexpr()` (Vimscript shim from nvim-treesitter).

### Query linting

`ft-query-plugin` no longer enables `vim.treesitter.query.lint()` by default in
0.12. Enable it explicitly if needed:

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern  = "query",
  callback = function(ev)
    vim.treesitter.query.lint(ev.buf)
  end,
})
```

### `Query:iter_matches()` — "all" option removed

The transitional `all = true` option on `Query:iter_matches()` was removed in
0.12. Remove it from any custom treesitter query code.

---

## Lua Standard Library (0.12 additions)

### `vim.text.diff` (renamed from `vim.diff`)

```lua
-- 0.12+
local result = vim.text.diff(a, b, { result_type = "unified" })
```

### HTTP requests — `vim.net.request()`

```lua
-- No external curl wrappers needed
local response = vim.net.request("https://example.com/api/data")
```

### Iterator enhancements

```lua
-- :take() and :skip() now accept predicates in addition to counts
vim.iter({ 1, 2, 3, 4, 5 }):take(function(v) return v < 4 end):totable()
-- { 1, 2, 3 }

-- :unique() deduplicates
vim.iter({ 1, 1, 2, 3, 3 }):unique():totable()
-- { 1, 2, 3 }

-- vim.list.bisect() for binary search on sorted lists
local idx = vim.list.bisect({ 1, 3, 5, 7 }, 5)
```

### JSON improvements

```lua
-- Pretty-print with indent
vim.json.encode(data, { indent = 2, sort_keys = true })

-- Decode JSON with comments (e.g. JSONC / tsconfig)
vim.json.decode(text, { skip_comments = true })
```

### `vim.tbl_extend` function behavior

```lua
-- behavior can now be a function for custom merge logic
vim.tbl_deep_extend(function(key, a_val, b_val)
  -- return merged value
  return b_val
end, table_a, table_b)
```

### `vim.fs` additions

```lua
-- Get the last file extension
vim.fs.ext("foo.test.ts")  -- "ts"

-- Equal-priority root markers via nested lists
vim.fs.root(buf, { { "package.json", "Cargo.toml" }, ".git" })
```

### `vim.hl.range()` — timed highlights

```lua
vim.hl.range(bufnr, ns, "IncSearch", { 0, 0 }, { 0, 10 }, { timeout = 500 })
```

---

## Options Added in 0.12

| Option | Purpose |
|---|---|
| `'autocomplete'` | Enable native insert-mode auto-completion |
| `'pumborder'` | Border around popup menu |
| `'pummaxwidth'` | Maximum popup menu width |
| `'winborder'` | Default window border style (e.g. `"single"`, `"bold"`) |
| `'busy'` | Mark a buffer as "busy" (shown in statusline) |
| `'chistory'` / `'lhistory'` | Quickfix/loclist stack size |
| `'diffopt' inline:` | Inline diff highlighting within changed lines |
| `'completeopt' nearest` | Sort completions by distance to cursor |

```lua
-- Example: consistent border globally (replaces per-plugin border opts)
vim.opt.winborder = "single"
```

---

## Highlight Groups Added in 0.12

| Group | Purpose |
|---|---|
| `hl-DiffTextAdd` | Added text within a changed diff line |
| `hl-SnippetTabstopActive` | Currently active snippet tabstop |
| `hl-PmenuBorder` | Popup menu border |
| `hl-PmenuShadow` | Popup menu shadow |
| `hl-OkMsg` | Success messages |
| `hl-StderrMsg` / `hl-StdoutMsg` | stderr/stdout message differentiation |

---

## New Events in 0.12

| Event | Trigger |
|---|---|
| `MarkSet` | After user sets a mark |
| `SessionLoadPre` | Before loading a session file |
| `TabClosedPre` | Before a tabpage is closed |
| `CmdlineLeavePre` | Before leaving command-line mode |
| `Progress` | When a progress message is created or updated |

```lua
-- Example: hook into session load
vim.api.nvim_create_autocmd("SessionLoadPre", {
  callback = function()
    -- save state before session overwrites it
  end,
})
```

---

## Known Workarounds in This Config

### `init.lua` — mdx-analyzer single-brace glob patch

The mdx language server sends glob patterns like `**/*.{mdx}` (single item in
braces), which Neovim 0.12's stricter `vim.glob.to_lpeg` rejects. The patch in
`init.lua` collapses `{single}` → `single` before passing to the original
function.

```lua
-- init.lua (keep until mdx-analyzer is fixed upstream)
local orig_to_lpeg = vim.glob.to_lpeg
vim.glob.to_lpeg = function(pattern)
  local fixed = pattern:gsub('{(%w+)}', '%1')
  return orig_to_lpeg(fixed)
end
```

Remove this patch once the mdx-analyzer LSP sends valid glob patterns.

---

## Snippets

Snippets are provided by **LuaSnip** with `friendly-snippets` for community
snippets. Custom snippets use the VSCode JSON format and are loaded alongside
`friendly-snippets` in `plugins/coding.lua`.

### Global snippets

Live in `snippets/` at the config root. `package.json` is the manifest — add an
entry per language pointing to its JSON file:

```
snippets/
  package.json     ← manifest
  ruby.json        ← snippets for ruby filetype
  go.json          ← snippets for go filetype
```

`package.json`:
```json
{
  "name": "custom-snippets",
  "engines": { "vscode": "^1.11.0" },
  "contributes": {
    "snippets": [
      { "language": "ruby", "path": "./ruby.json" },
      { "language": "go",   "path": "./go.json" }
    ]
  }
}
```

Each JSON file is a flat map of snippet definitions — multiple snippets per
file, one file per language:

```json
{
  "display name": {
    "prefix": "trigger",
    "body": ["line one", "\t${1:placeholder}", "line two"],
    "description": "optional"
  }
}
```

### Per-project snippets

Use a `.nvim.lua` file at the project root (requires `vim.opt.exrc = true`,
already set in `options.lua`). Neovim sources it automatically on startup and
prompts to trust it on first open.

```lua
-- .nvim.lua (project root)
require("luasnip.loaders.from_vscode").lazy_load({
  paths = { vim.fn.getcwd() .. "/.nvim/snippets" },
})
```

Place snippet files under `.nvim/snippets/` using the same `package.json` +
per-language JSON structure as global snippets. Add `.nvim.lua` and `.nvim/`
to your global gitignore.

`lazy_load` is additive — per-project snippets layer on top of global ones.
If both define the same prefix for the same filetype, both appear in the
completion menu.

---

## Per-project Config

### `.nvim.lua` — standard approach

`vim.opt.exrc = true` (set in `options.lua`) causes Neovim to automatically
source a `.nvim.lua` file at the project root after lazy.nvim and all plugins
have loaded. Neovim prompts to trust the file on first open.

Use `:trust` to re-evaluate trust for the current file.

### `NVIM_LOCAL_CONFIG` — alternative for restricted projects

For projects where committing or gitignoring `.nvim.lua` at the root is not
practical, set `NVIM_LOCAL_CONFIG` in the project's `.envrc` to point to any
Lua file. It is sourced at the same point in startup as `.nvim.lua` and uses
the same `vim.secure.read` trust prompt.

```bash
# .envrc
export NVIM_LOCAL_CONFIG=".config/nvim.lua"   # relative to project root
export NVIM_LOCAL_CONFIG="/abs/path/nvim.lua"  # or absolute
```

The file itself follows the same conventions as `.nvim.lua` — see the template
for documented examples.

### `dotf nvim-project-init` — scaffold both files from templates

Run `dotf nvim-project-init` from any project root to copy the template files:

```bash
dotf nvim-project-init
# wrote .envrc
# wrote .nvim.lua
```

Existing files are skipped. Templates live at:

```
packages/nvim/.config/nvim/templates/
  .envrc.template     ← direnv env vars including NVIM_LOCAL_CONFIG
  .nvim.lua.template  ← LSP overrides, snippets, keymaps, DAP configs
```

Both templates are fully commented — uncomment and adapt the sections relevant
to the project. After generating:

```bash
direnv allow       # load the .envrc
# edit .envrc      # uncomment env vars for this project
# edit .nvim.lua   # uncomment overrides for this project
```

### Snippet navigation keymaps

| Key | Action |
|---|---|
| `<C-l>` | Expand or jump forward through tabstops |
| `<C-h>` | Jump backward through tabstops |

---

## Neovim 0.12 Reserved Keys

`<Tab>` is reserved in 0.12 for built-in edit suggestions (next edit / apply
inline suggestion). Do not remap `<Tab>` or `<S-Tab>` for any custom purpose.

## Snacks.nvim

Snacks picker supports `pick_win` — a Snacks-internal action that renders
floating letter-hint overlays on each visible split, letting you choose which
window a file opens into. Bind it as `{ "pick_win", "jump" }` on any picker
source. Note: sources that use `focus = "list"` (e.g. the explorer) do not
inherit input window defaults and require the binding to be set explicitly on
the `list` window keys.

### Floating explorer keymaps

| Key | Layout |
|---|---|
| `-` | `dropdown` — centered float |
| `<leader>-` | `ivy` — bottom panel |

Both floating variants override the explorer source default of
`jump = { close = false }` (designed for the persistent sidebar) with
`jump = { close = true }` so `<CR>` closes the picker.

**Single file:**

| Key | Behaviour |
|---|---|
| `<CR>` | Open in previously focused split, close picker |
| `<S-CR>` | Show `pick_win` split overlay, open in chosen split, close picker |

**Multi-file (`<Tab>` to select, then `<S-CR>` per file):**

1. `<Tab>` — mark files for assignment (visual selection highlight)
2. `<S-CR>` — show split overlay, open the first selected file in chosen split,
   deselect it, return focus to picker
3. Repeat `<S-CR>` for each remaining selected file
4. `<Esc>` or `q` — close picker when done

The `pick_win_stay` custom action (registered in `picker.actions`) handles the
branching: if tab-selected items exist it stays open and processes one file per
keypress; if no tab selection it closes after opening.

---

## Anti-Patterns to Avoid

- Do not call `vim.cmd(...)` for anything that has a `vim.opt` / `vim.keymap.set` / `vim.api` equivalent.
- Do not use `vim.diagnostic.disable()` — removed in 0.12.
- Do not configure diagnostic signs with `:sign-define` or `sign_define()` — removed in 0.12.
- Do not use `nvim_treesitter#foldexpr()` — use `v:lua.vim.treesitter.foldexpr()`.
- Do not use `vim.diff(...)` — renamed to `vim.text.diff(...)` in 0.12.
- Do not re-define default LSP keymaps (`grn`, `grr`, `gri`, `gra`, `grt`, `grx`, `K`) unless intentionally overriding with a picker.
- Do not add `Query:iter_matches()` calls with `all = true` — removed in 0.12.
- Do not use `vim.loop` — prefer `vim.uv` (alias established in 0.10, `vim.loop` deprecated).
- Do not add LSP server config in `lua/lang/` files — that pattern is removed. Use `lsp/<server>.lua` instead.
- Do not call `require("lspconfig")[name].setup(...)` manually — `automatic_enable = true` handles this.
- Do not use `vim.lsp._enabled_configs` — private API, unreliable at plugin config time. Use `require("config.utils").lsp_servers()`.
- Do not repeat the global capabilities wildcard in individual `lsp/*.lua` files unless overriding a server-specific capability.
- Do not use `mason.nvim` `opts.ensure_installed` — `mason.nvim` has no such option; it is silently ignored. Use `tools/<concern>.lua` for non-LSP packages instead.
- Do not add non-LSP tools (formatters, linters, CLIs) to `lsp/` files — `lsp/` is for LSP servers only. Non-LSP mason packages belong in `tools/<concern>.lua`.
- Do not hardcode tool lists in `plugins/lsp.lua` or `plugins/formatting.lua` — all mason packages are registered via `lsp/` or `tools/` and auto-collected at startup.
- Do not use `dofile` to source trusted project config — it bypasses the `vim.secure` trust check entirely. Use `NVIM_LOCAL_CONFIG` in `.envrc` and let `autocmds.local_config()` handle sourcing via `vim.secure.read`.
