# Omarchy Instructions

This file captures Omarchy-specific conventions, override paths, package management, and troubleshooting. Keep content lean — link out, don't duplicate.

## Key Concepts

- **Override model**: User configs in `~/.config/`, system defaults in `/usr/share/omarchy/` (read-only)
- **Dotfiles management**: Stow is endorsed by Omarchy for backup/management
- **Shell**: Bash-first at desktop level (zsh included but interactive tools assume bash)
- **Config refresh**: After `omarchy update` or `omarchy reinstall configs`, re-run `make dotfiles`
- **Package tracking**: Explicitly track your direct dependencies in `packages/pacman/packages.txt` and `packages-aur.txt`, including Omarchy defaults
- **Security**: Gitleaks pre-commit hook scans for secrets

## System Configuration

### Override Paths

#### Hyprland (Window Manager)
```
~/.config/hypr/
├── hyprland.conf    # Main config
├── monitors.conf    # Display configuration
├── bindings.conf    # Keybindings
└── autostart.conf   # Startup applications
```

#### Omarchy Shell
```
~/.config/omarchy/
├── shell.json       # Shell configuration
├── hooks/           # Custom hooks
├── themes/          # Custom themes
└── plugins/         # Custom plugins
```

#### Other Configs
- **Terminal**: `~/.config/ghostty/config`
- **Prompt**: `~/.config/starship.toml`
- **Neovim**: `~/.config/nvim/`
- **Git**: `~/.config/git/config`

### Common Tasks

**Update dotfiles after Omarchy update:**
```bash
omarchy update
make dotfiles  # Re-establish symlinks
```

**Plugin development:**
See [Plugin Development Guide](https://plugins.omarchy.org/develop.html)

## Package Management

### System Packages (pacman/AUR)

System packages are tracked in three curated files:

- **`packages/pacman/packages.txt`** — System packages (infrastructure, CLI tools)
- **`packages/pacman/packages-gui.txt`** — GUI applications
- **`packages/pacman/packages-aur.txt`** — AUR packages

#### Commands

```bash
# Install system packages
sudo pacman -S --needed - < packages/pacman/packages.txt

# Install GUI applications
sudo pacman -S --needed - < packages/pacman/packages-gui.txt

# Install AUR packages
yay -S --needed - < packages/pacman/packages-aur.txt

# Find untracked packages
./scripts/omarchy/find-untracked-packages.sh

# Export installed packages (then curate!)
pacman -Qqen > packages/pacman/packages.txt
pacman -Qqem > packages/pacman/packages-aur.txt
```

**Workflow:**
1. Install with `omarchy pkg add <package>` or `pacman -S <package>`
2. Run `./scripts/omarchy/find-untracked-packages.sh` to discover missing packages (Omarchy defaults may be filtered out)
3. Add direct dependencies to the appropriate file (packages.txt for system, packages-gui.txt for GUI), even if Omarchy already installed them
4. Hardware-specific packages (drivers, firmware) don't need tracking

#### What NOT to Track

**❌ Do NOT add to packages.txt:**

1. **Hardware-specific drivers**
   - amd-ucode, vulkan-radeon, rocm-smi-lib, xpadneo-dkms
   - These are machine-specific and shouldn't be in shared config

2. **Packages managed by mise**
   - Optional/version-sensitive tools like gitleaks, kubectl, gh, hunk, opencode
   - These belong in `packages/mise/.config/mise/config.toml`

3. **Language runtimes in system packages (interim)**
   - Don't install node, ruby, go via pacman
   - Use asdf instead for version management

**✅ DO track:**
1. **System infrastructure** you depend on (git, curl, stow, build tools)
2. **System services** you use (docker)
3. **GUI applications** you launch from app menu
4. **Platform-managed CLI/TUI tools** you depend on, including Omarchy defaults (bat, jq, lazygit, ripgrep, starship, tmux)
5. **Optional/version-sensitive tools** in mise and **language runtimes** in asdf (until the separate runtime migration)

## Dev Tools & Language Runtimes

See [package management instructions](./package-management.md) for mise and asdf conventions, commands, and troubleshooting.

## Troubleshooting

### GUI app vs system package?

**Rule of thumb:**
- If it has a GUI and you launch it from the app menu → `packages-gui.txt`
- If it's a CLI tool or system service → `packages.txt`

**Examples:**
- ✅ alacritty (terminal emulator with GUI) → packages-gui.txt
- ✅ git (CLI tool) → packages.txt
- ✅ docker (system service) → packages.txt
- ✅ vscode (GUI editor) → packages-gui.txt

## Warnings

- **Collision risk**: Stowing packages replaces Omarchy-seeded configs in `~/.config/`
- **Stale configs**: After Omarchy updates, check for `.bak` files and re-run `make dotfiles`
- **Read-only source**: Never edit `/usr/share/omarchy/` directly

## Sources

- [Omarchy Manual](https://omarchy.org/manual/) — primary user documentation
- [Omarchy Plugins](https://plugins.omarchy.org/) — plugin registry and discovery
- [Omarchy Plugin Development](https://plugins.omarchy.org/develop.html) — create custom plugins
- [Omarchy Source Code](/usr/share/omarchy) — read-only system package (local)

_Last synced: 2026-01-23_
