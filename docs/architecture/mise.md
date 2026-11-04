# mise Configuration Architecture

This page maps repository-specific wiring, not installed-machine state. The
TOML files and `Makefile` are authoritative; consult upstream for mise semantics.

## File Roles

All source files below live in `<repo>/.config/mise/`.

| File | Role |
|---|---|
| `tools.toml` | Shared development tools, without runtime requests |
| `tools.omarchy.toml` | Omarchy-specific tool provider selections |
| `global.toml` | Tools-only entrypoint including shared tools |
| `global.omarchy.toml` | Tools-only entrypoint including shared then Omarchy tools |
| `config.toml` | Shared bootstrap packages and dotfile definitions; includes shared tools |
| `config.macos.toml` | macOS packages and dotfile selections |
| `config.omarchy.toml` | Omarchy packages, deployment overrides, and additional tool requests |
| `config.local.toml` | Gitignored checkout-local overrides |
| `miserc.toml` | Early discovery policy leaving `.tool-versions` to asdf |

`global*.toml` are repository naming conventions, not automatically discovered
mise filenames. Both Omarchy entrypoints maintain matching `disable_tools`
settings; included files cannot contain settings.

## Shared and Platform Composition

```text
Repository management                  Tools-only entrypoints

config.toml                            global.toml                 [macOS]
  └─ include tools.toml                   └─ include tools.toml
       +
config.macos.toml       [macOS]         global.omarchy.toml          [Omarchy]
       OR                                ├─ include tools.toml
config.omarchy.toml     [Omarchy]         └─ include tools.omarchy.toml
  └─ include tools.omarchy.toml
       +
config.local.toml       [checkout-local, when present]
```

macOS uses shared tools unchanged, so it has no `tools.macos.toml` or
`global.macos.toml`. Platform group selections choose which shared application
configs deploy; a shared source does not imply deployment on every platform.

Make detects `PROFILE` unless explicitly supplied, and defaults `MISE_ENV` to
that profile. An existing `MISE_ENV` is preserved: check that both agree.
Direct mise commands require the intended environment, for example
`mise -E omarchy config ls`. The repository's Zsh startup defaults to `macos`;
mise environment names alone do not perform OS or hostname detection.

## Three Loading Contexts

| Context | Loaded scope |
|---|---|
| Repository management (`make link`, package bootstrap) | Normal mise discovery plus the selected platform environment; includes deployment/package rules |
| `make tools` | Explicit tools-only entrypoint; excludes ambient global/system and parent-checkout configuration |
| Everyday use outside this repository | System and user-global configuration, plus configuration discovered for the current project |

`make tools` selects `global.<PROFILE>.toml` if present, otherwise `global.toml`.
Make scopes its global/system config inputs and directory discovery to isolate
installation. Additional requests in `config.omarchy.toml` are outside this scope.

## Global Deployment and Precedence

The declared deployment links only the tools layer into user-global configuration:

```text
~/.config/mise/                  Source in <repo>/.config/mise/
  config.toml                   Existing machine config, preserved
  config.local.toml ──────────► global.toml OR global.omarchy.toml
  tools.toml ────────────────► tools.toml
  tools.omarchy.toml ────────► tools.omarchy.toml       [Omarchy]
  miserc.toml ───────────────► miserc.toml
```

Included tool files deploy before the entrypoint. Bootstrap and deployment rules
are not loaded globally. A declaration does not prove a link is deployed: inspect
the target machine rather than recording deployment status here.

Relevant normal precedence, low to high (not every supported mise filename):

```text
system configuration
  → ~/.config/mise/config.toml
  → ~/.config/mise/config.local.toml
  → <repo>/.config/mise/config.toml
  → <repo>/.config/mise/config.<environment>.toml
  → <repo>/.config/mise/config.local.toml
```

This repository's layers apply when discovered from its directory tree. Other
projects supply their own layers; nested projects can add further configuration.
Matching tool keys override earlier requests; distinct provider keys may coexist.

## Machine Scope and Runtime Ownership

- **Platform:** `config.macos.toml` and `config.omarchy.toml` are environment
  selections, not hostname overlays. No automatic machine-overlay loader exists.
- **Machine:** the preserved `~/.config/mise/config.toml` is machine-local.
- **Checkout:** `<repo>/.config/mise/config.local.toml` affects this checkout only.
  It is distinct from the user-global file with the same basename.
- **Current boundary:** `config.omarchy.toml` also contains tool requests that
  originated on one machine. They apply wherever that environment is selected;
  they are not hostname-scoped and are not copied into the tools-only global layer.
- **Runtimes:** asdf reads `.tool-versions`; mise's deployed `miserc.toml` disables
  that discovery without disabling explicit TOML tool requests. Managing the asdf
  executable with mise does not transfer runtime ownership.

## Official Documentation

- [Configuration and discovery](https://mise.jdx.dev/configuration.html)
- [Configuration environments](https://mise.jdx.dev/configuration/environments.html)
- [Dotfiles](https://mise.jdx.dev/dotfiles.html)
- [asdf version selection](https://asdf-vm.com/manage/configuration.html)

For agent safety and verification, see [deployment instructions](../instructions/mise-dotfiles.md)
and [package ownership policy](../instructions/package-management.md).
