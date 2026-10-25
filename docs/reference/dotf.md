# dotf — Daily-Use Toolbox

`dotf` is a dispatcher script stowed to `~/.local/bin/dotf`. It routes subcommands to individual scripts in `~/.local/bin/dotf.d/`.

## Source Location

```
packages/scripts/.local/bin/
  dotf            # dispatcher — routes dotf <cmd> [args] to dotf.d/<cmd>
  dotf.d/         # one executable file per subcommand
    colima-use              # switch colima profile + docker context + socket
    colima-list             # list profiles, states, contexts
    colima-migrate-volumes  # export/import volumes between colima profiles
    init                    # scaffold template files into the current project root (fzf picker)
```

## How It Works

Running `dotf --help` auto-lists all commands with their one-line descriptions (pulled from the second line of each script).

## Adding a New Subcommand

1. Create an executable file at `packages/scripts/.local/bin/dotf.d/<name>`
2. Line 1: `#!/usr/bin/env bash`
3. Line 2: a `# <one-line description>` comment — this is what `dotf --help` prints
4. Run `make dotfiles` to stow it into `~/.local/bin/dotf.d/`

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

**Use a Makefile target when** the command is about the dotfiles project: provisioning a machine, stowing packages, applying OS defaults, installing tools. These run once or rarely and operate on the repo itself.

**Use a `dotf` subcommand when** the script is a general-purpose utility that should be available anywhere in a shell session: switching runtimes, managing containers, scaffolding projects, or any workflow tool that travels with the developer rather than the repo.
