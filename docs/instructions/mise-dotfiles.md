# Skill: mise-dotfiles

Configuration guidance for deploying dotfiles with mise's `[dotfile_groups]` system.

## Key Configuration Rules

**Group declarations require explicit fields.** Empty tables like `[dotfile_groups.nvim]` don't work. Each group needs:

```toml
[dotfile_groups.nvim]
root = "nvim"
mode = "symlink-each"
manifest = "git"
```

**Settings structure matters.** Use `[settings.dotfiles]` with `default_mode` (not just `mode`):

```toml
[settings.dotfiles]
root = "../../packages"  # relative path from .config/mise/
default_mode = "symlink-each"
```

**Relative paths resolve from the config file location.** If config is at `.config/mise/config.toml` and sources are at `packages/`, use `root = "../../packages"`.

## Platform Selection

Use `MISE_ENV` to select platform configs:

- `MISE_ENV=macos`: loads `config.macos.toml`
- `MISE_ENV=omarchy`: loads `config.omarchy.toml`
- No env: all declared groups apply by default

Each platform config contains `[bootstrap] dotfile_groups = [...]` listing which groups to apply.

## Behavior Validated in Testing

✅ **Git filtering works**: `manifest = "git"` excludes files in `.gitignore` from deployment
✅ **Executable bits preserved**: Scripts deployed via symlinks maintain executable permissions
✅ **Group deselection handles orphans**: Switching platforms removes platform-specific groups correctly
✅ **Unapply provides reversibility**: `mise dot unapply --group <name>` removes deployed files

## Common Pitfalls

- ❌ Don't use `dotfiles.root = "packages"` at top-level — use `[settings.dotfiles]` section
- ❌ Don't use `mode` in settings — use `default_mode`
- ❌ Don't create empty group tables — always specify `root`, `mode`, `manifest`
- ❌ Don't assume `~` expands in paths — use explicit relative or absolute paths

## Official Documentation

- [Groups](https://mise.jdx.dev/dotfiles/groups.html) — group declaration and selection
- [Managed files](https://mise.jdx.dev/dotfiles/managed.html) — modes, templates, edits
- [Config environments](https://mise.jdx.dev/configuration/environments.html) — MISE_ENV and platform selection
- [Dotfiles reference](https://mise.jdx.dev/dotfiles/reference.html) — all entry keys and modes
- [Templates](https://mise.jdx.dev/templates.html) — Tera template variables and functions

## Example Configuration

Base config (`.config/mise/config.toml`):

```toml
[settings.dotfiles]
root = "../../packages"
default_mode = "symlink-each"

[dotfile_groups.nvim]
root = "nvim"
mode = "symlink-each"
manifest = "git"

[dotfile_groups.zsh]
root = "zsh"
mode = "symlink-each"
manifest = "git"

[dotfile_groups.bash]
root = "bash"
mode = "symlink-each"
manifest = "git"
```

macOS config (`.config/mise/config.macos.toml`):

```toml
[bootstrap]
dotfile_groups = [
  "nvim",
  "zsh",
  # ... other groups
]
```

Omarchy config (`.config/mise/config.omarchy.toml`):

```toml
[bootstrap]
dotfile_groups = [
  "nvim",
  "bash",
  # ... other groups
]
```
