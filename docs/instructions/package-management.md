# Package Management Instructions

Cross-platform package management conventions for this dotfiles repo. Platform-specific details are in `@docs/instructions/omarchy.md` and `@docs/instructions/macos.md`.

## Current Layers

| Manager | Role | Config |
|---------|------|--------|
| Homebrew / pacman | OS-integrated and session-critical packages | `packages/homebrew/Brewfile`, `packages/pacman/packages.txt` |
| mise | Version-sensitive, fast-moving/cloud-coupled, and optional tools not supplied by Omarchy | `packages/mise/.config/mise/config.toml` |
| asdf (interim) | Language runtimes | `packages/tool-versions/.tool-versions` |

**Planned separately:** move language runtimes from asdf to mise, then retire asdf. Do not change runtime ownership as part of other package migrations. Until then, asdf owns runtime versions; avoid installing duplicate runtimes through mise.

## Choosing an Owner

1. **OS integration or service?** Use Homebrew/pacman for GUI apps, libraries, build dependencies, Docker, and tools needed by the OS or desktop.
2. **Needed for a usable shell/session?** Use Homebrew/pacman for startup hooks, the prompt, session managers, and other session-critical commands. Examples: starship, fzf, direnv, zoxide, tmux, zellij.
3. **Shipped in Omarchy's base packages?** Use pacman on Omarchy and Homebrew on macOS for the same tool. Explicitly list the direct dependency in `packages/pacman/packages.txt` even if Omarchy already installs it: `pacman -S --needed` skips installed packages. Examples: bat, jq, lazygit, neovim, ripgrep, tree-sitter-cli, herdr. `herdr` comes from Omarchy's package repositories, not Arch's official `extra` repo.
4. **Version-switched or coupled to a fast-moving cloud API?** Use mise (unless a previous system/session requirement applies). Examples: kubectl, gh, hunk, opencode; later, language runtimes and Terraform.
5. **Optional tool not shipped by Omarchy?** Use mise for a cross-platform CLI/TUI if its backend works on both OSes. Examples: gitleaks, lazydocker, yq, glow, lsd, dua, superfile, television, yazi. If unavailable or unsuitable through mise, use the platform manager and document the exception.

Do not put the same tool in both the shared mise config and a platform package list. Omarchy's upstream mise defaults (`/etc/mise/conf.d/`) can declare tools independently; check the effective configuration on Omarchy when changing ownership. Do not remove an Omarchy-owned base package just because mise also supplies it.

## mise Tools

The shared config is stowed to `~/.config/mise/config.toml`. On Omarchy, system mise defaults may also apply. Omarchy's update hook runs `mise up`; only add tools to the shared config when they meet the criteria above.

```bash
mise install             # install configured tools; check runtime overlap while asdf remains
mise use -g <tool>@latest # add an eligible tool to global config
mise list
mise current
```

Check `mise registry <tool>` and supported platforms before adding a tool. Avoid using `mise install` as a blanket runtime installer until the asdf migration is complete; mise may read `~/.tool-versions` as well.

## Language Runtimes (Interim: asdf)

Language runtimes are currently version-managed through `packages/tool-versions/.tool-versions`.

```bash
asdf install
asdf install <lang> <version>
asdf global <lang> <version>
asdf current <lang>
```

## Resolving Duplicates

If a tool is in both mise and a system package list, classify it using the rules above. Install and verify the chosen provider before removing the other. On Omarchy, distinguish packages required by Omarchy itself from packages explicitly tracked in our list; do not uninstall Omarchy base packages to eliminate a duplicate. Verify with `command -v <tool>` in a fresh shell and check mise's effective configuration before pruning old installs.

## Sources

- [Omarchy base packages](https://github.com/omacom/omarchy/blob/quattro/install/omarchy-base.packages)
- [Omarchy mise defaults](https://github.com/omacom/omarchy/blob/quattro/etc/mise/conf.d/omarchy-tools.toml)
- [mise documentation](https://mise.jdx.dev/)
- [asdf documentation](https://asdf-vm.com/)
