```
    ____        __  _______ __         
   / __ \____  / /_/ ____(_) /__  _____
  / / / / __ \/ __/ /_  / / / _ \/ ___/
 / /_/ / /_/ / /_/ __/ / / /  __(__  ) 
/_____/\____/\__/_/   /_/_/\___/____/                     
```

Personal dotfiles managed with [mise](https://mise.jdx.dev/dotfiles.html).
Make orders the lifecycle; platform scripts compose shared implementations.

## Install

### Platform prerequisites

**macOS (Apple Silicon):** install Xcode Command Line Tools if missing, then wait
for installation to finish. They provide Git and Make for the next step.

```bash
xcode-select --install
```

**Omarchy:** ensure Git and Make are available.

```bash
sudo pacman -S --needed git make
```

### Clone and bootstrap

Use the same entrypoint on either platform:

```bash
git clone https://github.com/mjyocca/dotfiles.git ~/dotfiles
cd ~/dotfiles
make bootstrap
```

Bootstrap detects the platform and changes this machine: it installs missing
software, deploys selected dotfiles, and applies declared platform preferences.
Review declarations and existing dotfile conflicts first. Existing mise providers
and machine-local configuration are preserved; conflicts are not force-overwritten.
Bootstrap can be rerun after resolving a failure. It does not pull this repository,
request package upgrades/removals, or activate macOS LaunchAgents.

## Lifecycle

```text
prerequisites → packages → repos → link → tools → plugins → config → hooks
```

| Stage | Responsibility |
|---|---|
| `prerequisites` | Install/reuse mise and ensure platform prerequisites, including Homebrew on macOS |
| `packages` | Install system packages; also run interactive AUR review on Omarchy |
| `repos` | Provision optional configured workspace checkouts, without updating existing checkouts to their latest remote commits |
| `link` | Deploy selected dotfiles, global mise tool fragments, and discovery policy |
| `tools` | Install effective mise tool requests, including intentional local additions |
| `plugins` | Install TPM, declared asdf plugins, gh-dash, and the pinned Zellij plugin |
| `config` | Apply additional platform preferences where implemented; macOS defaults only |
| `hooks` | Install this repository's Gitleaks pre-commit hook when Gitleaks is available |

Packages are installed before deployment; global mise configuration must be
deployed before tools. Stages run sequentially, including under `make -j`, and
stop on failure. Language runtime versions remain managed by asdf and are not
installed by bootstrap. Individual tmux plugin installation/updates remain explicit.

## Everyday commands

Run these from the checkout:

```bash
make                 # Show help; does not provision anything
make sync            # packages → repos → link → tools → plugins
make packages        # System packages only; no dotfile deployment
make link            # Deploy dotfiles only
make tools           # Install effective mise tools after deployment
make plugins         # Install tracked plugin integrations
```

Update the checkout explicitly with Git before syncing when you want newer
declarations. `sync` does not run prerequisites, apply platform preferences, or
install Git hooks.

Preview a scoped deployment or tool installation:

```bash
make link DOTFILES_ARGS='--dry-run ~/.bashrc'
make tools TOOLS_ARGS=--dry-run
```

`make aur` reruns Omarchy's interactive AUR stage. `make ghostty-shader
REPO=<git-url>` imports shaders into the checkout for review.

## Platforms and composition

Supported provisioning profiles are `macos` (Apple Silicon) and `omarchy`.
Override detection with `PROFILE`, for example `make bootstrap PROFILE=omarchy`.
Make defaults `MISE_ENV` to that profile and rejects conflicting selections or a
missing platform configuration. Detecting another Linux distro does not imply
that provisioning is supported.

Deployment seeds an ignored `.miserc.local.toml` in this checkout with the selected
platform as mise's default. After deployment, direct commands such as
`mise config ls`, `mise dot apply --dry-run`, and
`mise bootstrap --only packages --dry-run` work here without `-E`, in Bash or Zsh.
An explicit `-E` or `MISE_ENV` still wins. Existing workspace defaults, shell exports,
and global configuration are left alone; outside the checkout, nothing changes.
Before the first deployment, select the platform through Make or explicit `-E`.

Platform entrypoints live at `scripts/<platform>/<stage>.sh`. They source shared
implementations, or explicitly inherit Linux entrypoints, and can extend or
replace functions before running a stage. Make does not hide inheritance behind
script fallback rules. Platform `config.sh` is optional; deployment always belongs
to `link`.

See [mise configuration architecture](docs/architecture/mise.md) for shared,
platform-specific, and machine-local configuration scope, optional workspace
repositories, and how to add a distro.
