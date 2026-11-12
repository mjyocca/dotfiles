```text
 ____            __       ___      ___
/\  _`\         /\ \__  /'___\ __ /\_ \
\ \ \/\ \    ___\ \ ,_\/\ \__//\_\\//\ \      __    ____
 \ \ \ \ \  / __`\ \ \/\ \ ,__\/\ \ \ \ \   /'__`\ /',__\
  \ \ \_\ \/\ \L\ \ \ \_\ \ \_/\ \ \ \_\ \_/\  __//\__, `\
   \ \____/\ \____/\ \__\\ \_\  \ \_\/\____\ \____\/\____/
    \/___/  \/___/  \/__/ \/_/   \/_/\/____/\/____/\/___/
```

Personal dotfiles managed with Make, Bash scripts, and
[mise](https://mise.jdx.dev/dotfiles.html).

> For an alternative to mise's dotfile management, consider
> [chezmoi](https://www.chezmoi.io/); for a symlink-focused setup, consider
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
│   └── global/                 Global tool fragments
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

| Domain | Managed by | Responsibility |
|---|---|---|
| Lifecycle | Make + Bash scripts | Select the platform and run setup stages in order |
| System packages | mise bootstrap + Homebrew/Pacman | Install platform packages (Bash scripts handle interactive AUR installation) |
| Dotfiles | mise dotfiles | Deploy selected configuration files and templates |
| Development tools / Language runtimes | mise | Install CLI tools / select global or project-specific versions of Go, Rust, Node.js, etc. |
| Project environments | mise | Load project variables and PATH additions |
| Platform configuration | mise + Bash scripts | Apply macOS preferences and deploy Omarchy settings, themes, and hooks |
| Plugins and repository hooks | Bash scripts | Install TPM, gh-dash, a Zellij plugin, and the Gitleaks hook |

See the [mise configuration architecture](docs/architecture/mise.md) for details
on environment selection, local overrides, and how the platform configurations
fit together.

## Install

This setup supports Apple Silicon macOS and Omarchy machines. Git and Make must
already be available; see the [setup notes](docs/commands.md#setup-notes) for
platform prerequisites. Bootstrap handles the remaining prerequisites.

```bash
git clone https://github.com/mjyocca/dotfiles.git ~/dotfiles
cd ~/dotfiles
make bootstrap
```

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

Sync installs system packages, provisions optional workspace repositories, deploys
dotfiles, and installs development tools, language runtimes, and plugin
integrations. Pull repository updates with Git first; sync doesn't pull them for you.

```bash
make upgrade
```

Upgrade mise tools within their configured version ranges, keeping old versions.
Pinned language runtimes stay pinned; system package upgrades are separate.

See the [command reference](docs/commands.md) for individual stages and previews.
For project scaffolding and daily utilities, see the [dotf toolbox](docs/reference/dotf.md).

## Documentation

- [Commands and setup](docs/commands.md) — Prerequisites, lifecycle stages, upgrades, deployment, and environment migration
- [mise architecture](docs/architecture/mise.md) — Configuration composition, ownership, platform extension, and runtime behavior
- [Project secrets](docs/secrets.md) — Fnox providers, task-scoped grants, and migration from plaintext environment files
- [dotf toolbox](docs/reference/dotf.md) — Daily utilities and project scaffolding
- [Tooling reference](docs/reference/tools.md) — Upstream documentation and discovery links, not an installation inventory

These guides are written for people; agents may consult relevant sections too.
[AGENTS.md](AGENTS.md) provides the agent entrypoint and task-based routes to
repository constraints under `docs/instructions/`. Shared facts do not need a
separate agent copy, and reading a guide does not authorize running its commands.
