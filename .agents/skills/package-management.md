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

1. Mission-critical, session-critical, or OS-integrated (services, libraries, shell startup, prompt, session manager) → Homebrew/pacman.
2. Needs version switching or follows a fast-moving cloud API → mise, unless it must work independently of mise per rule 1.
3. Language runtimes remain on asdf **for now**; Go and other runtimes, as well as tools such as Terraform, are planned for mise in a separate migration.
4. Otherwise keep existing ownership. An optional cross-platform CLI/TUI may go to mise if its backend works on both platforms and it is not a session/OS dependency. If mise is unsuitable, use the platform manager and document why.

**Tie-breakers for a tool that could reasonably use either manager:**

1. Check how *this repo* owns the tool or similar tools: `packages/homebrew/Brewfile`, `packages/pacman/packages.txt` (and GUI/AUR lists), and `packages/mise/.config/mise/config.toml`. Prefer consistency with an existing comparable tool when the primary criteria do not decide; do not copy an old choice that contradicts them.
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
# - packages/pacman/packages.txt (repository system/CLI)
# - packages/pacman/packages-gui.txt (repository GUI apps)
# - packages/pacman/packages-aur.txt (all AUR packages, including GUI)
# Apply one list (system, gui, or aur), or omit the argument for all three.
# Preview with --dry-run; the installer validates names and strips comments.
# --needed skips up-to-date packages; it is not version pinning.
bash ./scripts/omarchy/install-packages.sh system
# Hardware-specific dependencies belong in packages/pacman/machines/<name>/.
# Explicit selection adds that overlay to shared lists; absent files are OK.
bash ./scripts/omarchy/install-packages.sh --machine amd-strix-halo --dry-run
# Use the same selection when auditing installed packages:
./scripts/omarchy/find-untracked-packages.sh --machine amd-strix-halo

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

When setting up a new machine, install in this order:

1. **System packages** (via Homebrew/pacman)
   ```bash
   # macOS: brew bundle --file=packages/homebrew/Brewfile
   # Omarchy: bash ./scripts/omarchy/install-packages.sh
   ```

2. **Git hooks**
   ```bash
   make install_git_hooks
   ```

3. **Stow configuration** (including the mise config for this OS)
   ```bash
   make dotfiles
   ```

4. **Eligible mise tools** (install only what is needed; avoid duplicate runtimes)
   ```bash
   make mise_install # macOS/Omarchy: only tools declared in the shared repo config
   # Or install an individual configured tool:
   mise install <tool>
   ```

5. **Language runtimes** (via asdf, interim)
   ```bash
   asdf install
   ```

`make mise_install` uses `scripts/install-mise-tools.sh` on both macOS and Omarchy. Preview with `bash scripts/install-mise-tools.sh --dry-run`. It installs only explicit tool/version requests from the repository's shared mise config using `mise --no-config install`, avoiding existing effective config and asdf runtimes.

`make bootstrap` on Omarchy runs `pacman -Syu`, the list installer, mise availability check, repository-only mise installation, git hooks, and Zellij plugins sequentially, even with `make -j`. System/GUI lists go to pacman; AUR goes to yay as a normal user. It does not stow or install runtimes: run `make dotfiles`, then `asdf install` as needed. See `docs/instructions/omarchy.md` for list syntax, providers, preview commands, and discovery limitations.

## Omarchy Sources (Secondary Tie-Breaker Only)

Check the installed version first when available. For upstream, verify the relevant branch/version; these links point to `quattro`:

- [Pacman base list](https://github.com/omacom/omarchy/blob/quattro/install/omarchy-base.packages)
- [mise defaults](https://github.com/omacom/omarchy/blob/quattro/etc/mise/conf.d/omarchy-tools.toml)
- [Repository](https://github.com/omacom/omarchy)
