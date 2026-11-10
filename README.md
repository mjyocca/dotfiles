```text
 ____            __       ___      ___
/\  _`\         /\ \__  /'___\ __ /\_ \
\ \ \/\ \    ___\ \ ,_\/\ \__//\_\\//\ \      __    ____
 \ \ \ \ \  / __`\ \ \/\ \ ,__\/\ \ \ \ \   /'__`\ /',__\
  \ \ \_\ \/\ \L\ \ \ \_\ \ \_/\ \ \ \_\ \_/\  __//\__, `\
   \ \____/\ \____/\ \__\\ \_\  \ \_\/\____\ \____\/\____/
    \/___/  \/___/  \/__/ \/_/   \/_/\/____/\/____/\/___/
```

Personal dotfiles are managed with a Makefile, Bash scripts, and
[mise](https://mise.jdx.dev/dotfiles.html).

> For an alternative to mise's dotfile management, consider
> [chezmoi](https://www.chezmoi.io/); for a simpler, symlink-based setup, consider
> [GNU Stow](https://www.gnu.org/software/stow/).

This setup is shared for inspiration; it isn't intended for every machine.

> [!WARNING]
> Use at your own risk. Bootstrap installs software and changes your
> configuration. Review the configuration in this repository and your existing
> dotfiles before running it.

## Architecture

```text
dotfiles/
├── Makefile                     Lifecycle ordering + platform selection
├── .config/mise/                Declarative provisioning + deployment
│   ├── config.toml              Shared dotfile definitions
│   ├── config.<platform>.toml   Platform packages, settings + deployment rules
│   └── global/                 Global tools + machine policy templates
│       ├── tools.toml           Shared development tools
│       └── platform*.toml       Platform providers + exclusions
├── packages/                    Application dotfiles deployed by mise
│   ├── zsh/                     Zsh configuration
│   ├── bash/                    Bash configuration
│   ├── nvim/                    Neovim configuration
│   └── ...
└── scripts/                     Stage wrappers + setup outside mise
    ├── shared/                  Reusable implementations + mise calls
    ├── linux/                   Reusable Linux stage implementations
    └── <platform>/              Platform entrypoints + extensions
```

Dotfile package directories mirror `$HOME`. The mise configuration defines which
dotfile groups each platform deploys and where they go. Optional local mise
overrides let you customize the configuration for each machine without changing
the shared files. These overrides are ignored by Git.

- **System packages:** mise manages Homebrew on macOS and Pacman on Omarchy;
  scripts handle interactive AUR installation.
- **Platform configuration:** mise applies macOS defaults and deploys
  Omarchy settings, theme templates, and hooks.
- **Tools:** the global mise configuration makes development tools available
  outside this checkout as well. Language runtimes default to asdf; ignored
  machine preferences can select mise instead and choose direnv or mise for
  environment loading.
- **Plugins and hooks:** scripts install TPM, asdf plugins, gh-dash, a Zellij
  plugin, and the repository's Gitleaks hook.

See the [mise configuration architecture](docs/architecture/mise.md) for details
on environment selection, local overrides, and how the platform configurations
fit together.

## Install

```bash
git clone https://github.com/mjyocca/dotfiles.git ~/dotfiles
cd ~/dotfiles
make bootstrap
```

You'll need Git and Make to get started; bootstrap handles the remaining platform
prerequisites. See the [setup notes](docs/commands.md#setup-notes) for help getting
started on a fresh machine.

## Lifecycle

The `make bootstrap` command sets up a new machine. The `make sync` command brings
an existing setup up to date with the configuration in this checkout.

```text
make bootstrap
  prerequisites → [ packages → repos → link → tools → plugins ] → config → hooks
                   └─────────── make sync ───────────────────┘
```

Both commands run their steps in order and stop if a step fails.

### Everyday use

```bash
make sync
```

Sync installs system packages, checks out any optional repositories you've
configured, puts dotfiles in place, and installs development tools and plugin
integrations. Pull updates to this repository with Git first when you want the
latest configuration; sync doesn't pull them for you.

See the [command reference](docs/commands.md) for individual stages and previews.
