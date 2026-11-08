```text
 ____            __       ___      ___
/\  _`\         /\ \__  /'___\ __ /\_ \
\ \ \/\ \    ___\ \ ,_\/\ \__//\_\\//\ \      __    ____
 \ \ \ \ \  / __`\ \ \/\ \ ,__\/\ \ \ \ \   /'__`\ /',__\
  \ \ \_\ \/\ \L\ \ \ \_\ \ \_/\ \ \ \_\ \_/\  __//\__, `\
   \ \____/\ \____/\ \__\\ \_\  \ \_\/\____\ \____\/\____/
    \/___/  \/___/  \/__/ \/_/   \/_/\/____/\/____/\/___/
```

Dotfiles managed with [mise](https://mise.jdx.dev/dotfiles.html).
Shared for inspiration, not as a universal setup. **Use at your own risk:**
bootstrap installs software and changes
your configuration. Review the declarations and existing dotfiles before running.

## Install

```bash
git clone https://github.com/mjyocca/dotfiles.git ~/dotfiles
cd ~/dotfiles
make bootstrap
```

Git and Make must be available to start; bootstrap handles the remaining platform
prerequisites. See [setup notes](docs/commands.md#setup-notes) for fresh machines.

## Everyday use

```bash
make sync
```

Installs declared packages, provisions optional repositories, deploys dotfiles,
and installs tools and plugin integrations. Update this checkout with Git first
when you want newer declarations; sync does not pull it for you.

See the [command reference](docs/commands.md) for individual stages and previews.

## Architecture

```text
dotfiles/
├── Makefile                     Lifecycle ordering + platform selection
├── .config/mise/                Declarative provisioning + deployment
│   ├── config.toml              Shared dotfile definitions
│   ├── config.<platform>.toml   Platform packages, settings + deployment rules
│   └── global/                 Tools deployed into user-global mise config
│       ├── tools.toml           Shared development tools
│       └── platform*.toml       Platform providers + exclusions
├── packages/                    Application dotfiles deployed by mise
│   └── aur/                     AUR package lists consumed by scripts
└── scripts/                     Stage wrappers + setup outside mise
    ├── shared/                  Reusable implementations + mise calls
    ├── linux/                   Reusable Linux stage implementations
    └── <platform>/              Platform entrypoints + extensions
```

- **System packages:** mise manages Homebrew on macOS and Pacman on Omarchy;
  scripts handle interactive AUR installation.
- **Platform configuration:** mise applies macOS defaults and deploys
  Omarchy settings, theme templates, and hooks.
- **Tools:** global mise configuration supplies development tools everywhere;
  asdf owns language runtimes.
- **Plugins and hooks:** scripts install TPM, asdf plugins, gh-dash, a Zellij
  plugin, and the repository's Gitleaks hook.

See [mise configuration architecture](docs/architecture/mise.md) for environment
selection, local overrides, and platform composition.
