# mise Dotfile Deployment

Use for deployment wiring, not package ownership or general mise tutorials.

## Repository Layout and Current Gap

- `packages/<name>/` mirrors paths under `$HOME`.
- `make link` runs `mise dotfiles apply` from the repository root.
- `.config/mise/config.toml` and its platform files currently declare bootstrap
  packages, **not** dotfile groups or a `settings.dotfiles` root. The deployed
  `packages/mise/.config/mise/config.toml` declares dev tools only.
- Therefore tracked configuration alone does not establish package deployment.
  Inspect effective configuration (`mise config ls`) and `mise dotfiles status`
  before promising what will be linked. Machine-local declarations may exist.
  Missing deployment wiring is an implementation follow-up, not permission to
  create ad hoc symlinks or invent group selections during another task.

## Editing Deployment Configuration

Consult [mise groups](https://mise.jdx.dev/dotfiles/groups.html) and the
[dotfiles reference](https://mise.jdx.dev/dotfiles/reference.html) for the installed
version before adding declarations. Do not copy historical sample TOML as current
configuration. In particular:

- Verify root resolution, group selection, and defaults upstream; platform files
  do not currently contain the previously documented group selections.
- `MISE_ENV` selects environment files, not an OS automatically. Zsh currently
  exports `macos` in `packages/zsh/.zshenv`; confirm the effective value elsewhere.
- Account for tracked versus ignored/local files before selecting a deployment
  manifest. Do not deploy credentials or add agent metadata to a package tree
  without checking whether it will be copied into `$HOME`.
- Inspect target collisions and existing user edits before apply. Deselecting a
  group is not proof that old files were removed; pruning/unapply are separate,
  potentially destructive operations requiring explicit scope and authorization.

## Command Boundaries

`make bootstrap` runs prerequisites, packages, tools, plugins, config, and hooks;
the Makefile has no explicit link step. Package scripts invoke `mise bootstrap`,
whose behavior depends on effective mise declarations—do not assume it never
deploys files when machine-local dotfile configuration exists.

`make sync` runs packages, link, and plugins only. It does not run tools, config,
or hooks. Use the narrow task-appropriate layer rather than treating sync as full
provisioning. Deployment still requires authorized `make link` with valid wiring.

For documentation-only checks, inspect declarations and Make recipes without
running apply, bootstrap, prune, or unapply. Runtime deployment behavior has not
been established by a text audit.
