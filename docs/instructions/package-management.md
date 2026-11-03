# Package Management Instructions

Cross-platform package management conventions for this dotfiles repo. Platform-specific details are in `@docs/instructions/omarchy.md` and `@docs/instructions/macos.md`.

## Current Layers

| Manager | Role | Config |
|---------|------|--------|
| mise bootstrap | System packages (Homebrew on macOS, pacman on Linux) | `.config/mise/config.<platform>.toml` |
| mise | Version-switched, fast-moving cloud API, and eligible optional tools | `packages/mise/.config/mise/config.toml` |
| asdf (interim) | Language runtimes | `packages/tool-versions/.tool-versions` |

**Planned separately:** move language runtimes from asdf to mise, then retire asdf. Do not change runtime ownership as part of other package migrations. Until then, asdf owns runtime versions; avoid installing duplicate runtimes through mise.

## Choosing an Owner

1. **System packages?** Use mise bootstrap with `brew:` (macOS) or platform package manager (Linux). Examples: git, Docker, starship, fzf, direnv, zoxide, tmux, zellij.
2. **Version-switched or coupled to a fast-moving cloud API?** Use mise dev tools, unless the tool must be available independently of mise per rule 1. Examples: kubectl, gh, hunk, opencode. Language runtimes (such as Go) and tools such as Terraform will move to mise in a separate migration; runtimes remain in asdf for now.
3. **Neither rule settles ownership?** Keep the existing owner unless there is a reason to change it. For an optional CLI/TUI, use mise if its backend supports both platforms and it has no session/OS dependency (e.g., gitleaks, lazydocker, yq, glow, lsd, dua, superfile, television, yazi). Otherwise use the platform package manager and document the exception. If both options still fit, first compare similar tools in our mise config, pacman lists, and Homebrew packages; then, if still ambiguous, use the package-management skill's upstream lookup. Neither tie-breaker overrides the primary criteria.

Explicitly track direct dependencies in the appropriate `manifests/pacman/packages*.txt` list even if the OS already installed them; `--needed` skips up-to-date targets. These provisioning manifests are read directly from the repository and are not deployed to `$HOME`. Repository system/CLI and GUI packages use their respective lists; all AUR packages use `packages-aur.txt`. See the Omarchy instructions for the installer and list format. Do not put the same tool in both our shared mise config and a platform package list. Check system-provided mise defaults and packages before changing ownership; do not uninstall packages the OS itself requires to eliminate a duplicate.

Hardware-specific direct dependencies belong in `manifests/pacman/machines/<name>/`, using the same list filenames. Explicitly select the overlay with `--machine <name>` in both the Omarchy installer and discovery helper; shared lists remain the default and are always included.

## mise Tools

The shared config is deployed to `~/.config/mise/config.toml`. System mise defaults may also apply; only add tools to the shared config when they meet the criteria above.

Tools are installed via the tools layer:

```bash
make tools  # Install all dev tools via mise
mise list
mise current
```

Check `mise registry <tool>` and supported platforms before adding a tool. A blanket `mise install` may also read `~/.tool-versions` and install duplicate asdf runtimes until the separate migration is complete.

To add a new dev tool, edit the appropriate config file:
- Shared tools: `packages/mise/.config/mise/config.toml`
- macOS-only: `.config/mise/config.macos.toml`
- Omarchy-only: `.config/mise/config.omarchy.toml`

Then run `make tools` to install.

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
