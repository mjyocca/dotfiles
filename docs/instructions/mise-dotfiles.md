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
- The deployed `packages/mise/.config/mise/config.toml` declares dev tools only.
  Inspect `mise config ls` and `mise dotfiles status` before deployment;
  machine-local declarations may also affect the effective configuration.

## Editing Deployment Configuration

Consult [mise groups](https://mise.jdx.dev/dotfiles/groups.html) and the
[dotfiles reference](https://mise.jdx.dev/dotfiles/reference.html) for the installed
version before adding declarations. Do not copy historical sample TOML as current
configuration. In particular:

- Verify root resolution, group selection, and defaults upstream. Preserve explicit
  platform selections and `manifest = "git"` filtering when changing package setup.
- `MISE_ENV` selects environment files, not an OS automatically. Zsh currently
  exports `macos` in `packages/zsh/.zshenv`; confirm the effective value elsewhere.
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

For documentation-only checks, inspect declarations and Make recipes without
running apply, bootstrap, prune, or unapply. Check status and `apply --dry-run`
before authorized deployment. Never broadly prune while declarations are missing:
previously deployed groups appear orphaned even though their files are still useful.
