# Personal Dotfiles Config Project

Dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Configuration lives in `packages/` and is symlinked to `$HOME` via `make dotfiles`.

## External File Loading

When you encounter a file reference (e.g., @docs/instructions/macos.md), use your Read tool to load it on a need-to-know basis.

- `docs/instructions/` — agent-facing. Load on demand when relevant to the task.
- `docs/reference/` and all other `docs/` subdirectories — human-facing reference material. Do NOT read unless explicitly asked to.

## Commands

| Command | Description |
|---|---|
| `make dotfiles` | Stow packages for current OS profile into `$HOME` |
| `make dotfiles PROFILE=omarchy` | Force a specific profile |
| `make stow PKG=<name>` | Stow a single package by name |
| `make bootstrap` | Full machine provisioning (platform-aware) |
| `make apply_settings` | Apply OS-level defaults |
| `make install_git_hooks` | Install gitleaks pre-commit hook |

## Project Structure

```
packages/          # Stow packages (each maps to $HOME paths)
  nvim/            # Neovim config
  bash/            # Shell config (Omarchy default)
  zsh/             # Shell config (macOS default)
  tmux/            # Terminal multiplexer
  gitconfig/       # Git config
  ssh/             # SSH config
  starship/        # Prompt theme
  ghostty/         # Terminal emulator
  pacman/          # System packages (Omarchy: packages.txt, packages-gui.txt, packages-aur.txt)
  homebrew/        # System packages (macOS: Brewfile)
  mise/            # Dev tools (cross-platform: config.toml)
  tool-versions/   # Language runtimes (cross-platform: .tool-versions)
profiles/          # OS profile allow-lists (one package name per line)
  macos            # Packages to stow on macOS
  omarchy          # Packages to stow on Omarchy Linux
scripts/
  macos/           # macOS bootstrap, defaults, config scripts
  omarchy/         # Omarchy-specific utility scripts
  detect-os.sh     # OS detection and profile selection
  stow.sh          # Stow orchestration
  install-git-hooks.sh  # Gitleaks pre-commit hook installer
docs/
  instructions/    # OS-specific conventions (load on demand)
    macos.md       # macOS conventions and package management
    omarchy.md     # Omarchy conventions and package management
    neovim.md      # Neovim conventions
    zsh.md         # Zsh conventions
    bash.md        # Bash conventions (Omarchy default)
.agents/skills/    # Reproducible workflows (load when task matches)
Makefile           # Command entrypoint
```

## Agent Instructions

Platform-specific and tool-specific instructions are in `docs/instructions/`:

- `@docs/instructions/neovim.md` — LazyVim config structure, plugin management, keymaps
- `@docs/instructions/zsh.md` — Shell config layout (zshenv/zshrc), prompt, plugin hooks
- `@docs/instructions/bash.md` — Bash config layout, Omarchy bootstrap, cross-platform tool init
- `@docs/instructions/omarchy.md` — Omarchy desktop conventions, Hyprland, theme management
- `@docs/instructions/macos.md` — macOS-specific setup, Homebrew, system preferences

Load these when working on the respective components.

## OS Detection & Profiles

```bash
./scripts/detect-os.sh --print  # outputs: macos | omarchy | ubuntu | etc.
```

Profiles are allow-lists in `profiles/<name>`. Each lists which packages to stow on that OS.

| OS | Profile | Notes |
|---|---|---|
| macOS | `macos` | Includes `homebrew`, `colima` |
| Omarchy | `omarchy` | Excludes `homebrew`, `colima` |

To add a package to a profile, edit the relevant `profiles/<name>` file.

Per-machine ignore list: `.stow-ignore.local` (git-ignored).

## Package Management Architecture

Choose by dependency: mission-critical, session-critical, or OS-integrated tools → Homebrew/pacman; version-switched or fast-moving cloud API tools → mise (unless needed independently of mise). Optional tools use mise when suitable; if both managers fit, first compare our existing package lists/config, then consult the package-management skill's upstream lookup if still ambiguous. Runtimes stay on asdf until their separate migration to mise. Track direct pacman dependencies explicitly; apply the curated lists with `bash scripts/omarchy/install-packages.sh` (`--dry-run` previews). Repository CLI/system and GUI lists use pacman; all AUR packages use the AUR list and yay. `--needed` skips up-to-date targets, not all installed packages. For details load:
- Cross-platform → `@docs/instructions/package-management.md`
- macOS → `@docs/instructions/macos.md`
- Omarchy → `@docs/instructions/omarchy.md`

Machine-specific pacman dependencies live in `packages/pacman/machines/<name>/`. Select one explicitly with `--machine <name>` in the Omarchy installer and discovery helper; shared lists are always included. Do not auto-detect the machine or put hardware-specific dependencies in shared lists.

## Skills

| Skill | Description | When to load |
|-------|-------------|--------------|
| `package-management` | Workflows for managing packages across platforms | Adding packages, installing software, troubleshooting conflicts |

## Security

**NEVER commit secrets or credentials.** Use `~/.bashrc.local` or `~/.zshrc.local` (git-ignored).

**NEVER hardcode usernames or absolute paths.** Always use `$HOME` or `~`.

**Gitleaks** pre-commit hook scans for secrets on every commit. Install with `make install_git_hooks`.

For detailed security practices (VM mounts, SSH includes, git email), see `@docs/reference/security.md`.

## Conventions

- Each `packages/<name>/` mirrors `$HOME` structure for Stow
- No manual symlinks — always use `make dotfiles`
- Platform-specific scripts belong in `scripts/macos/` or `scripts/omarchy/`
- Cross-platform scripts stay in `scripts/`
