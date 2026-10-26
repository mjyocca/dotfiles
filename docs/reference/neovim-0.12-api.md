# Neovim 0.12 API Additions

Reference for Lua standard library additions, new options, highlight groups, and events introduced in Neovim 0.12. Load when debugging 0.12 compatibility or exploring new APIs.

For config conventions, LSP patterns, and plugin management see `@docs/instructions/neovim.md`.

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

_Last synced: 2026-01-23_
