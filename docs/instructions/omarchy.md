# Omarchy Instructions

This file captures Omarchy-specific conventions, override paths, package management, and troubleshooting. Keep content lean — link out, don't duplicate.

## Key Concepts

- **Override model**: User configs in `~/.config/`, system defaults in `/usr/share/omarchy/` (read-only)
- **Dotfiles management**: mise is used for dotfile management
- **Shell**: Bash-first at desktop level (zsh included but interactive tools assume bash)
- **Config refresh**: After `omarchy update` or `omarchy reinstall configs`, re-run `make link`
- **Package tracking**: Track direct dependencies in all three `manifests/pacman/packages*.txt` lists, including packages already installed by the OS
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
make link  # Re-establish symlinks
```

**Plugin development:**
See [Plugin Development Guide](https://plugins.omarchy.org/develop.html)

## Package Management

### System Packages (pacman/AUR)

System packages are tracked in three repository-only provisioning manifests (not deployed to $HOME):

- **`manifests/pacman/packages.txt`** — Repository system/CLI packages
- **`manifests/pacman/packages-gui.txt`** — Repository GUI applications
- **`manifests/pacman/packages-aur.txt`** — All AUR packages, including GUI apps

"Repository" includes the configured Omarchy repository, not only Arch's official repositories. Use actual package names, not executable names: `git-delta` provides `delta`, and AUR `asdf-vm` provides `asdf`. Preserve Omarchy's `mise-bin` provider rather than replacing it with Arch's conflicting `mise`. Prefer explicit providers such as `qemu-base` over ambiguous virtual targets.

List format: one package name per line; blank lines, indentation, and full-line or inline `#` comments are accepted. No options, version expressions, or multiple packages on a line. Keep hardware-specific choices out of shared lists.

#### Machine Overlays

Track hardware-specific direct dependencies under `manifests/pacman/machines/<name>/`, using the same `packages.txt`, `packages-gui.txt`, and `packages-aur.txt` filenames. Overlay files are optional; shared files remain required. Select exactly one overlay explicitly with `--machine <name>`; no hostname or hardware detection is performed. Names use letters, digits, underscores, or hyphens and must start with a letter or digit. Unknown machine names are errors.

The selected overlay adds to the shared lists, with the same validation, routing, and deduplication. A list selector such as `aur` applies to both shared and machine AUR files. Neither deleting entries nor selecting a different machine uninstalls anything. Bootstrap still installs shared lists only; apply the desired overlay separately.

`amd-strix-halo/packages-aur.txt` tracks the existing `llama-cpp-rocm-git` dependency. Its AUR entry remains orphaned/out-of-date; this preserves tracking, not a claim that fresh builds work. Review it before reinstalling; replacing the installed package is a separate decision.

#### Commands

```bash
# Install all system packages (pacman + AUR) via mise bootstrap
make packages

# Or run specific layers
make prerequisites  # Install base tools (git, curl, make, etc.)
make packages       # Install system packages via mise bootstrap
make tools          # Install dev tools via mise

# Install pacman packages directly (for advanced use)
# The install-packages.sh script has been replaced by layer scripts
# See scripts/linux/packages.sh and scripts/omarchy/packages.sh

# Find untracked packages
./scripts/omarchy/find-untracked-packages.sh
# Include Omarchy base names when auditing preinstalled direct dependencies
./scripts/omarchy/find-untracked-packages.sh --include-base
# Count this machine's overlay entries as tracked, too
./scripts/omarchy/find-untracked-packages.sh --machine amd-strix-halo

# Inspect installed packages without overwriting curated lists
pacman -Qqen
pacman -Qqem
```

The package installation is now handled through the domain layer architecture. `make packages` on Omarchy runs the packages layer which installs pacman packages from the manifests, then handles AUR packages via yay. System and GUI targets go to `sudo pacman -S --needed`; AUR targets go to `yay -S --needed --aur` as your normal user. AUR builds remain interactive so you can review build instructions; installed packages are never pruned.

`--needed` skips up-to-date targets, not all installed targets. New versions can still be installed; repeatable installation is not version pinning. Run a full system update before installing against refreshed databases—never use `pacman -Sy` alone. `make bootstrap` runs prerequisites, packages (including AUR), tools, plugins, config, and hooks layers in order. It does not deploy configs; run `make link` afterward.

Dev tools are installed via `make tools` which runs the tools layer script. This uses mise to install version-pinned tools from the configuration. See [package management instructions](./package-management.md) for details on adding tools and managing versions.

**Workflow:**
1. Install with `omarchy pkg add <package>` or `sudo pacman -S --needed <package>`
2. Run `./scripts/omarchy/find-untracked-packages.sh` to discover missing packages (preinstalled packages may be filtered out)
3. Add direct dependencies to the appropriate file (repository system/CLI, repository GUI, or AUR), even if already installed
4. Track hardware-specific direct dependencies in the appropriate machine overlay, not the shared lists

Discovery reports explicit native and foreign packages separately. Foreign packages may be AUR or manually installed. Pass the same `--machine` used for installation to count overlay entries as tracked. Omarchy base names are excluded by default; `--include-base` disables that filter. mise tools are never filtered out, because overlaps need review. Compare with `mise ls --current` and `mise config ls` (including `/etc/mise/conf.d/*.toml`); package and tool names can differ. This is an audit aid, not a complete dependency or ownership detector. Check hardware support and package maintenance before installing machine-specific ROCm/LLM packages.

#### What NOT to Track

**❌ Do NOT add to packages.txt:**

1. **Hardware-specific drivers**
   - amd-ucode, vulkan-radeon, rocm-smi-lib, xpadneo-dkms
    - Track direct dependencies in a machine overlay, not shared lists

2. **Packages managed by mise**
   - Optional/version-sensitive tools like gitleaks, kubectl, gh, hunk, opencode
   - These belong in `packages/mise/.config/mise/config.toml`

3. **Language runtimes in system packages (interim)**
   - Use asdf for your selected node, ruby, and go versions
   - OS/AUR build dependencies may legitimately install system runtimes; don't remove those to force a single installation

**✅ DO track:**
1. **System infrastructure** you depend on (git, curl, stow, build tools)
2. **System services** you use (docker)
3. **GUI applications** you launch from app menu
4. **Platform-managed CLI/TUI tools** you depend on, including preinstalled tools (bat, jq, lazygit, ripgrep, starship, tmux)
5. **Optional/version-sensitive tools** in mise and **language runtimes** in asdf (until the separate runtime migration)

## Dev Tools & Language Runtimes

Dev tools are installed via `make tools`, which runs the tools layer script. This uses mise to install version-pinned tools from the configuration.

Language runtimes are currently managed through asdf (interim solution). After the separate migration is complete, they will move to mise.

```bash
# Install dev tools via mise
make tools

# Language runtimes (interim: asdf)
asdf install
asdf install <lang> <version>
asdf set -u <lang> <version>
```

See [package management instructions](./package-management.md) for details on adding tools, managing versions, and the ownership criteria.

## Troubleshooting

### GUI app vs system package?

**Rule of thumb:**
- If it comes from AUR → `packages-aur.txt`, whether CLI or GUI
- Otherwise, if it has a GUI and you launch it from the app menu → `packages-gui.txt`
- If it's a system service or platform-managed CLI tool → `packages.txt`; classify other CLIs with the [ownership criteria](./package-management.md)

**Examples:**
- ✅ alacritty (terminal emulator with GUI) → packages-gui.txt
- ✅ git (CLI tool) → packages.txt
- ✅ docker (system service) → packages.txt
- ✅ heroic-games-launcher (AUR GUI app) → packages-aur.txt

## Warnings

- **Collision risk**: Deploying packages replaces Omarchy-seeded configs in `~/.config/`
- **Stale configs**: After Omarchy updates, check for `.bak` files and re-run `make link`
- **Read-only source**: Never edit `/usr/share/omarchy/` directly

## Sources

- [Omarchy Manual](https://omarchy.org/manual/) — primary user documentation
- [Omarchy Plugins](https://plugins.omarchy.org/) — plugin registry and discovery
- [Omarchy Plugin Development](https://plugins.omarchy.org/develop.html) — create custom plugins
- [Omarchy Source Code](/usr/share/omarchy) — read-only system package (local)

_Last synced: 2026-11-03_
