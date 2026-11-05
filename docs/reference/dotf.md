# dotf — Daily-Use Toolbox

`dotf` is a dispatcher script deployed to `~/.local/bin/dotf`. It routes subcommands to individual scripts in `~/.local/bin/dotf.d/`.

## Source Location

```
packages/scripts/.local/bin/
  dotf            # dispatcher — routes dotf <cmd> [args] to dotf.d/<cmd>
  dotf.d/         # one executable file per subcommand
    init                    # scaffold template files into the current project root (fzf picker)
```

The `colima-*` subcommands live in `packages/colima-scripts/` and are selected
only by the macOS deployment profile, not the shared `scripts` group.

## How It Works

Running `dotf --help` auto-lists all commands with their one-line descriptions (pulled from the second line of each script).

## Adding a New Subcommand

1. Create an executable file at `packages/scripts/.local/bin/dotf.d/<name>`
2. Line 1: `#!/usr/bin/env bash`
3. Line 2: a `# <one-line description>` comment — this is what `dotf --help` prints
4. Review the file and add it to Git's index (`git add <path>`); the deployment
   manifest includes only indexed files. A commit is not required to preview it.
5. Inspect deployment status and a scoped dry-run before an authorized `make link`.

---

## Makefile vs. dotf

Use Make targets for repository provisioning and deployment; use `dotf` subcommands
for daily utilities that need to work outside this repository.
