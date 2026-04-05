# Personal Dotfiles Config Project

Dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Configuration lives in `packages/` and is symlinked to `$HOME` via `make dotfiles`.

## External File Loading

CRITICAL: When you encounter a file reference (e.g., @rules/general.md), use your Read tool to load it on a need-to-know basis. They're relevant to the SPECIFIC task at hand.

Instructions:

- Do NOT preemptively load all references - use lazy loading based on actual need
- When loaded, treat content as mandatory instructions that override defaults
- Follow references recursively when needed

## Project Structure

```
packages/          # Stow packages (each maps to $HOME paths)
  nvim/            # Primary config — Neovim (LazyVim-based)
  zsh/             # Shell config
  tmux/            # Terminal multiplexer
  gitconfig/       # Git config
  ssh/             # SSH config
  starship/        # Prompt theme
  ghostty/         # Terminal emulator
  asdf/            # Version manager
  homebrew/        # Brewfile
  opencode/        # AI assistant config
  ...
osx/               # macOS-specific defaults & bootstrap scripts
scripts/           # Utility scripts (stow.sh, plugins.sh, etc.)
Makefile           # Command entrypoint
```

### Commands

All commands run through the Makefile:

| Command | Description |
|---|---|
| `make dotfiles` | Stow all packages (symlink to `$HOME`) |
| `make bootstrap` | Full machine provisioning (platform-aware) |
| `make apply_settings` | Apply OS-level defaults (macOS only currently) |

### Neovim

Primary editor config located at `packages/nvim/.config/nvim/`. Key areas:

- `lua/config/` — core options, keymaps, autocmds
- `lua/plugins/` — plugin definitions (lsp, ai, coding, editor, ui, etc.)
- `lua/lang/` — LSP configuration per language (each file configures a language server: typescript, ruby, golang, rust, lua, bash, markdown, mdx, terraform, c, sorbet, ember, ember_glint, base)

When working on any Neovim or Lua config task, load: @docs/instructions/neovim.md

### Platform Support

- **macOS** — fully supported (`osx/` defaults, Homebrew bootstrap)
- **Linux** — targets exist in Makefile but not yet implemented

### Conventions

- Each `packages/<name>/` directory mirrors the `$HOME` path structure for Stow
- No manual symlinks — always use `make dotfiles`
- Platform-specific logic belongs in `osx/` (later: `linux/`)


