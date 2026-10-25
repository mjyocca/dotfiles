---
name: package-management
description: Workflows for managing system packages, dev tools, GUI applications, and language runtimes across macOS and Omarchy
triggers:
  - adding new packages
  - installing software
  - package conflicts
  - updating package lists
  - setting up development environment
---

# Package Management Workflows

## Adding a System Package

### Omarchy
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

### macOS
```bash
# 1. Install via Homebrew
brew install <package>

# 2. Add to Brewfile
# Edit packages/homebrew/Brewfile and add: brew '<package>'

# 3. Commit
git add packages/homebrew/Brewfile
git commit -m "add <package> to Homebrew"
```

## Adding a Dev Tool (Cross-Platform)

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

## Adding a Language Runtime

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
