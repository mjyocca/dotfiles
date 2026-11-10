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
activates macOS LaunchAgents. Their tools stage can install discovered language
versions through mise; existing asdf runtime installations are not transferred.
Sync also skips prerequisites, platform preferences, and repository hook installation.

## Individual stages

| Command | Responsibility |
|---|---|
| `make prerequisites` | Install/reuse mise and ensure platform prerequisites |
| `make packages` | Install system packages, including interactive AUR review on Omarchy |
| `make repos` | Provision optional configured workspace checkouts; does not request updates to latest remote commits |
| `make link` | Deploy selected dotfiles, global mise tool fragments, and discovery policy |
| `make tools` | Install effective mise tool requests; requires deployed global configuration |
| `make plugins` | Install TPM, gh-dash, and the pinned Zellij plugin |
| `make config` | Apply additional platform preferences where implemented |
| `make hooks` | Install the repository's Gitleaks pre-commit hook when Gitleaks is available |

`make config` currently applies macOS defaults only. Individual tmux plugin
installation and updates remain explicit; installing TPM does not install them.

### Scoped previews

Before using `make tools`, including its dry-run, deploy the global mise
configuration and discovery policy with `make link`.

```bash
make link DOTFILES_ARGS='--dry-run ~/.config/mise/miserc.toml ~/.bashrc ~/.bash_profile'
make tools TOOLS_ARGS=--dry-run
```

`DOTFILES_ARGS` passes arguments to `mise dotfiles apply`; `TOOLS_ARGS` passes
arguments to `mise install`.

Include discovery policy when previewing or applying shell startup changes. The
example above covers only Bash startup and discovery policy; see the
[complete migration deployment](architecture/mise.md#runtimes-and-project-environments)
for the remaining dotfiles.

## Upgrades

| Command | Scope |
|---|---|
| `make upgrade` | Upgrade effective mise tools and runtimes within configured version ranges; keep old versions |
| `make upgrade-system` | macOS: upgrade installed system packages declared in the effective mise configuration, including Brew formulae and casks. Omarchy: run the official full-system updater |

These are separate from bootstrap and sync. Exact runtime pins stay pinned;
neither target bumps version requests, deploys dotfiles, or pulls this checkout.
Effective configuration includes machine-local overrides, not just tracked defaults.
The macOS system target skips missing packages; use `make packages` to install them.

On Omarchy, `make upgrade-system` requires an interactive terminal and confirmation
that the update covers the whole system and may prompt for a reboot. It then calls
`omarchy-update` without bypassing its own prompts. Omarchy manages snapshots,
migrations, AUR updates, and orphan cleanup. There is no direct Pacman/Yay fallback:
upgrading only declared Pacman packages risks an unsupported partial upgrade.
See the [official Omarchy update workflow](https://omarchy.org/manual/updates/).

To run both sequentially, with system updates last because Omarchy may reboot:

```bash
make upgrade && make upgrade-system
```

Do not pass both targets to parallel Make; they are independent and could run
concurrently. For a mise-only preview, select the platform as described below:

```bash
mise -E macos upgrade --no-prune --dry-run
mise -E macos bootstrap packages upgrade --dry-run
```

The second preview is macOS-only; it is not a safe Omarchy upgrade path. The
Omarchy updater has no equivalent full dry-run exposed by these targets.

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

If your shell exports another project's environment, such as `MISE_ENV=staging`,
select a matching profile and environment for this invocation:

```bash
make link PROFILE=macos MISE_ENV=macos
# On Omarchy:
make link PROFILE=omarchy MISE_ENV=omarchy
```

These command-line assignments do not change the parent shell's environment.

Deployment seeds an ignored, create-only `.miserc.local.toml` with the selected
platform. After deployment, direct mise commands inside the checkout can use that
default when neither `-E` nor `MISE_ENV` is set:

```bash
mise config ls
mise dot apply --dry-run
mise bootstrap --only packages --dry-run
```

Shell startup does not export a default `MISE_ENV`, and the checkout-local default
does not set that shell variable. An empty `echo "$MISE_ENV"` is therefore expected.
To verify platform selection, use `mise config ls` and look for
`.config/mise/config.<platform>.toml`; `(none)` in its Tools column means it declares
no runtime tools, not that the configuration is inactive.

Before initial deployment, use Make or explicitly select the environment with
`mise -E <platform> ...`. Existing workspace defaults and shell exports are
preserved; deployment will not repair an incorrect create-only default.

See [mise configuration architecture](architecture/mise.md) for global versus
checkout scope, machine-local overrides, optional repositories, and LaunchAgents.
