# macOS Instructions

This file contains macOS-specific bootstrap, package management, and system configuration instructions.

## Bootstrap

macOS bootstrap is handled by `osx/installer.sh` and `osx/core-utils.sh`:

```bash
# Initial setup (installs Xcode CLI tools, Homebrew, clones dotfiles)
bash osx/installer.sh

# Subsequent provisioning
make bootstrap
```

## Package Management

**Homebrew** is the primary package manager on macOS.

- Brewfile: `packages/homebrew/Brewfile`
- Install packages: `make brew_bundle` or `brew bundle --file=~/Brewfile`
- Update packages: `brew update && brew upgrade`

## Colima (Docker/VM Management)

Colima is used for Docker and VM management on macOS:

- Config: `packages/colima/.config/colima/_templates/default.yaml`
- Switch profiles: `dotf colima-use <profile>`
- List profiles: `dotf colima-list`

## System Settings

macOS system settings are managed via `apply-user-defaults`:

- Defaults file: `osx/defaults.yml`
- App-specific defaults: `osx/defaults.apps.yml`
- Apply settings: `make apply_settings` or `make apply_defaults_osx`

## Key Differences from Linux

- Uses Homebrew instead of pacman/apt
- Colima for containerization (no native Docker Desktop required)
- System preferences via `defaults write` (automated via apply-user-defaults)
- `.zshrc.local` for per-machine overrides (git-ignored)
