# dotf — Daily-Use Toolbox

`dotf` is a dispatcher script deployed to `~/.local/bin/dotf`. It routes subcommands to individual scripts in `~/.local/bin/dotf.d/`.

## Usage

After deployment, run these commands from the directory where you want the files:

```bash
dotf --help       # list available commands
dotf init         # select project templates with fzf
dotf init --all   # copy all available templates without prompting
```

`dotf init` copies templates into the current directory; it does not detect or
switch to the project root. Existing files, directories, and symlinks are skipped.
Templates come from
`${XDG_CONFIG_HOME:-$HOME/.config}/${NVIM_APPNAME:-nvim}/templates/`, so the selected
Neovim configuration must have its templates deployed. If templates are missing,
review the [deployment procedure](../commands.md#updating-existing-deployments).

The tracked templates provide `mise.toml`, `mise.local.toml`, and `.nvim.lua`.
The local mise override and Neovim project file are ignored by the dotfiles-managed
global Git ignore; shared `mise.toml` remains eligible for commits. Existing tracked
files are not untracked by these rules. Keep real secrets in a secret manager,
not plaintext local overrides.

Review generated files before running `mise trust`. To install the requested
runtimes afterward, run `mise install`. Neovim's Lua trust decision is separate;
scaffolding neither trusts configuration nor installs tools. See
[project environment migration](../commands.md#migrating-project-environments-and-editor-setup)
for legacy `.envrc` files and editor environment inheritance.

## Source Location

```text
packages/scripts/.local/bin/
  dotf            # dispatcher — routes dotf <cmd> [args] to dotf.d/<cmd>
  dotf.d/         # one executable file per subcommand
    init            # scaffold template files into the current directory
```

The `colima-*` subcommands live in `packages/colima-scripts/` and are selected
only by the macOS deployment profile, not the shared `scripts` group.

## Adding a New Subcommand

1. Create an executable file at `packages/scripts/.local/bin/dotf.d/<name>`
2. Line 1: `#!/usr/bin/env bash`
3. Line 2: a `# <one-line description>` comment — this is what `dotf --help` prints
4. Review the file and add it to Git's index (`git add <path>`); the deployment
   manifest includes only indexed files. A commit is not required to preview it.
5. Inspect deployment status and a scoped dry-run before an authorized `make link`.

## Makefile vs. dotf

Use Make targets for repository provisioning and deployment; use `dotf` subcommands
for daily utilities that need to work outside this repository.
