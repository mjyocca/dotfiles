---
name: package-management
description: Guide for managing system packages, dev tools, GUI applications, and language runtimes across macOS and Omarchy
triggers:
  - adding new packages
  - installing software
  - package conflicts
  - updating package lists
  - setting up development environment
---

# Package Management Skill

## When to Use

- Adding new system dependencies
- Installing development tools
- Managing GUI applications
- Troubleshooting package conflicts
- Setting up a new machine
- Updating package lists

## Architecture Overview

This dotfiles repo uses a **three-layer package management architecture**:

```
Layer 1: System Packages (OS-specific, infrastructure)
├── macOS: Homebrew (packages/homebrew/Brewfile)
└── Omarchy: pacman/AUR (packages/pacman/packages.txt, packages-gui.txt)

Layer 2: Dev Tools (cross-platform, version-managed)
└── mise: packages/mise/.config/mise/config.toml

Layer 3: Language Runtimes (cross-platform, version-managed)
└── asdf: packages/tool-versions/.tool-versions
```

## Decision Matrix

| Category | Manager | File | Examples |
|----------|---------|------|----------|
| System infrastructure | Homebrew/pacman | Brewfile, packages.txt | git, curl, gcc, cmake |
| System services | Homebrew/pacman | Brewfile, packages.txt | docker, colima |
| GUI applications | Homebrew/pacman | Brewfile, packages-gui.txt | vscode, alacritty, spotify |
| Dev CLI tools | mise | config.toml | gitleaks, lazygit, jq, ripgrep |
| TUI tools | mise | config.toml | btop, yazi, superfile |
| Shell utilities | mise | config.toml | starship, direnv, zoxide |
| Language runtimes | asdf | .tool-versions | node, ruby, go, rust, zig |

## Workflows

### Adding a System Package

**Omarchy:**
```bash
# 1. Install the package
omarchy pkg add <package>
# or: sudo pacman -S <package>

# 2. Check if it's tracked
./scripts/omarchy/find-untracked-packages.sh

# 3. If untracked, add to appropriate file
# - packages/pacman/packages.txt (system/CLI)
# - packages/pacman/packages-gui.txt (GUI apps)

# 4. Commit the change
git add packages/pacman/packages.txt
git commit -m "add <package> to system packages"
```

**macOS:**
```bash
# 1. Install via Homebrew
brew install <package>

# 2. Add to Brewfile
# Edit packages/homebrew/Brewfile and add: brew '<package>'

# 3. Commit
git add packages/homebrew/Brewfile
git commit -m "add <package> to Homebrew"
```

### Adding a Dev Tool (Cross-Platform)

```bash
# 1. Add to mise
mise use -g <tool>@latest

# 2. This updates packages/mise/.config/mise/config.toml

# 3. Install on current machine
mise install

# 4. Commit
git add packages/mise/.config/mise/config.toml
git commit -m "add <tool> to mise dev tools"
```

**Note:** Dev tools are cross-platform. Adding to mise makes it available on both macOS and Omarchy.

### Adding a Language Runtime

```bash
# 1. Install via asdf
asdf install <lang> <version>
# e.g., asdf install nodejs 20.10.0

# 2. Set global version
asdf global <lang> <version>

# 3. This updates packages/tool-versions/.tool-versions

# 4. Commit
git add packages/tool-versions/.tool-versions
git commit -m "add <lang> <version> to asdf"
```

**Note:** Language runtimes are cross-platform via asdf.

## Common Commands

### Omarchy/Arch

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

### macOS

```bash
# Install from Brewfile
brew bundle --file=packages/homebrew/Brewfile

# Update all packages
brew update && brew upgrade

# List installed packages
brew list
```

### Mise (Cross-Platform)

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

### Asdf (Cross-Platform)

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

## What NOT to Track

### ❌ Do NOT add to packages.txt or Brewfile:

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
   - Don't install node, ruby, go via pacman/brew
   - Use asdf instead for version management

### ✅ DO track:

1. **System infrastructure** you depend on (git, curl, stow, build tools)
2. **System services** you use (docker, colima)
3. **GUI applications** you launch from app menu
4. **Dev tools** in mise (cross-platform CLI/TUI tools)
5. **Language runtimes** in asdf (version-managed)

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

## Package Installation Order

When setting up a new machine, install in this order:

1. **System packages** (via Homebrew/pacman)
   ```bash
   make bootstrap  # Handles this automatically
   ```

2. **Git hooks**
   ```bash
   make install_git_hooks
   ```

3. **Dev tools** (via mise)
   ```bash
   mise install
   ```

4. **Language runtimes** (via asdf)
   ```bash
   asdf install
   ```

5. **Dotfiles** (via stow)
   ```bash
   make dotfiles
   ```

## Additional Resources

- [AGENTS.md](../../../AGENTS.md) - Main agent instructions
- [Omarchy instructions](../../docs/instructions/omarchy.md) - Omarchy-specific conventions
- [macOS instructions](../../docs/instructions/macos.md) - macOS-specific conventions
- [mise documentation](https://mise.jdx.dev/) - Dev tools management
- [asdf documentation](https://asdf-vm.com/) - Language runtime management
