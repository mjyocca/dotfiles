# Bash Agent Instructions

Instructions and conventions for working on the bash configuration.
All files live under `packages/bash/` and are stowed to `$HOME`.

---

## File Layout

```
packages/bash/
  .bash_profile           # Sources .bashrc for login shells
  .bashrc                 # All config — env vars, tools, aliases
  .bashrc.local           # Per-machine overrides — git-ignored
  .config/bash/
    nvim.bash             # Neovim aliases (nv, nv-*, nvim-*)
```

### Bash startup model (vs. zsh)

| File                | Login | Interactive | Script |
|---------------------|-------|-------------|--------|
| `.bash_profile`     | yes   | no          | no     |
| `.bashrc`           | via .bash_profile | yes | no   |
| `.bashrc.local`     | via .bash_profile | yes | no   |

Unlike zsh, bash has **no universal file** equivalent to `.zshenv`.
Environment variables live in `.bashrc` with an interactive-only guard.
`.bash_profile` exists solely to source `.bashrc` for login shells.

📖 [GNU Bash — Startup Files](https://www.gnu.org/software/bash/manual/bash.html#Bash-Startup-Files)

---

## Cross-platform architecture

`.bashrc` handles two environments via a single conditional:

**On Omarchy (Linux):**
- Sources `/usr/share/omarchy/default/bash/env-bootstrap`
- Non-interactive shells return here (env vars still set)
- Sources `$OMARCHY_PATH/default/bash/rc` — gets starship, mise, zoxide,
  fzf, bash-completion, aliases, functions

**On non-Omarchy (macOS, other Linux):**
- Initializes tools directly (guarded by `command -v`)
- Sources fzf / bash-completion from standard locations

📖 [Omarchy dotfiles manual](https://omarchy.org/manual/dotfiles/) — bash override model

---

## Current `.bashrc` structure

1. **Environment block** — PATH, asdf shims, XDG, EDITOR/PAGER
2. **Omarchy bootstrap** — conditional source + interactive guard
3. **Standalone tool init** — starship, mise, zoxide, fzf, bash-completion
   (skipped on Omarchy)
4. **Cross-platform tool hooks** — direnv, PNPM PATH
5. **Neovim aliases** — `source ~/.config/bash/nvim.bash`
6. **Local overrides** — bootstrap + source `.bashrc.local`

---

## Conventions

- **PATH additions use idempotent `case ":$PATH:"` guards.** `.bashrc` is
  re-sourced on nested shells and login shell chains.
- **Tool init uses `command -v` guards.** Never assume a tool is present.
- **Interactive-only code must come after the `$-` check.** Env vars at the
  top of `.bashrc` must be safe for non-interactive shells (fast, no output).
- **Do not add Omarchy-specific init to the standalone block.** It's already
  handled by `$OMARCHY_PATH/default/bash/rc`.
- **`$OMARCHY_PATH` is the cross-platform signal.** Its presence means
  "Omarchy handled these tools." Its absence means "initialize them ourselves."
- **`.bashrc.local` is sourced last.** Lets it override anything set above.
- **No hardcoded usernames or absolute paths.** Use `$HOME` everywhere.
- **One concern per section, with a comment header.**

---

## Local overrides

Same pattern as `.zshrc.local`. Git-ignored, auto-bootstrapped on first
interactive shell with a commented template. Use for:
- Work-specific tool init, VPN aliases, corporate PATH entries
- Secret exports (GITHUB_TOKEN, API keys)
- Machine-specific overrides to shared config

---

## Adding a new tool

### Interactive-only, needed on all platforms (e.g. new CLI with a hook)

Add after the standalone tool init block:
```bash
# MyTool (see https://mytool.dev)
command -v mytool &>/dev/null && eval "$(mytool init bash)"
```

### Needed by scripts too (env var or PATH)

Add at the top of `.bashrc` (before the interactive check):
```bash
export MYTOOL_DIR="$HOME/.mytool"
case ":$PATH:" in
  *":${MYTOOL_DIR}/bin:"*) ;;
  *) export PATH="${MYTOOL_DIR}/bin:$PATH" ;;
esac
```

### Already in Omarchy defaults

Don't add it to the standalone block. It's already available on Omarchy via
`$OMARCHY_PATH/default/bash/rc`. If you need it on macOS too, add to the
standalone block with a `command -v` guard.

### Machine-specific setting

Don't touch `.bashrc`. Add to `~/.bashrc.local` on that machine.

---

## Sources

- [GNU Bash manual](https://www.gnu.org/software/bash/manual/)
- [Omarchy dotfiles manual](https://omarchy.org/manual/dotfiles/)
- [bash-completion](https://github.com/scop/bash-completion)
- [mise activate](https://mise.jdx.dev/)
- [direnv hook](https://direnv.net/docs/hook.html)
- [zsh instructions](./zsh.md) — macOS shell equivalent

_Last synced: 2026-01-23_
