---
title: "macOS Instructions"
description: "Index of macOS-specific conventions and configuration for dotfiles management"
sources:
  - name: "Apple Developer Documentation"
    url: "https://developer.apple.com/documentation/"
    type: "official"
    last_synced: "2026-01-23"
    notes: "System frameworks and APIs"
  - name: "Homebrew Documentation"
    url: "https://docs.brew.sh/"
    type: "official"
    last_synced: "2026-01-23"
    notes: "Package manager documentation"
  - name: "macOS User Guide"
    url: "https://support.apple.com/guide/mac-help"
    type: "official"
    last_synced: "2026-01-23"
    notes: "Apple's official user documentation"
last_updated: "2026-01-23"
maintainer: "mjyocca"
status: "active"
---

# macOS Instructions

This file provides an index of macOS-specific conventions and points to authoritative sources. Keep content lean — link out, don't duplicate.

## Key Concepts

- **Package management**: Homebrew for system packages, mise for dev tools
- **Shell**: Zsh is default shell on macOS
- **Dotfiles management**: GNU Stow for symlink management
- **System defaults**: Use `defaults write` for macOS system preferences

## Package Management

### Homebrew
```bash
brew install <package>     # Install package
brew install --cask <app>  # Install GUI app
brew update && brew upgrade  # Update all packages
```

**Brewfile**: `packages/homebrew/Brewfile`
- List of packages and casks to install
- Use `brew bundle` to install from Brewfile

### Colima (Docker)
```bash
colima start              # Start Docker daemon
colima stop               # Stop Docker daemon
colima status             # Check status
```

## Package Management

Homebrew is for **system packages only** (infrastructure, build deps, GUI apps).

Dev tools are managed via mise (cross-platform), not Homebrew.

### Common Commands

**System packages (Homebrew):**
```bash
# Install from Brewfile
brew bundle --file=packages/homebrew/Brewfile

# Update all packages
brew update && brew upgrade

# List installed packages
brew list

# Install a single package
brew install <package>

# Install a GUI app (cask)
brew install --cask <app>
```

**Dev tools (mise):**
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
```

**Language runtimes (asdf):**
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

### What Goes Where

- **System infrastructure** (git, curl, gcc) → Homebrew
- **GUI applications** (vscode, alacritty) → Homebrew cask
- **Dev CLI tools** (gitleaks, lazygit, jq) → mise
- **Language runtimes** (node, ruby, go) → asdf

**Future:** macOS-specific scripts will be added to `scripts/macos/` as needed.

### What NOT to Track

**❌ Do NOT add to Brewfile:**

1. **Packages managed by mise**
   - Dev tools like gitleaks, lazygit, jq, ripgrep, etc.
   - These belong in `packages/mise/.config/mise/config.toml`

2. **Language runtimes in system packages**
   - Don't install node, ruby, go via Homebrew
   - Use asdf instead for version management

**✅ DO track:**
1. **System infrastructure** you depend on (git, curl, stow, build tools)
2. **System services** you use (docker, colima)
3. **GUI applications** you launch from app menu
4. **Dev tools** in mise (cross-platform CLI/TUI tools)
5. **Language runtimes** in asdf (version-managed)

### Troubleshooting

#### Package already in mise but also in Brewfile

**Problem:** You see gitleaks in both Brewfile and mise config.

**Solution:**
```bash
# Remove from Brewfile
# Edit packages/homebrew/Brewfile and remove the line

# Keep in mise config.toml
# It should only be in packages/mise/.config/mise/config.toml

# Commit the fix
git add packages/homebrew/Brewfile
git commit -m "remove gitleaks from Homebrew (managed by mise)"
```

#### GUI app vs system package?

**Rule of thumb:**
- If it has a GUI and you launch it from `/Applications/` → Homebrew cask
- If it's a CLI tool or system service → Homebrew formula

**Examples:**
- ✅ alacritty (terminal emulator with GUI) → cask
- ✅ git (CLI tool) → formula
- ✅ docker (system service) → formula
- ✅ vscode (GUI editor) → cask

#### Language runtime in Homebrew?

**Problem:** You installed node via Homebrew and it's in Brewfile.

**Solution:**
```bash
# 1. Remove from Brewfile
# Edit packages/homebrew/Brewfile and remove 'nodejs' or 'node'

# 2. Uninstall the Homebrew version
brew uninstall node

# 3. Install via asdf instead
asdf install nodejs 20.10.0
asdf global nodejs 20.10.0

# 4. This updates packages/tool-versions/.tool-versions

# 5. Commit
git add packages/homebrew/Brewfile packages/tool-versions/.tool-versions
git commit -m "migrate nodejs from Homebrew to asdf"
```

#### Mise tool not installing

**Problem:** `mise install` fails for a tool.

**Solutions:**
1. Check if the tool name is correct in the mise registry
2. Verify your internet connection
3. Try updating mise: `mise self-update`
4. Check mise logs for specific error messages

#### Asdf plugin not found

**Problem:** `asdf install <lang>` says plugin not found.

**Solution:**
```bash
# Add the plugin first
asdf plugin add <lang>
# e.g., asdf plugin add nodejs

# Then install
asdf install <lang> <version>
```

## System Configuration

### Defaults
System preferences are managed via `defaults write` commands in `packages/macos/` scripts.

### Common Paths
- **User config**: `~/.config/` (XDG standard)
- **Applications**: `/Applications/`
- **Homebrew prefix**: `/opt/homebrew/` (Apple Silicon) or `/usr/local/` (Intel)

## Common Tasks

**Install dotfiles:**
```bash
make install  # Runs stow to create symlinks
```

**Update system defaults:**
```bash
make defaults  # Apply macOS system preferences
```

**Install all packages:**
```bash
brew bundle --file=packages/homebrew/Brewfile
```

## Warnings

- **SIP (System Integrity Protection)**: Cannot modify system files in `/System/`
- **File permissions**: macOS has strict permissions for certain directories
- **Code signing**: Some applications require code signing or notarization

## Additional Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/) — system APIs and frameworks
- [Homebrew Documentation](https://docs.brew.sh/) — package manager
- [macOS User Guide](https://support.apple.com/guide/mac-help) — user documentation
