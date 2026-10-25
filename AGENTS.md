# Personal Dotfiles Config Project

Dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Configuration lives in `packages/` and is symlinked to `$HOME` via `make dotfiles`.

## External File Loading

CRITICAL: When you encounter a file reference (e.g., @rules/general.md), use your Read tool to load it on a need-to-know basis. They're relevant to the SPECIFIC task at hand.

Instructions:

- Do NOT preemptively load all references - use lazy loading based on actual need
- When loaded, treat content as mandatory instructions that override defaults
- Follow references recursively when needed

## docs/ Reading Policy

- `docs/instructions/` — agent-facing. Load on demand when relevant to the task.
- `docs/reference/` and all other `docs/` subdirectories — human-facing reference material. Do NOT read unless explicitly asked to.

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
  homebrew/        # Brewfile (macOS only)
  colima/          # Colima VM config (macOS only)
  opencode/        # AI assistant config
  ...
profiles/          # OS profile allow-lists (one package name per line)
  macos            # Packages to stow on macOS
  omarchy          # Packages to stow on Omarchy Linux
osx/               # macOS-specific defaults & bootstrap scripts
scripts/           # Utility scripts (stow.sh, detect-os.sh, plugins.sh, etc.)
Makefile           # Command entrypoint
```

### Commands

All commands run through the Makefile:

| Command | Description |
|---|---|
| `make dotfiles` | Stow packages for current OS profile into `$HOME` (profile − ignore list) |
| `make dotfiles PROFILE=omarchy` | Force a specific profile |
| `make stow PKG=<name>` | Stow a single package by name (bypasses profile + ignore) |
| `make stow PKG="a b c"` | Stow multiple specific packages |
| `make bootstrap` | Full machine provisioning (platform-aware) |
| `make apply_settings` | Apply OS-level defaults (macOS only currently) |

#### Profile-based package selection

Dotfiles are selected per OS via **profiles** in `profiles/<name>`. Each profile
lists which packages to stow on that OS. The Makefile auto-detects the active
profile from the running OS (or `PROFILE=...` override).

| OS / Distro | Profile | Notes |
|---|---|---|
| macOS (Darwin) | `macos` | Includes `homebrew`, `colima` |
| Omarchy (Arch-based Linux) | `omarchy` | Excludes `homebrew`, `colima` |

Detection logic (in `scripts/detect-os.sh`):
- `uname -s == Darwin` → `macos`
- `/etc/os-release` `ID=omarchy` or `ID_LIKE` contains `arch` → `omarchy`
- Other Linux → uses `$ID` directly (no profile yet)

To add a package to a profile, edit the relevant `profiles/<name>` file.

#### Per-machine package ignore list

Create a `.stow-ignore.local` file at the repo root to skip packages on a
specific machine. The file is git-ignored and never committed.

```
# .stow-ignore.local — example for a work machine
# One package name per line. Blank lines and # comments are ignored.
zsh
homebrew
```

`make dotfiles` reads this file automatically and skips any listed packages.
`make stow PKG=<name>` always bypasses the ignore list.

### Neovim

Primary editor config located at `packages/nvim/.config/nvim/`. Key areas:

- `lua/config/` — core options, keymaps, autocmds
- `lua/plugins/` — plugin definitions (lsp, ai, coding, editor, ui, etc.)
- `lua/lang/` — LSP configuration per language (each file configures a language server: typescript, ruby, golang, rust, lua, bash, markdown, mdx, terraform, c, sorbet, ember, ember_glint, base)

When working on any Neovim or Lua config task, load: @docs/instructions/neovim.md

### Zsh

Shell config located at `packages/zsh/`. Three-file layout:

- `.zshenv` — PATH and env vars for every shell context (scripts, cron, interactive)
- `.zshrc` — interactive shell only (prompt, plugins, tool hooks)
- `.zshrc.local` — per-machine overrides, git-ignored, auto-bootstrapped on first shell open

When working on any zsh config task, load: @docs/instructions/zsh.md

### Platform Detection & Instructions

OS-specific conventions and bootstrap instructions live in `docs/instructions/<profile>.md`.
Before any OS-specific task (bootstrap, apply_settings, desktop config), detect the profile:

```bash
./scripts/detect-os.sh --print  # outputs: macos | omarchy | ubuntu | etc.
```

Then load the matching instruction file:

| Profile | Instructions File |
|---|---|
| `macos` | `@docs/instructions/macos.md` |
| `omarchy` | `@docs/instructions/omarchy.md` |

**When to load:** Before any OS-specific task. Don't guess — detect first.

**Complex OS tooling:** For Omarchy desktop config (Hyprland, bar, themes), also
invoke the `omarchy` skill (already available).

### Security: Gitleaks Integration

**Gitleaks** scans git commits for secrets (API keys, tokens, passwords) and prevents them from being committed.

**Pre-commit hook** is installed via `scripts/install-git-hooks.sh` and runs automatically on every commit:
- Scans staged changes for secrets
- Blocks commit if secrets detected
- Provides guidance on how to fix

**Manual usage:**
```bash
# Scan staged changes
gitleaks protect --staged

# Scan entire repository history
gitleaks detect --source . --log-level info

# Scan specific commit
gitleaks protect --commit <sha>
```

**Configuration** (optional): Create `.gitleaks.toml` in repo root to:
- Allowlist specific paths (e.g., test fixtures)
- Add custom patterns
- Exclude false positives

**Installation:**
- macOS: `brew install gitleaks` (in Brewfile)
- Linux: `sudo pacman -S gitleaks` (via bootstrap_linux)
- Git hook: `make install_git_hooks` or `scripts/install-git-hooks.sh`

### Linux Package Management (Omarchy/Arch)

**Package tracking** uses three curated files following community convention:

```
packages/pacman/
├── packages.txt       # System packages (infrastructure, CLI tools)
├── packages-gui.txt   # GUI applications
└── packages-aur.txt   # AUR packages
```

**Format:** One package per line, comments with `#`:
```
# Core Infrastructure
git
stow
curl
```

**Maintenance commands:**
```bash
# Install from package lists
sudo pacman -S --needed - < packages/pacman/packages.txt
sudo pacman -S --needed - < packages/pacman/packages-gui.txt
yay -S --needed - < packages/pacman/packages-aur.txt

# Export currently installed packages (then curate!)
pacman -Qqen > packages/pacman/packages.txt
pacman -Qqem > packages/pacman/packages-aur.txt

# Find untracked packages
./scripts/find-untracked-packages.sh
```

**Package categories:**

| Category | File | Examples |
|----------|------|----------|
| System packages | `packages.txt` | git, curl, stow, docker, cmake |
| GUI applications | `packages-gui.txt` | 1password, alacritty, spotify |
| AUR packages | `packages-aur.txt` | brave-bin, heroic-games-launcher |
| Dev tools | `packages/mise/.config/mise/config.toml` | gitleaks, lazygit, jq, ripgrep |

**What NOT to track:**
- Hardware-specific drivers (amd-ucode, vulkan-radeon, etc.)
- Omarchy defaults (already in `/usr/share/omarchy/install/omarchy-base.packages`)
- Packages managed by mise (see `packages/mise/.config/mise/config.toml`)

**Note:** Omarchy uses `omarchy pkg add <package>` for interactive installation, but doesn't provide user-level package tracking. These files serve as your declarative package manifest.

### Dev Tools (mise)

Dev tools are managed via [mise](https://mise.jdx.dev/) for cross-platform consistency. Configuration lives at `packages/mise/.config/mise/config.toml` and is stowed to `~/.config/mise/config.toml`.

**What belongs in mise:**
- CLI tools used across projects (gitleaks, lazygit, jq, ripgrep, etc.)
- TUI tools (btop, yazi, superfile, etc.)
- Shell utilities (starship, direnv, zoxide, etc.)

**What stays in Homebrew/pacman:**
- System infrastructure (git, curl, stow, build tools)
- System services (docker, systemd units)
- GUI applications (editors, browsers, etc.)

**Commands:**
```bash
mise install          # Install all tools from config.toml
mise update           # Update all tools
mise add <tool>       # Add a new tool
mise list             # List installed tools
```

**Decision matrix for new packages:**

| Category | Manager | Example |
|----------|---------|---------|
| System infrastructure | Homebrew/pacman | git, curl, gcc, cmake |
| System services | Homebrew/pacman | docker, colima |
| GUI applications | Homebrew/pacman | vscode, alacritty |
| Dev CLI tools | mise | gitleaks, lazygit, jq |
| TUI tools | mise | btop, yazi, superfile |
| Shell utilities | mise | starship, direnv, zoxide |

### `dotf` — daily-use toolbox

`dotf` is a dispatcher script stowed to `~/.local/bin/dotf`. It routes
subcommands to individual scripts in `~/.local/bin/dotf.d/`. Source lives at:

```
packages/scripts/.local/bin/
  dotf            # dispatcher — routes dotf <cmd> [args] to dotf.d/<cmd>
  dotf.d/         # one executable file per subcommand
    colima-use              # switch colima profile + docker context + socket
    colima-list             # list profiles, states, contexts
    colima-migrate-volumes  # export/import volumes between colima profiles
    init                    # scaffold template files into the current project root (fzf picker)
```

Running `dotf --help` auto-lists all commands with their one-line descriptions
(pulled from the second line of each script).

**Adding a new subcommand:**

1. Create an executable file at `packages/scripts/.local/bin/dotf.d/<name>`
2. Line 1: `#!/usr/bin/env bash`
3. Line 2: a `# <one-line description>` comment — this is what `dotf --help` prints
4. Run `make dotfiles` to stow it into `~/.local/bin/dotf.d/`

---

### Makefile vs. `dotf` — where to put new commands

| Criterion | Makefile target | `dotf` subcommand |
|---|---|---|
| Operates on the dotfiles repo itself | yes | no |
| Run during bootstrap / provisioning | yes | no |
| Needs to be available everywhere on the machine | no | yes |
| Used interactively during normal daily work | no | yes |
| Manages external tools (docker, colima, editors…) | no | yes |
| Accepts dynamic arguments / flags | awkward | natural |

**Use a Makefile target when** the command is about the dotfiles project:
provisioning a machine, stowing packages, applying OS defaults, installing
tools. These run once or rarely and operate on the repo itself.

**Use a `dotf` subcommand when** the script is a general-purpose utility that
should be available anywhere in a shell session: switching runtimes, managing
containers, scaffolding projects, or any workflow tool that travels with the
developer rather than the repo.

---

### Security Practices

Learnings from a security audit of this repo. Apply these when adding or
modifying any package config.

**Never commit secrets or credentials**
- Secrets, API keys, and tokens belong in `~/.zshrc.local` (git-ignored)
- Never put real values in `.zshenv` or `.zshrc` — those are committed
- The `.zshrc.local` bootstrap in `.zshrc` exists specifically for this

**Never hardcode usernames or absolute paths**
- Always use `$HOME` or `~` — never `/Users/<name>/...`
- Hardcoded paths break on other machines and leak identity in public repos

**Scope VM mounts tightly**
- Do not mount `/Users` (entire home directory) into a VM — it grants every
  process in the VM read/write access to `~/.ssh`, `~/.aws`, `~/.config`, etc.
- Scope colima mounts to specific project directories (e.g. `~/code`)
- Mounts in colima are mutable post-creation via `~/.colima/<profile>/colima.yaml`

**Do not commit runtime SSH includes**
- OrbStack and similar tools auto-inject `Include` directives into `~/.ssh/config`
- These reference runtime-generated files with internal hostnames and VM IPs
- Remove any auto-injected `Include` stanzas before committing `packages/ssh/.ssh/config`

**Keep git config email private**
- Use GitHub's noreply address format: `<id>+<username>@users.noreply.github.com`
- Never commit a real personal email address in `packages/gitconfig/.gitconfig`

**git-ignore all per-machine local files**
- `.stow-ignore.local` — machine-specific package ignore list
- `packages/zsh/.zshrc.local` — machine-specific shell overrides
- `packages/zsh/.global_env.sh` — legacy, replaced by `.zshrc.local`

---

### Conventions

- Each `packages/<name>/` directory mirrors the `$HOME` path structure for Stow
- No manual symlinks — always use `make dotfiles`
- Platform-specific logic belongs in `osx/` (later: `linux/`)


