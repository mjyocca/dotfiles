# Package Management Instructions

Cross-platform package management conventions for this dotfiles repo.
Platform-specific system package details are in `@docs/instructions/omarchy.md` and `@docs/instructions/macos.md`.

---

## Three-Layer Architecture

| Layer | Manager | Scope | Config File |
|-------|---------|-------|-------------|
| System Packages | Homebrew / pacman | OS-specific | `Brewfile`, `packages.txt` |
| Dev Tools | mise | Cross-platform | `config.toml` |
| Language Runtimes | asdf | Cross-platform | `.tool-versions` |

### Decision Matrix

| Category | Manager | Example |
|----------|---------|---------|
| System infrastructure | Homebrew/pacman | git, curl, gcc |
| GUI applications | Homebrew/pacman | vscode, alacritty |
| Dev CLI tools | mise | gitleaks, lazygit, jq |
| Language runtimes | asdf | node, ruby, go |

---

## Dev Tools (mise)

Dev tools are managed via mise — cross-platform, available on both macOS and Omarchy.

**Config location:** `packages/mise/.config/mise/config.toml` (stowed to `~/.config/mise/config.toml`)

**Auto-updates (Omarchy):** The `post-update` hook runs `mise up` to keep tools current:
```bash
~/.config/omarchy/hooks/post-update.d/99-mise-update
```

### Commands

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

# Force update now
MISE_MINIMUM_RELEASE_AGE=0 mise up --yes
```

---

## Language Runtimes (asdf)

Language runtimes are managed via asdf — cross-platform, version-managed.

**Config location:** `packages/tool-versions/.tool-versions` (stowed to `~/.tool-versions`)

### Commands

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

---

## Cross-Platform Rules

### What NOT to put in system packages (Brewfile / packages.txt)

- **Dev tools managed by mise** — gitleaks, lazygit, jq, ripgrep, etc. belong in `config.toml`
- **Language runtimes** — node, ruby, go belong in asdf, not system packages

### What belongs in system packages

- System infrastructure (git, curl, stow, build tools)
- System services (docker)
- GUI applications launched from app menu

### GUI app vs CLI tool?

- Has a GUI and launches from app menu → system package (GUI list)
- CLI tool or system service → system package (infrastructure list)

---

## Troubleshooting

### Package in both system packages and mise

**Problem:** A tool like gitleaks appears in both Brewfile/packages.txt and mise config.

**Fix:** Remove from the system package file. It belongs in `packages/mise/.config/mise/config.toml` only.

### mise tool not installing

1. Check the tool name is correct in the mise registry
2. Try updating mise: `mise self-update`
3. Check mise logs for specific error messages

### asdf plugin not found

```bash
asdf plugin add <lang>   # e.g., asdf plugin add nodejs
asdf install <lang> <version>
```

---

## Sources

- [mise documentation](https://mise.jdx.dev/) — dev tool manager
- [asdf documentation](https://asdf-vm.com/) — language runtime manager

_Last synced: 2026-01-23_
