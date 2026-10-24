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

- **Package management**: Homebrew for CLI tools, casks for GUI apps
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
