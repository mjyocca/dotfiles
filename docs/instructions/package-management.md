# Package Management Instructions

Cross-platform package management conventions for this dotfiles repo. Platform-specific details are in `@docs/instructions/omarchy.md` and `@docs/instructions/macos.md`.

## Current Layers

| Manager | Role | Config |
|---------|------|--------|
| Homebrew / pacman | Mission-critical, session-critical, and OS-integrated packages | `packages/homebrew/Brewfile`, `manifests/pacman/packages.txt` |
| mise | Version-switched, fast-moving cloud API, and eligible optional tools | `packages/mise/.config/mise/config.toml` |
| asdf (interim) | Language runtimes | `packages/tool-versions/.tool-versions` |

**Planned separately:** move language runtimes from asdf to mise, then retire asdf. Do not change runtime ownership as part of other package migrations. Until then, asdf owns runtime versions; avoid installing duplicate runtimes through mise.

## Choosing an Owner

1. **Mission-critical, session-critical, or OS-integrated?** Use Homebrew/pacman for services, GUI apps, libraries, build dependencies, and commands required for a usable shell or desktop. Examples: git, Docker, starship, fzf, direnv, zoxide, tmux, zellij.
2. **Version-switched or coupled to a fast-moving cloud API?** Use mise, unless the tool must be available independently of mise per rule 1. Examples: kubectl, gh, hunk, opencode. Language runtimes (such as Go) and tools such as Terraform will move to mise in a separate migration; runtimes remain in asdf for now.
3. **Neither rule settles ownership?** Keep the existing owner unless there is a reason to change it. For an optional CLI/TUI, use mise if its backend supports both platforms and it has no session/OS dependency (e.g., gitleaks, lazydocker, yq, glow, lsd, dua, superfile, television, yazi). Otherwise use the platform manager and document the exception. If both options still fit, first compare similar tools in our Brewfile, pacman lists, and mise config; then, if still ambiguous, use the package-management skill's upstream lookup. Neither tie-breaker overrides the primary criteria.

Explicitly track direct dependencies in the appropriate `manifests/pacman/packages*.txt` list even if the OS already installed them; `--needed` skips up-to-date targets. These provisioning manifests are read directly from the repository and are not stowed. Repository system/CLI and GUI packages use their respective lists; all AUR packages use `packages-aur.txt`. See the Omarchy instructions for the installer and list format. Do not put the same tool in both our shared mise config and a platform package list. Check system-provided mise defaults and packages before changing ownership; do not uninstall packages the OS itself requires to eliminate a duplicate.

Hardware-specific direct dependencies belong in `manifests/pacman/machines/<name>/`, using the same list filenames. Explicitly select the overlay with `--machine <name>` in both the Omarchy installer and discovery helper; shared lists remain the default and are always included.

## mise Tools

The shared config is stowed to `~/.config/mise/config.toml`. System mise defaults may also apply; only add tools to the shared config when they meet the criteria above.

```bash
mise install <tool>      # install an eligible tool without also installing asdf runtimes
mise use -g <tool>@latest # add an eligible tool to global config
mise list
mise current
```

Check `mise registry <tool>` and supported platforms before adding a tool. A blanket `mise install` may also read `~/.tool-versions` and install duplicate asdf runtimes until the separate migration is complete.

On macOS and Omarchy, `make mise_install` runs the shared Bash helper `scripts/install-mise-tools.sh`. It uses mise's TOML parser to read only `packages/mise/.config/mise/config.toml`, then installs explicit tool/version requests using `mise --no-config install`. It does not require stowing first, change existing user config, or install tools inherited from global/system/project config and `~/.tool-versions`. Run `make dotfiles` to activate the shared configuration afterward. Only simple string-version entries are supported; complex tool options are rejected rather than silently ignored.

Preview without installing (requires mise):
```bash
bash scripts/install-mise-tools.sh --dry-run
```

## Language Runtimes (Interim: asdf)

Language runtimes are currently version-managed through `packages/tool-versions/.tool-versions`.

```bash
asdf install
asdf install <lang> <version>
asdf set -u <lang> <version> # asdf 0.16+; older versions used asdf global
asdf current <lang>
```

## Resolving Duplicates

If a tool is in both mise and a system package list, classify it using the rules above. Install and verify the chosen provider before removing the other. Distinguish packages required by the OS itself from packages explicitly tracked in our list. Verify with `command -v <tool>` in a fresh shell and check mise's effective configuration before pruning old installs.

## Sources

- [mise documentation](https://mise.jdx.dev/)
- [asdf documentation](https://asdf-vm.com/)
