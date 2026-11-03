# Personal Dotfiles Config Project

Dotfiles managed with [mise](https://mise.jdx.dev/). Configuration lives in `packages/` and is deployed to `$HOME` via `make link`.

## External File Loading

When you encounter a file reference (e.g., @docs/instructions/macos.md), use your Read tool to load it on a need-to-know basis.

- `docs/instructions/` — agent-facing. Load on demand when relevant to the task.
- `docs/reference/` and all other `docs/` subdirectories — human-facing reference material. Do NOT read unless explicitly asked to.

## Commands

| Command | Description |
|---|---|
| `make bootstrap` | Full machine provisioning (platform-aware, runs all layers) |
| `make prerequisites` | Install base tools (git, curl, make, etc.) |
| `make packages` | Install system packages via mise bootstrap |
| `make tools` | Install dev tools via mise |
| `make plugins` | Install zellij, tmux plugins |
| `make config` | Apply system/app configuration |
| `make hooks` | Install git hooks (gitleaks) |
| `make link` | Deploy dotfiles via mise to `$HOME` |
| `make pack` | Alias for `packages` |
| `make plug` | Alias for `plugins` |
| `make sync` | Run `make pack link plug` |
| `make apply_settings` | Apply OS-level defaults |

**Layer inheritance:** Scripts in `omarchy/` inherit from `linux/`. If a layer script doesn't exist in `omarchy/`, it falls back to the `linux/` version. This allows platform-specific overrides while sharing common logic.

## Project Structure

```
packages/          # Dotfile packages (each maps to $HOME paths)
  nvim/            # Neovim config
  bash/            # Shell config (Omarchy default)
  zsh/             # Shell config (macOS default)
  tmux/            # Terminal multiplexer
  gitconfig/       # Git config
  ssh/             # SSH config
  starship/        # Prompt theme
  ghostty/         # Terminal emulator
  mise/            # Dev tools (cross-platform: config.toml)
  tool-versions/   # Language runtimes (cross-platform: .tool-versions)
manifests/         # Repository-only provisioning manifests (not deployed to $HOME)
  pacman/          # Shared package lists and machine-specific overlays
  aur/             # AUR package list (Omarchy only)
scripts/
  shared/          # Common utilities (utils.sh, detect-os.sh)
  linux/           # Base layer scripts for all Linux distros
    prerequisites.sh  # git, curl, make, build tools
    packages.sh       # mise bootstrap
    tools.sh          # mise tool versions
    plugins.sh        # zellij, tmux plugins
    config.sh         # Linux-specific config
    hooks.sh          # git hooks
    installer.sh      # Generic Linux fresh install
  macos/           # macOS layer scripts (standalone, no inheritance)
    prerequisites.sh  # Xcode CLT, Homebrew
    packages.sh       # mise bootstrap
    tools.sh          # mise tool versions
    plugins.sh        # zellij, tmux plugins
    config.sh         # macOS defaults
    hooks.sh          # git hooks
    installer.sh      # Fresh Mac setup
  omarchy/         # Omarchy layer scripts (inherits from linux/)
    prerequisites.sh  # Inherits from linux/
    packages.sh       # Calls linux/packages.sh then aur.sh
    aur.sh            # AUR packages (yay, PKGBUILD review)
    config.sh         # Omarchy-specific config
    installer.sh      # Fresh Omarchy setup
    find-untracked.sh # Audit untracked packages
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

## OS Detection & Platforms

```bash
./scripts/shared/detect-os.sh  # outputs: macos | ubuntu | fedora | arch | omarchy | unknown
```

Platforms are defined in mise config files (`.config/mise/config.<platform>.toml`). Each platform config selects which packages to install via `[bootstrap.packages]`.

| OS | Platform | Notes |
|---|---|---|
| macOS | `macos` | Includes Homebrew packages in `config.macos.toml` |
| Omarchy | `omarchy` | Uses `config.omarchy.toml` + AUR packages |

To add a package to a platform, edit the relevant `.config/mise/config.<platform>.toml` file and add it to the `[bootstrap.packages]` table.

## Package Management Architecture

All system packages (Homebrew on macOS, pacman on Linux) are managed via mise bootstrap in platform-specific config files:
- **macOS:** `.config/mise/config.macos.toml` — Homebrew packages and casks
- **Omarchy:** `.config/mise/config.omarchy.toml` — pacman packages + AUR list in `manifests/aur/packages-aur.txt`

The `make bootstrap` flow runs layers in order: `prerequisites → packages → [aur on Omarchy] → tools → plugins → config → hooks`. Each layer is composable and can be run independently.

For adding packages or resolving ownership conflicts, load:
- Cross-platform → `@docs/instructions/package-management.md`
- macOS → `@docs/instructions/macos.md`
- Omarchy → `@docs/instructions/omarchy.md`

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

- Each `packages/<name>/` mirrors `$HOME` structure for mise
- No manual symlinks — always use `make link`
- Scripts are organized by **domain layer** (prerequisites, packages, tools, plugins, config, hooks), not by package type
- Platform-specific scripts live in `scripts/macos/`, `scripts/omarchy/`, or `scripts/linux/`
- Shared utilities live in `scripts/shared/`
- Scripts inherit: `omarchy/` falls back to `linux/` if a layer script doesn't exist
- All layer scripts must be idempotent and testable standalone
