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
4. Run `make link` to deploy it to `~/.local/bin/dotf.d/`

---

## Makefile vs. dotf — Where to Put New Commands

| Criterion | Makefile target | `dotf` subcommand |
|---|---|---|
| Operates on the dotfiles repo itself | yes | no |
| Run during bootstrap / provisioning | yes | no |
| Needs to be available everywhere on the machine | no | yes |
| Used interactively during normal daily work | no | yes |
| Manages external tools (docker, colima, editors…) | no | yes |
| Accepts dynamic arguments / flags | awkward | natural |

**Use a Makefile target when** the command is about the dotfiles project: provisioning a machine, deploying packages, applying OS defaults, installing tools. These run once or rarely and operate on the repo itself.

**Use a `dotf` subcommand when** the script is a general-purpose utility that should be available anywhere in a shell session: switching runtimes, managing containers, scaffolding projects, or any workflow tool that travels with the developer rather than the repo.
