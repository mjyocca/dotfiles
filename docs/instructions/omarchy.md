---
title: "Omarchy Instructions"
description: "Omarchy-specific conventions and configuration for dotfiles management"
sources:
  - name: "Omarchy Manual"
    url: "https://omarchy.org/manual/"
    type: "official"
    last_synced: "2026-01-23"
    notes: "Primary user documentation"
  - name: "Omarchy Plugins"
    url: "https://plugins.omarchy.org/"
    type: "official"
    last_synced: "2026-01-23"
    notes: "Plugin registry and discovery"
  - name: "Omarchy Plugin Development"
    url: "https://plugins.omarchy.org/develop.html"
    type: "official"
    last_synced: "2026-01-23"
    notes: "Guide for developing and publishing plugins"
  - name: "GitHub Manual (legacy)"
    url: "https://github.com/basecamp/omarchy/tree/quattro/manual"
    type: "official"
    last_synced: "2026-01-23"
    notes: "Markdown source files, may be deprecated in favor of omarchy.org/manual"
  - name: "Omarchy Source Code"
    url: "/usr/share/omarchy"
    type: "local"
    last_synced: "2026-01-23"
    notes: "Read-only system package"
last_updated: "2026-01-23"
maintainer: "mjyocca"
status: "active"
---

# Omarchy Instructions

This file captures Omarchy-specific conventions, override paths, package management, and troubleshooting. Keep content lean — link out, don't duplicate.

## Key Concepts

- **Override model**: User configs in `~/.config/`, system defaults in `/usr/share/omarchy/` (read-only)
- **Dotfiles management**: Stow is endorsed by Omarchy for backup/management
- **Shell**: Bash-first at desktop level (zsh included but interactive tools assume bash)
- **Config refresh**: After `omarchy update` or `omarchy reinstall configs`, re-run `make dotfiles`
- **Package tracking**: Use `packages/pacman/packages.txt` and `packages-aur.txt`
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
2. Run `./scripts/omarchy/find-untracked-packages.sh` to see what's not tracked
3. Add to the appropriate file (packages.txt for system, packages-gui.txt for GUI)
4. Hardware-specific packages (drivers, firmware) don't need tracking

#### What NOT to Track

**❌ Do NOT add to packages.txt:**

1. **Hardware-specific drivers**
   - amd-ucode, vulkan-radeon, rocm-smi-lib, xpadneo-dkms
   - These are machine-specific and shouldn't be in shared config

2. **Omarchy defaults**
   - Packages already in `/usr/share/omarchy/install/omarchy-base.packages`
   - The find-untracked-packages.sh script filters these out

3. **Packages managed by mise**
   - Dev tools like gitleaks, lazygit, jq, ripgrep, etc.
   - These belong in `packages/mise/.config/mise/config.toml`

4. **Language runtimes in system packages**
   - Don't install node, ruby, go via pacman
   - Use asdf instead for version management

**✅ DO track:**
1. **System infrastructure** you depend on (git, curl, stow, build tools)
2. **System services** you use (docker)
3. **GUI applications** you launch from app menu
4. **Dev tools** in mise (cross-platform CLI/TUI tools)
5. **Language runtimes** in asdf (version-managed)

### Dev Tools (mise)

Dev tools are managed via mise (cross-platform), aligned with how Omarchy manages AI tools.

**Config location:** `packages/mise/.config/mise/config.toml` (stowed to `~/.config/mise/config.toml`)

**Auto-updates:** Omarchy's `post-update` hook runs `mise up` to keep tools current:
```bash
~/.config/omarchy/hooks/post-update.d/99-mise-update
```

#### Commands

```bash
# Install all dev tools
mise install

# Update all dev tools
mise update

# Add new tool
mise use -g <tool>@latest

# List installed tools
mise list

# Check tool versions
mise current

# Force update now
MISE_MINIMUM_RELEASE_AGE=0 mise up --yes
```

### Language Runtimes (asdf)

Language runtimes are managed via asdf (cross-platform).

**Config location:** `packages/tool-versions/.tool-versions` (stowed to `~/.tool-versions`)

#### Commands

```bash
# Install all language runtimes
asdf install

# Add new runtime
asdf install <lang> <version>

# Set global version
asdf global <lang> <version>

# List installed versions
asdf list <lang>

# Check current version
asdf current <lang>
```

## Troubleshooting

### Package already in mise but also in packages.txt

**Problem:** You see gitleaks in both packages.txt and mise config.

**Solution:**
```bash
# Remove from packages.txt
# Edit packages/pacman/packages.txt and remove the line

# Keep in mise config.toml
# It should only be in packages/mise/.config/mise/config.toml

# Commit the fix
git add packages/pacman/packages.txt
git commit -m "remove gitleaks from system packages (managed by mise)"
```

### GUI app vs system package?

**Rule of thumb:**
- If it has a GUI and you launch it from the app menu → `packages-gui.txt`
- If it's a CLI tool or system service → `packages.txt`

**Examples:**
- ✅ alacritty (terminal emulator with GUI) → packages-gui.txt
- ✅ git (CLI tool) → packages.txt
- ✅ docker (system service) → packages.txt
- ✅ vscode (GUI editor) → packages-gui.txt

### Language runtime in system packages?

**Problem:** You installed node via pacman and it's in packages.txt.

**Solution:**
```bash
# 1. Remove from packages.txt
# Edit packages/pacman/packages.txt and remove 'nodejs'

# 2. Install via asdf instead
asdf install nodejs 20.10.0
asdf global nodejs 20.10.0

# 3. This updates packages/tool-versions/.tool-versions

# 4. Commit
git add packages/pacman/packages.txt packages/tool-versions/.tool-versions
git commit -m "migrate nodejs from system package to asdf"
```

### Mise tool not installing

**Problem:** `mise install` fails for a tool.

**Solutions:**
1. Check if the tool name is correct in the mise registry
2. Verify your internet connection
3. Try updating mise: `mise self-update`
4. Check mise logs for specific error messages

### Asdf plugin not found

**Problem:** `asdf install <lang>` says plugin not found.

**Solution:**
```bash
# Add the plugin first
asdf plugin add <lang>
# e.g., asdf plugin add nodejs

# Then install
asdf install <lang> <version>
```

## Warnings

- **Collision risk**: Stowing packages replaces Omarchy-seeded configs in `~/.config/`
- **Stale configs**: After Omarchy updates, check for `.bak` files and re-run `make dotfiles`
- **Read-only source**: Never edit `/usr/share/omarchy/` directly

## Additional Resources

- [Omarchy Manual](https://omarchy.org/manual/) — primary documentation
- [Plugin Registry](https://plugins.omarchy.org/) — discover and install plugins
- [Plugin Development](https://plugins.omarchy.org/develop.html) — create custom plugins
