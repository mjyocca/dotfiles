---
name: package-management
description: Choose and manage package ownership across Homebrew, pacman, mise, and interim asdf
triggers:
  - adding new packages
  - installing software
  - package conflicts
  - updating package lists
  - setting up development environment
---

# Package Management Workflows

## Decide Ownership Before Installing

Load `docs/instructions/package-management.md` first. Classify the *tool*, not just its CLI/GUI label:

1. Mission-critical, session-critical, or OS-integrated (services, libraries, shell startup, prompt, session manager) → mise bootstrap (system packages).
2. Needs version switching or follows a fast-moving cloud API → mise, unless it must work independently of mise per rule 1.
3. Language runtimes remain on asdf **for now**; Go and other runtimes, as well as tools such as Terraform, are planned for mise in a separate migration.
4. Otherwise keep existing ownership. An optional cross-platform CLI/TUI may go to mise if its backend works on both platforms and it is not a session/OS dependency. If mise is unsuitable, use the platform manager and document why.

**Tie-breakers for a tool that could reasonably use either manager:**

1. Check how *this repo* owns the tool or similar tools: `.config/mise/config.<platform>.toml` (system packages), `manifests/pacman/packages.txt` (and GUI/AUR lists), and `packages/mise/.config/mise/config.toml` (dev tools). Prefer consistency with an existing comparable tool when the primary criteria do not decide; do not copy an old choice that contradicts them.
2. If still unclear, inspect how the installed Omarchy version provides it when available (`/usr/share/omarchy/install/omarchy-base.packages`, `/etc/mise/conf.d/*.toml`, and `mise config ls`). Default filenames vary by version. Otherwise consult the upstream sources at the bottom of this skill.

These lookups break ties; they do not replace our ownership rules. For a still-ambiguous tool, prefer platform ownership if it is in the upstream pacman base list, or mise if it is in upstream mise defaults. If it appears in both, apply the primary criteria and check how the system uses it; do not create a duplicate by default. Absence from either list does not mean the tool is unavailable in pacman or mise. Check actual package availability and the *effective* mise configuration (system defaults may apply) before adding a second installation. Do not uninstall OS-required packages merely to resolve an overlap.

## Adding a System Package

### Omarchy
```bash
# 1. Install the package
omarchy pkg add <package>
# or: sudo pacman -S --needed <package>

# 2. Check for untracked packages (preinstalled packages may be filtered out)
./scripts/omarchy/find-untracked-packages.sh

# 3. Track direct dependencies even if already installed by the OS
# - manifests/pacman/packages.txt (repository system/CLI)
# - manifests/pacman/packages-gui.txt (repository GUI apps)
# - manifests/pacman/packages-aur.txt (all AUR packages, including GUI)
# These manifests are repository-only; do not stow them.
# Install system packages via mise bootstrap:
make packages
# Hardware-specific dependencies belong in manifests/pacman/machines/<name>/.
# Use the same selection when auditing installed packages:
./scripts/omarchy/find-untracked-packages.sh --machine amd-strix-halo

# 4. Commit the change
git add manifests/pacman/packages.txt
git commit -m "add <package> to system packages"
```

### macOS
```bash
# 1. Install via Homebrew
brew install <package>

# 2. Add to mise bootstrap config
# Edit .config/mise/config.macos.toml and add:
# "brew:<package>" = "latest"
# or for casks:
# "brew-cask:<package>" = "latest"

# 3. Commit
git add .config/mise/config.macos.toml
git commit -m "add <package> to Homebrew"

# 4. Install the package
make packages
```

## Adding a mise-Owned Tool

```bash
# 1. Confirm the tool meets the ownership criteria and its backend supports both OSes
#    (mise registry <tool> can help)

# 2. Add to mise
mise use -g <tool>@latest

# 3. Verify that packages/mise/.config/mise/config.toml was updated

# 4. Install just this tool; a blanket mise install may also read ~/.tool-versions
#    and install duplicate asdf runtimes until the runtime migration is done
mise install <tool>

# 5. Check that it resolves correctly in a fresh shell, then commit
git add packages/mise/.config/mise/config.toml
git commit -m "add <tool> to mise-managed tools"
```

**Note:** Not every dev CLI belongs in mise. The shared config applies on both platforms; system mise defaults can also apply on Omarchy.

## Changing a Tool's Owner

Check both package lists and effective mise configuration. Install and verify the new owner first; then remove the old *user-managed* installation/declaration and rebuild mise shims if needed. Confirm `command -v <tool>` in a fresh shell. Leave uncommitted config changes and OS-required packages alone.

## Adding a Language Runtime (Interim)

```bash
# 1. Install via asdf
asdf install <lang> <version>
# e.g., asdf install nodejs 20.10.0

# 2. Set global version
asdf set -u <lang> <version> # asdf 0.16+; older versions used asdf global

# 3. This updates packages/tool-versions/.tool-versions

# 4. Commit
git add packages/tool-versions/.tool-versions
git commit -m "add <lang> <version> to asdf"
```

**Note:** Language runtimes are cross-platform via asdf until the separately planned migration to mise.

## Package Installation Order

When setting up a new machine, use the domain layer architecture:

```bash
# Full bootstrap (runs all layers in order)
make bootstrap

# Or run individual layers:
make prerequisites  # Install base tools (git, curl, make, etc.)
make packages       # Install system packages via mise bootstrap
make tools          # Install dev tools via mise
make plugins        # Install zellij, tmux plugins
make config         # Apply system/app configuration
make hooks          # Install git hooks
make link           # Deploy dotfiles via mise
```

On Omarchy, `make packages` also installs AUR packages after system packages.

Language runtimes are managed via asdf (interim):
```bash
asdf install
```

`make bootstrap` runs layers in order: prerequisites → packages (including AUR on Omarchy) → tools → plugins → config → hooks. It does not deploy configs: run `make link` afterward, then `asdf install` as needed. See `docs/instructions/omarchy.md` for list syntax, providers, preview commands, and discovery limitations.

## Omarchy Sources (Secondary Tie-Breaker Only)

Check the installed version first when available. For upstream, verify the relevant branch/version; these links point to `quattro`:

- [Pacman base list](https://github.com/omacom/omarchy/blob/quattro/install/omarchy-base.packages)
- [mise defaults](https://github.com/omacom/omarchy/blob/quattro/etc/mise/conf.d/omarchy-tools.toml)
- [Repository](https://github.com/omacom/omarchy)
