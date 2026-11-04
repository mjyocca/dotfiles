# mise Dotfile Deployment

Use for deployment wiring, not package ownership or general mise tutorials.

## Repository Layout

- Dotfile directories under `packages/<name>/` mirror paths under `$HOME`.
  Exception: `packages/aur/` is repository-only installation data. Never select
  it as a dotfile group or include it through broad package-directory discovery.
- `make link` runs `mise dotfiles apply` from the repository root through the
  shared provisioning PATH wrapper (no interactive shell or runtime activation).
- `.config/mise/config.toml` declares bootstrap packages, `settings.dotfiles.root`
  (`../../packages`), and explicit Git-filtered dotfile groups. Keep package and
  deployment declarations together; neither replaces the other.
- `config.macos.toml` and `config.omarchy.toml` select groups under
  `[bootstrap] dotfile_groups`. The base selection is empty for safety until a
  platform environment is selected. Make exports `MISE_ENV` from `PROFILE` (which
  defaults to detection) unless already set; direct mise commands need `-E macos`
  or `-E omarchy`.
- Git, SSH, Ghostty, and Zellij have template overrides; their deployed files are
  rendered copies, not source symlinks. Other group files use `symlink-each`.
- Ghostty's template keeps macOS styling independent. Its Linux/Omarchy branch
  includes the current Omarchy theme without hardcoded palette overrides and
  preserves the stock font/window settings and Hyprland workaround. Cursor/SSH
  integration and distinct Enter encodings are shared; Ctrl-s sequences remain
  commented out for multiplexers. Deploy the cursor shader alongside the config.
- Git's `~/.gitconfig` template selects the host clipboard command and includes
  optional `~/.gitconfig.local` last, so local scalar settings override shared ones.
  For machine-local edits, use `git config --file ~/.gitconfig.local ...`; this
  creates the local file if needed. Keep it outside mise deployment. Its package
  counterpart `packages/gitconfig/.gitconfig.local` is gitignored and excluded by
  the group's Git manifest, not automatically linked or rendered.
  On Omarchy, preserve existing `~/.config/git/config` and its credential helpers;
  Git reads it before `~/.gitconfig`. Do not copy credentials or machine-specific
  helper paths into the template. `git config --global` writes the rendered
  `~/.gitconfig` once it exists, and reapplying mise can replace those edits.
  Inspect combined values with `git config --show-origin ...` rather than
  restricting the query to `--global`.
- Omarchy overrides the `nvim` group to deploy into `~/.config/nvim-dotfiles`,
  leaving its stock `~/.config/nvim` untouched. Bash defaults `NVIM_APPNAME` to
  `nvim-dotfiles` when deployed; `nv-omarchy`/`nvim-omarchy` explicitly select `nvim`.
- The deployed `packages/mise/.config/mise/config.toml` declares dev tools only.
  Inspect `mise config ls` and `mise dotfiles status` before deployment;
  machine-local declarations may also affect the effective configuration.
- The repository's `config.omarchy.toml` also records this machine's existing
  mise tool requests. They are checkout-scoped, not deployed global defaults,
  and are not installed by `make tools`. Do not replace the global mise config
  assuming these requests will remain active outside the checkout.

## Editing Deployment Configuration

Consult [mise groups](https://mise.jdx.dev/dotfiles/groups.html) and the
[dotfiles reference](https://mise.jdx.dev/dotfiles/reference.html) for the installed
version before adding declarations. Do not copy historical sample TOML as current
configuration. In particular:

- Verify root resolution, group selection, and defaults upstream. Preserve explicit
  platform selections and `manifest = "git"` filtering when changing package setup.
- `MISE_ENV` selects environment files, not an OS automatically. Zsh defaults it
  to `macos` in `packages/zsh/.zshenv`, preserving overrides; confirm it elsewhere.
- Account for tracked versus ignored/local files before selecting a deployment
  manifest. Do not deploy credentials or add agent metadata to a package tree
  without checking whether it will be copied into `$HOME`.
- Inspect target collisions and existing user edits before apply. Deselecting a
  group is not proof that old files were removed; pruning/unapply are separate,
  potentially destructive operations requiring explicit scope and authorization.

## Command Boundaries

`make bootstrap` runs prerequisites (including mise installation), packages, tools,
plugins, config, and hooks; the Makefile has no explicit link step. Package scripts
invoke `mise bootstrap --skip tools`, which also applies the selected dotfile groups.
Therefore `make packages` is not a package-only operation. The separate tools layer
installs only the tracked shared dev tools, excluding asdf runtime defaults.

`make sync` runs packages, link, and plugins only. It does not run tools, config,
or hooks. Use the narrow task-appropriate layer rather than treating sync as full
provisioning. Use authorized `make link` for deployment without installing packages.
Pass `DOTFILES_ARGS` for flags and/or target paths when only part of the profile
is authorized, e.g. `make link PROFILE=omarchy DOTFILES_ARGS='--dry-run ~/.bashrc ~/.bash_profile ~/.config/bash/nvim.bash ~/.config/nvim-dotfiles ~/.config/nvim-next'`.

For documentation-only checks, inspect declarations and Make recipes without
running apply, bootstrap, prune, or unapply. Check status and `apply --dry-run`
before authorized deployment. Never broadly prune while declarations are missing:
previously deployed groups appear orphaned even though their files are still useful.
