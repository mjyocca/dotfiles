# mise Dotfile Deployment

Use for deployment wiring, not package ownership or general mise tutorials.

## Sources and Scope

Declarations live in `.config/mise/`; home-relative sources live under
`packages/<name>/`. See [mise architecture](../architecture/mise.md) for platform
composition and global versus checkout scope.

- Never deploy `packages/aur/`; it contains repository-only installation data.
- Select the intended platform before deployment. Inspect `mise config ls` and
  `mise dotfiles status`, including checkout-local overrides and system defaults.
- Make requires a platform configuration and matching `PROFILE`/`MISE_ENV`.
  Direct mise commands bypass that check; select the intended environment explicitly.
- Preserve Git-filtered manifests and explicit platform group selections. Do not
  turn an empty base selection into an implicit all-platform deployment.
- Preserve machine-local files, credentials, provider/service configuration, and
  Omarchy-owned defaults. Inspect each target's declared scope before applying.
- Templates are rendered copies that can replace local edits; edits through
  symlinks modify tracked sources. Keep machine-local settings in supported local
  overrides rather than rendered files.
- Preserve checkout-local exclusions. Confirm group replacement semantics before
  editing an override; deselection does not remove previously deployed files.
- Deploy mise's discovery guard before asdf-owned `.tool-versions` files.

## Editing Deployment Configuration

Consult the installed version's [dotfiles manual](https://mise.jdx.dev/dotfiles.html),
[groups](https://mise.jdx.dev/dotfiles/groups.html), and
[reference](https://mise.jdx.dev/dotfiles/reference.html) for syntax and merge rules.
Inspect source manifests, target collisions, existing edits, and backups before
an authorized scoped apply. Prune/unapply require separate explicit scope and
authorization; never infer that old files are safe to remove from missing declarations.

## Command Boundaries

- `make packages` runs bootstrap with tools skipped, but can deploy dotfiles.
- `make tools` installs effective tool requests after global configuration is
  deployed, including intentional machine-local requests but not asdf version files.
- `make link` deploys without installing packages. Use `PROFILE` and
  `DOTFILES_ARGS` to limit the operation, e.g.
  `make link PROFILE=omarchy DOTFILES_ARGS='--dry-run ~/.bashrc'`.
- `make sync` runs packages, link, tools, and plugins sequentially, not full provisioning.

For documentation-only checks, inspect declarations and Make recipes without
running provisioning or deployment. For deployment work, inspect status and a
scoped dry-run first; apply only when authorized.
