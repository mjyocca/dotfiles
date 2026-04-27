# Zsh Agent Instructions

Instructions and conventions for working on the zsh configuration.
All files live under `packages/zsh/` and are stowed to `$HOME`.

---

## File Layout

```
packages/zsh/
  .zshenv       # Sourced by every zsh shell — env vars and PATH only
  .zshrc        # Sourced by interactive shells — prompt, plugins, tools
  .zshrc.local  # Per-machine overrides — git-ignored, never committed
```

### Load order

| File | Login | Interactive | Script | `zsh -c` |
|---|---|---|---|---|
| `.zshenv` | yes | yes | yes | yes |
| `.zshrc` | no | yes | no | no |
| `.zshrc.local` | no | yes | no | no |

`.zshenv` is the only file guaranteed to run in every zsh context.

---

## What belongs in each file

### `.zshenv` — every shell

Only exports that a non-interactive script might need:

- `PATH` entries for tools scripts call directly (shims, `~/.local/bin`, `~/bin`)
- Tool data directories (`ASDF_DATA_DIR`, `GOPATH`, etc.) that shims or
  sub-processes depend on to locate the right binary version
- Universal environment: `EDITOR`, `PAGER`, `LANG`, `XDG_*`

**Never put in `.zshenv`:**
- Aliases or functions
- Prompt init (`starship`, `oh-my-zsh`)
- Plugin hooks (`direnv hook`, `fzf --zsh`)
- Anything that produces output or is slow to evaluate
- Tool PATH entries only needed at a terminal (e.g. `PNPM_HOME`)

### `.zshrc` — interactive shells only

Everything that only makes sense when a human is typing:

- Prompt init (`starship init zsh`)
- Plugin sources (`zsh-autosuggestions`, `fzf --zsh`)
- Tool hooks (`direnv hook zsh`, `compinit`)
- Completions and `fpath` additions
- Aliases, functions, keybindings
- Language tool PATH entries used interactively (`PNPM_HOME`, etc.)
- Language plugin hooks that produce side effects (`asdf golang set-env.zsh`)
- The `.zshrc.local` bootstrap and source (always at the end)

### `.zshrc.local` — per-machine overrides

Git-ignored. Created automatically with a commented template on the first
interactive shell open if it does not exist (bootstrapped by `.zshrc`).

Use for anything that differs between machines and must not be committed:

- Work-specific tool init, VPN aliases, corporate `PATH` entries
- Secret exports (`GITHUB_TOKEN`, API keys)
- Machine-specific overrides to shared config

---

## Current `.zshenv` contents

```zsh
# PATH: user-local bins (idempotent guards on all entries)
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"

# asdf shims — must be available to all shells and scripts
export ASDF_DATA_DIR="$HOME/.asdf"
export PATH="${ASDF_DATA_DIR}/shims:$PATH"

# Standard environment
export EDITOR="nvim"
export PAGER="less"
```

All PATH additions use `case ":$PATH:"` guards to prevent duplicates when
`.zshenv` is sourced multiple times (e.g. nested shells).

---

## Current `.zshrc` structure

1. Starship prompt init
2. `.zshrc.local` bootstrap (create from template if missing)
3. asdf completions + `compinit`
4. asdf Golang plugin hook
5. PNPM PATH
6. CLI tool hooks: `direnv`, `fzf`, `zsh-autosuggestions`
7. asdf shims re-prioritisation (see below)
8. Source `.zshrc.local`

### asdf shims re-prioritisation

Tools like PNPM prepend to `$PATH` during `.zshrc`, pushing the asdf shims
(set early in `.zshenv`) below system-installed binaries. On macOS this causes
the OS-bundled Ruby (and potentially other system tools) to win over
asdf-managed versions in interactive shells.

The fix is to re-prepend the shims at the **end** of `.zshrc`, after all other
PATH modifications, using a move-to-front guard that avoids duplicates:

```zsh
case ":$PATH:" in
  *":${ASDF_DATA_DIR}/shims:"*) export PATH="${ASDF_DATA_DIR}/shims:${PATH#*${ASDF_DATA_DIR}/shims:}" ;;
  *) export PATH="${ASDF_DATA_DIR}/shims:$PATH" ;;
esac
```

This is intentional — not a duplication of `.zshenv`. The two serve different
purposes:
- `.zshenv` ensures shims are present for scripts and non-interactive shells
- `.zshrc` re-prioritises shims after interactive-only tools have had their turn

Do not remove either. Do not move this block above PNPM or other tool hooks.

---

## Conventions

- **PATH additions in `.zshenv` must use idempotent `case` guards.** Nested
  shells and scripts re-source `.zshenv`, so unguarded `export PATH=...:$PATH`
  will keep prepending duplicates.
- **`.zshrc.local` is always sourced last.** This lets it override anything
  set by shared config — aliases, PATH prepends, tool versions.
- **Do not hardcode usernames or absolute paths.** Use `$HOME` everywhere.
- **Do not add new PATH entries to `.zshrc` directly.** If a PATH entry is
  needed only interactively, add it to `.zshrc` with an idempotent guard. If
  scripts also need it, it belongs in `.zshenv`.
- **Do not remove the asdf shims re-prioritisation block at the end of `.zshrc`.**
  It exists specifically to counteract PATH ordering issues introduced by tools
  like PNPM. Moving it earlier defeats its purpose.
- **One concern per section, with a comment header.** Keep sections visually
  separated and easy to scan.

---

## Adding a new tool

### Tool only needed interactively (e.g. a new CLI with a shell hook)

Add to `.zshrc`:
```zsh
# MyTool (see https://mytool.dev)
eval "$(mytool init zsh)"
```

### Tool needed by scripts too (e.g. a new runtime manager)

Add the data dir and shims PATH to `.zshenv`:
```zsh
export MYTOOL_DIR="$HOME/.mytool"
case ":$PATH:" in
  *":${MYTOOL_DIR}/bin:"*) ;;
  *) export PATH="${MYTOOL_DIR}/bin:$PATH" ;;
esac
```

Then add completions and hooks to `.zshrc`:
```zsh
# MyTool completions
fpath=($MYTOOL_DIR/completions $fpath)
```

### Machine-specific setting (e.g. work proxy, API key)

Do not touch `.zshenv` or `.zshrc`. Add to `~/.zshrc.local` on that machine:
```zsh
export MYTOOL_API_KEY="..."
```
