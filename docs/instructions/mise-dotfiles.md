# mise Configuration and Deployment

Use for provisioning boundaries and deployment safety. Package ownership lives
in [package policy](package-management.md); do not duplicate upstream tutorials.

## Sources and Scope

Declarations live in `.config/mise/`; home-relative sources live under
`packages/<name>/`. See [mise architecture](../architecture/mise.md) for platform
composition and global versus checkout scope.

- Never deploy `packages/aur/`; it contains repository-only installation data.
- Select the intended platform before deployment. Inspect `mise config ls` and
  `mise dotfiles status`, including checkout-local overrides and system defaults.
- Make requires a platform configuration and matching `PROFILE`/`MISE_ENV`.
  Direct mise commands bypass that check. After deployment, the checkout's ignored
  `.miserc.local.toml` supplies a default only when `-E` and `MISE_ENV` are absent;
  confirm loaded config before applying. Initial deployment needs explicit selection.
- Keep the workspace environment seed create-only and checkout-scoped. Do not put
  its `env` selection in the globally rendered discovery guard template.
- Preserve Git-filtered manifests and explicit platform group selections. Do not
  turn an empty base selection into an implicit all-platform deployment.
- Preserve machine-local files, credentials, provider/service configuration, and
  Omarchy-owned defaults. Inspect each target's declared scope before applying.
- Templates are rendered copies that can replace local edits; edits through
  symlinks modify tracked sources. Keep machine-local settings in supported local
  overrides rather than rendered files.
- Preserve checkout-local exclusions. Confirm group replacement semantics before
  editing an override; deselection does not remove previously deployed files.
- Deploy mise's discovery policy before `.tool-versions` files.
- Keep provisioning rules repository-scoped and tool defaults global. Prefer
  native mise features over custom configuration merging.
- Include the discovery policy and shared runtime PATH helper when deploying shell
  changes. Native dependencies order selected targets but do not expand a scoped
  apply; template dry-runs do not validate rendered content. See
  [runtime architecture](../architecture/mise.md#runtimes-and-project-environments).

## Editing Deployment Configuration

Consult the installed version's [dotfiles manual](https://mise.jdx.dev/dotfiles.html),
[groups](https://mise.jdx.dev/dotfiles/groups.html), and
[reference](https://mise.jdx.dev/dotfiles/reference.html) for syntax and merge rules.
Inspect source manifests, target collisions, existing edits, and backups before
an authorized scoped apply. Prune/unapply require separate explicit scope and
authorization; never infer that old files are safe to remove from missing declarations.

## Verification

Use `PROFILE` and `DOTFILES_ARGS` to scope deployment, for example
`make link PROFILE=omarchy DOTFILES_ARGS='--dry-run ~/.bashrc'`. Direct mise
inspection also needs the intended environment, e.g. `mise -E omarchy config ls`,
or a verified workspace default with no conflicting `MISE_ENV`.
Inspect the Make recipes before invoking a target: `make packages` installs system
packages only (including Omarchy AUR), `make link` deploys dotfiles, and `make tools`
installs effective requests, not only tracked defaults. Bootstrap and sync deploy
global configuration before installing tools.

For documentation-only checks, inspect declarations and Make recipes without
running provisioning or deployment. For deployment work, inspect status and a
scoped dry-run first; apply only when authorized.
