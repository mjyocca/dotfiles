# Command Reference

Run commands from the checkout. Bare `make` shows help without provisioning.
Supported profiles are `macos` (Apple Silicon) and `omarchy`; other Linux distros
need their own configuration and platform entrypoints.

## Setup notes

Git and Make must be available before cloning and running `make bootstrap`.

- **macOS:** if missing, run `xcode-select --install` and complete Command Line
  Tools installation. These supply Git and Make. Bootstrap also checks for the
  tools; if it opens the installer, finish installation and rerun bootstrap.
- **Omarchy:** if needed, run `sudo pacman -S --needed git make`.

Bootstrap installs or reuses mise and ensures platform prerequisites, including
Homebrew on macOS. Existing mise providers and machine-local configuration are
preserved. Review deployment conflicts before applying; conflicting local files
are not force-overwritten. Bootstrap can be rerun after resolving a failure.

## Workflows

| Command | Stages |
|---|---|
| `make` / `make help` | Show available commands |
| `make bootstrap` | prerequisites → packages → repos → link → tools → plugins → config → hooks |
| `make sync` | packages → repos → link → tools → plugins |

Stages run sequentially, including under `make -j`, and stop on failure. Update
this checkout explicitly with Git before syncing when you want newer declarations.
Neither workflow pulls this checkout, requests package upgrades/removals, or
activates macOS LaunchAgents. In mise-runtime mode, their tools stage can install
discovered language versions; asdf runtimes are not installed or transferred.
Sync also skips prerequisites, platform preferences, and repository hook installation.

## Individual stages

| Command | Responsibility |
|---|---|
| `make prerequisites` | Install/reuse mise and ensure platform prerequisites |
| `make packages` | Install system packages, including interactive AUR review on Omarchy |
| `make repos` | Provision optional configured workspace checkouts; does not request updates to latest remote commits |
| `make link` | Deploy selected dotfiles, global mise tool fragments, shell policy, and discovery guard |
| `make tools` | Install effective mise tool requests; requires deployed global configuration |
| `make plugins` | Install TPM, asdf plugins when selected, gh-dash, and the pinned Zellij plugin |
| `make config` | Apply additional platform preferences where implemented |
| `make hooks` | Install the repository's Gitleaks pre-commit hook when Gitleaks is available |

`make config` currently applies macOS defaults only. Individual tmux plugin
installation and updates remain explicit; installing TPM does not install them.

### Scoped previews

```bash
make link DOTFILES_ARGS='--dry-run ~/.bashrc'
make tools TOOLS_ARGS=--dry-run
```

`DOTFILES_ARGS` passes arguments to `mise dotfiles apply`; `TOOLS_ARGS` passes
arguments to `mise install`.

## Utilities

| Command | Responsibility |
|---|---|
| `make aur` | Rerun Omarchy's interactive AUR stage |
| `make ghostty-shader REPO=<git-url>` | Import Ghostty shaders into the checkout for review |

## Platform selection and direct mise use

Make detects `PROFILE`, defaults `MISE_ENV` to that profile, and rejects conflicting
selections or a missing platform configuration. Override detection explicitly:

```bash
make bootstrap PROFILE=omarchy
```

Deployment seeds an ignored, create-only `.miserc.local.toml` with the selected
platform. After deployment, direct mise commands inside the checkout can use that
default when neither `-E` nor `MISE_ENV` is set:

```bash
mise config ls
mise dot apply --dry-run
mise bootstrap --only packages --dry-run
```

Before initial deployment, use Make or explicitly select the environment with
`mise -E <platform> ...`. Existing workspace defaults and shell exports are
preserved; deployment will not repair an incorrect create-only default.

See [mise configuration architecture](architecture/mise.md) for global versus
checkout scope, machine-local overrides, optional repositories, and LaunchAgents.
