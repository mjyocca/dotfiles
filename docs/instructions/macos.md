# macOS Instructions

This file captures macOS-specific conventions, override paths, package management, and troubleshooting. Keep content lean — link out, don't duplicate.

## Key Concepts

- **Package management**: Homebrew for platform/session tools, mise for optional/version-sensitive tools, asdf for language runtimes (interim)
- **Shell**: Zsh is default shell on macOS
- **Dotfiles management**: mise for dotfile management
- **System defaults**: Managed via `defaults write` in `scripts/macos/`
- **Docker**: Colima for container runtime (macOS-only)

## System Configuration

### Override Paths
- **User config**: `~/.config/` (XDG standard)
- **Applications**: `/Applications/`
- **Homebrew prefix**: `/opt/homebrew/` (Apple Silicon) or `/usr/local/` (Intel)
- **LaunchAgents**: `~/Library/LaunchAgents/`

### macOS Defaults
System preferences are managed via `apply-user-defaults` using YAML files:
- `scripts/macos/defaults.yml` — System defaults
- `scripts/macos/defaults.apps.yml` — Application-specific defaults

**Apply defaults:**
```bash
make apply_settings
# or directly:
apply-user-defaults ./scripts/macos/defaults.yml
apply-user-defaults ./scripts/macos/defaults.apps.yml
```

### Common Tasks

**Install dotfiles:**
```bash
make link  # Deploys dotfiles via mise
```

**Install all packages:**
```bash
make packages  # Uses mise bootstrap to install Homebrew packages
```

**Colima (Docker):**
```bash
colima start              # Start Docker daemon
colima stop               # Stop Docker daemon
colima status             # Check status
```

## Package Management

### System Packages (Homebrew)

All system packages are managed via mise bootstrap in `.config/mise/config.macos.toml`. Homebrew packages are declared with `brew:` prefix, and GUI apps use `brew-cask:` prefix.

**Config location:** `.config/mise/config.macos.toml` under `[bootstrap.packages]`

#### Commands

```bash
# Install all packages via mise bootstrap
make packages
# or directly:
mise bootstrap

# Update all packages
brew update && brew upgrade

# List installed packages
brew list

# Install a single package (add to config.macos.toml, then run make packages)
brew install <package>

# Install a GUI app (cask)
brew install --cask <app>
```

#### What NOT to Track

**❌ Do NOT add to mise config (as Homebrew packages):**

1. **Tools managed by mise as dev tools**
   - Version-sensitive/optional tools like gitleaks, gh, kubectl, opencode, television
   - These belong in `packages/mise/.config/mise/config.toml` under `tools`

2. **Language runtimes**
   - Don't install node, ruby, go via Homebrew
   - Use mise for version management

**✅ DO track as Homebrew packages:**
1. **System infrastructure** you depend on (git, curl, stow, build tools)
2. **System services** you use (docker, colima)
3. **GUI applications** you launch from app menu
4. **Session-critical and other platform-managed CLI/TUI tools** (starship, direnv, fzf, jq, lazygit, ripgrep, tmux)
5. **Optional/version-sensitive tools** in mise; **language runtimes** in mise

## Dev Tools & Language Runtimes

Dev tools and language runtimes are managed through mise. Tools are installed via the tools layer:

```bash
make tools  # Installs dev tools via mise
```

This runs `mise install` which reads tool versions from the mise configuration. Language runtimes (node, python, ruby, etc.) are also managed via mise using the asdf plugin system.

See [package management instructions](./package-management.md) for details on adding new tools and managing versions.

## Troubleshooting

### GUI app vs system package?

**Rule of thumb:**
- If it has a GUI and you launch it from `/Applications/` → Homebrew cask
- If it's a system service or a platform-managed CLI tool → Homebrew formula; classify other CLIs with the [ownership criteria](./package-management.md)

**Examples:**
- ✅ alacritty (terminal emulator with GUI) → cask
- ✅ git (CLI tool) → formula
- ✅ docker (system service) → formula
- ✅ vscode (GUI editor) → cask

## Warnings

- **SIP (System Integrity Protection)**: Cannot modify system files in `/System/`
- **File permissions**: macOS has strict permissions for certain directories
- **Code signing**: Some applications require code signing or notarization

## Sources

- [Apple Developer Documentation](https://developer.apple.com/documentation/) — system frameworks and APIs
- [Homebrew Documentation](https://docs.brew.sh/) — package manager
- [macOS User Guide](https://support.apple.com/guide/mac-help) — Apple's official user documentation

_Last synced: 2026-11-03_
