---
title: "Omarchy Instructions"
description: "Index of Omarchy-specific conventions and configuration for dotfiles management"
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

This file provides an index of Omarchy-specific conventions and points to authoritative sources. Keep content lean — link out, don't duplicate.

## Key Concepts

- **Override model**: User configs in `~/.config/`, system defaults in `/usr/share/omarchy/` (read-only)
- **Dotfiles management**: Stow is endorsed by Omarchy for backup/management
- **Shell**: Bash-first at desktop level (zsh included but interactive tools assume bash)
- **Config refresh**: After `omarchy update` or `omarchy reinstall configs`, re-run `make dotfiles`
- **Package tracking**: Use `packages/pacman/packages.txt` and `packages-aur.txt` (see [AGENTS.md](../../AGENTS.md#linux-package-management-omarchyarch))
- **Security**: Gitleaks pre-commit hook scans for secrets (see [AGENTS.md](../../AGENTS.md#security-gitleaks-integration))
- **Dev tools**: Managed via mise (cross-platform), see [AGENTS.md](../../AGENTS.md#dev-tools-mise)

## User Override Paths

### Hyprland (Window Manager)
```
~/.config/hypr/
├── hyprland.conf    # Main config
├── monitors.conf    # Display configuration
├── bindings.conf    # Keybindings
└── autostart.conf   # Startup applications
```

### Omarchy Shell
```
~/.config/omarchy/
├── shell.json       # Shell configuration
├── hooks/           # Custom hooks
├── themes/          # Custom themes
└── plugins/         # Custom plugins
```

### Other Configs
- **Terminal**: `~/.config/ghostty/config`
- **Prompt**: `~/.config/starship.toml`
- **Neovim**: `~/.config/nvim/`
- **Git**: `~/.config/git/config`

## Common Tasks

**Update dotfiles after Omarchy update:**
```bash
omarchy update
make dotfiles  # Re-establish symlinks
```

**Plugin development:**
See [Plugin Development Guide](https://plugins.omarchy.org/develop.html)

## Mise Integration

Dev tools are managed via mise (cross-platform), aligned with how Omarchy manages AI tools.

**Config location:** `packages/mise/.config/mise/config.toml` (stowed to `~/.config/mise/config.toml`)

**Auto-updates:** Omarchy's `post-update` hook runs `mise up` to keep tools current:
```bash
~/.config/omarchy/hooks/post-update.d/99-mise-update
```

**Manual commands:**
```bash
mise install          # Install all tools
mise update           # Update all tools
mise list             # List installed tools
MISE_MINIMUM_RELEASE_AGE=0 mise up --yes  # Force update now
```

**Add a new tool:**
```bash
mise use -g <tool>@latest
# Then commit the updated config.toml
```

## Warnings

- **Collision risk**: Stowing packages replaces Omarchy-seeded configs in `~/.config/`
- **Stale configs**: After Omarchy updates, check for `.bak` files and re-run `make dotfiles`
- **Read-only source**: Never edit `/usr/share/omarchy/` directly

## Additional Resources

- [Omarchy Manual](https://omarchy.org/manual/) — primary documentation
- [Plugin Registry](https://plugins.omarchy.org/) — discover and install plugins
- [Plugin Development](https://plugins.omarchy.org/develop.html) — create custom plugins
