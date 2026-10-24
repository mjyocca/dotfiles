# Omarchy Instructions

This file contains Omarchy (Arch-based Linux) specific conventions and configuration instructions.

## Official Resources

**When you need additional context about Omarchy, consult these authoritative sources:**

- **Online Manual**: https://learn.omacom.io/ — comprehensive documentation for users
- **GitHub Manual**: https://github.com/basecamp/omarchy/tree/quattro/manual — markdown source files
  - Chapter 31 (Dotfiles): https://github.com/basecamp/omarchy/blob/quattro/manual/31-dotfiles.md
  - Chapter 15 (Terminal): https://github.com/basecamp/omarchy/blob/quattro/manual/15-terminal.md
  - Chapter 16 (Neovim): https://github.com/basecamp/omarchy/blob/quattro/manual/16-neovim.md
  - Chapter 40 (Prompt): https://github.com/basecamp/omarchy/blob/quattro/manual/40-prompt.md
  - Chapter 42 (Common Tweaks): https://github.com/basecamp/omarchy/blob/quattro/manual/42-common-tweaks.md
- **Source Code**: `/usr/share/omarchy/` — read-only system package (safe to read, never edit)
  - `bin/` — Command scripts (useful to understand how omarchy commands work)
  - `config/` — Default configuration templates
  - `default/` — System defaults (hypr, bash, etc.)
  - `themes/` — Stock theme definitions
  - `shell/` — Omarchy shell source and defaults

**Reading is safe**: You can freely read `/usr/share/omarchy/` to understand defaults, check how commands work, or reference stock themes. Never modify these files directly.

**When to consult**: Before making significant changes to Omarchy configuration, check the relevant manual chapter. When you need to understand how a specific omarchy command works, read the source in `/usr/share/omarchy/bin/`.

## Omarchy Override Model

**From official manual (`31-dotfiles.md`):**
- User configs live in `~/.config` (your files, safe to edit)
- System defaults live in `/usr/share/omarchy` (owned by omarchy package, **never edit**)
- Override values by placing files in `~/.config` instead

## Prescribed User Override Paths

### Hyprland Configuration

```
~/.config/hypr/
├── hyprland.lua       # Main config (loads Omarchy defaults + overrides below)
├── bindings.lua       # Keybindings and overrides
├── monitors.lua       # Display configuration
├── input.lua          # Keyboard/mouse settings
├── looknfeel.lua      # Appearance (gaps, borders, animations)
├── autostart.lua      # Startup applications
├── hyprsunset.conf    # Night light
└── xdph.conf          # Screen sharing / desktop portal
```

### Omarchy Shell Configuration

```
~/.config/omarchy/
├── shell.json         # Bar layout, widgets, idle/lock timings
├── hooks/<event>.d/   # Automation hooks (post-boot, theme-set, etc.)
├── extensions/        # Custom menu entries
└── themes/            # Custom themes
```

## Stow Integration

**Stow is endorsed** by the Omarchy manual for dotfile backup/management.

## Collision Warnings

- Omarchy seeds stock configs into `~/.config` (ghostty, btop, lazygit, starship, tmux, etc.)
- Stowing your packages **replaces** those with symlinks to your repo
- This is intentional if you want your cross-machine config to win
- Use `make stow PKG=<name> FLAGS=--adopt` once when migrating to adopt existing files
- Keep packages you want to own in the `omarchy` profile deliberately

## Post-Refresh Workflow

- After `omarchy reinstall configs` or `omarchy update`, re-run `make dotfiles`
- Omarchy may restore configs to defaults and leave `.bak` files
- Symlinks into the repo should be re-established

## Shell Differences

**Omarchy is bash-first at the desktop level:**
- zsh is included in the dotfiles but interactive ergonomics (tdl, tsd, etc.) assume bash
- Shell functions and aliases are in `~/.bashrc` (not overwritten on updates)
- Omarchy shell functions are sourced from `$OMARCHY_PATH/default/bash/rc`

## Future Desktop Packages

When adding Hyprland/Omarchy desktop packages:
- Only stow override files from the paths above
- Never stow wholesale replacements of Omarchy package internals
- Prefer files the loader already `require`s (e.g. `bindings.lua`, not `hyprland.lua`)

## Complex Desktop Config

For Hyprland, bar, themes, and other Omarchy desktop configuration, invoke the `omarchy` skill.
