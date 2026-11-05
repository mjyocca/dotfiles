# mise Configuration Architecture

This page maps repository-specific wiring, not installed-machine state. The
TOML files and `Makefile` are authoritative; consult upstream for mise semantics.

## File Roles

All source files below live in `<repo>/.config/mise/`.

| File | Role |
|---|---|
| `global/tools.toml` | Shared user-global development tools, without runtime requests |
| `global/platform.toml` | No platform overrides; shared defaults for macOS and other platforms |
| `global/platform.omarchy.toml` | Omarchy provider selections and exclusions |
| `config.toml` | Platform-neutral dotfile definitions and deployment defaults |
| `config.macos.toml` | Complete macOS package set, Brew policy, preferences, LaunchAgents, and dotfile selections |
| `config.omarchy.toml` | Complete Omarchy package set and deployment overrides |
| `config.local.toml` | Gitignored checkout-local overrides |
| `config.<environment>.local.toml` | Optional gitignored checkout overrides for one platform |
| `miserc.toml` | Early discovery policy leaving `.tool-versions` to asdf |
| `macos/` | Reserved for future macOS supporting files; retained with `.gitkeep` |
| `omarchy/` | Omarchy hook scripts, theme templates, and user-override snippets deployed by the platform config |

The `global/` directory holds deployment sources, not another mise discovery
root. Native `conf.d` discovery composes the deployed files.

Omarchy deployment declarations stay in `config.omarchy.toml`, grouped by hooks
and user overrides. Their contents live in `omarchy/hooks/`, `omarchy/themed/`,
and `omarchy/user-overrides/`. User-override snippets are rendered into managed
blocks, preserving the rest of the target file.

### Herdr desktop theme integration

The Omarchy platform deploys a user template under `~/.config/omarchy/themed/`
and a `theme-set.d` publishing hook. Omarchy renders the template from the active
palette during a theme switch; the hook validates and atomically publishes the
rendered JSON as Herdr's `themes/omarchy.json`. Herdr derives interface colors
from that palette and reloads it live. Generated palettes are not tracked.

Select Omarchy once in Herdr's theme picker (or run
`herdr-app do app.theme --name omarchy` with Herdr open). Theme switches never
rewrite preferences or reselect the theme. This bridge can be retired when the
installed Omarchy provides its native Herdr desktop integration.

## Shared and Platform Composition

```text
Repository provisioning                 User-global tool composition

config.toml                            global/tools.toml
  + selected environment                 + selected platform fragment
    config.macos.toml OR                    global/platform.toml OR
    config.omarchy.toml                     global/platform.omarchy.toml
  + checkout-local overrides               ↓ deployed as conf.d symlinks
    config.local.toml                    same defaults in every directory
```

macOS uses shared tools unchanged. Omarchy selects its platform fragment through
a deployment override, so the choice persists outside the repository without
requiring a shell environment variable. Platform group selections separately
choose which application configs deploy.

Make detects `PROFILE` unless explicitly supplied, and defaults `MISE_ENV` to
that profile. Provisioning targets reject a missing platform file or a conflicting
`MISE_ENV` before running their recipes. Each profile selects one independent
environment; Omarchy does not inherit an Arch environment.
Direct mise commands require the intended environment, for example
`mise -E omarchy config ls`. The repository's Zsh startup defaults to `macos`;
mise environment names alone do not perform OS or hostname detection.

### Adding a platform later

Add `config.<profile>.toml` with that platform's complete package set and explicit
dotfile-group selection. Override shared deployment definitions only where needed.
Duplication of package intent across platforms is acceptable; no environment map,
include chain, or custom configuration merger is needed.

Inspect detection and prerequisite support, including how mise itself is installed.
Detection alone does not establish provisioning support. Generic Linux bootstrap
and incremental targets both prefer `scripts/<profile>/<layer>.sh`, falling back
to `scripts/linux/<layer>.sh`; add overrides only for actual platform differences.
macOS and Omarchy retain their dedicated bootstrap flows.

The default global tool overlay can be reused. Add a platform tool fragment and
override its deployment source only when providers or exclusions differ. Keep
these tool sources separate from repository-only bootstrap declarations.

## Installation and Bootstrap Lifecycle

macOS user preferences are native `[bootstrap.macos.defaults]` declarations in
`config.macos.toml`. `make config` applies only those preferences; the macOS
package layer skips defaults and LaunchAgents as well as tools. Direct full
`mise bootstrap` includes declared preferences and agents. LaunchAgents are native
`[bootstrap.macos.launchd.agents]` declarations, not tracked plists. Explicit
`mise -E macos bootstrap macos launchd-agents apply` writes and loads them under
`dev.mise.*` labels. Inspect status and dry-run first, including legacy jobs with
different labels; removing a declaration does not unload an installed agent.

| Context | Loaded scope |
|---|---|
| Repository management (`make link`, package bootstrap) | Global tools plus repository provisioning rules and the selected platform environment |
| `make tools` | Normal effective requests, including machine-local additions and project overrides; requires deployed global fragments and discovery policy |
| Everyday use outside this repository | System and user-global configuration, plus configuration discovered for the current project |

Fresh bootstrap runs prerequisites (install/reuse mise), packages and configuration
deployment, tools, plugins, platform settings, then hooks. Package bootstrap skips
tool installation so the global fragments and discovery policy deploy first.
`make sync` sequentially runs packages → link → tools → plugins, even under `make -j`.
Neither workflow implicitly transfers asdf runtimes to mise. Installation is not
an explicit upgrade or removal operation.

## Global Deployment and Overrides

The declared deployment links only tool fragments and discovery policy globally:

```text
~/.config/mise/                        Source in <repo>/.config/mise/
  conf.d/
    10-dotfiles-tools.toml ──────────► global/tools.toml
    20-dotfiles-platform.toml ───────► global/platform[.omarchy].toml
  config.toml                         Existing machine configuration, preserved
  config.local.toml                   Optional untracked machine overrides
  miserc.toml ──────────────────────► miserc.toml
```

Bootstrap and deployment rules are not loaded globally. A declaration does not
prove a link is deployed: inspect the target machine rather than recording
deployment status here.

The existing global `config.toml` overrides the tracked fragments; deployment
never rewrites it or machine-local overrides. Do not treat `mise use -g` as an edit
to tracked declarations. Consult upstream [configuration discovery and precedence](https://mise.jdx.dev/configuration.html#configuration-hierarchy)
and inspect effective configuration rather than relying on a copied precedence list.

## Machine Scope and Runtime Ownership

- **Platform:** `config.macos.toml` and `config.omarchy.toml` are environment
  selections, not hostname overlays. No automatic machine-overlay loader exists.
- **Machine:** the preserved `~/.config/mise/config.toml` is machine-local.
- **Checkout:** `<repo>/.config/mise/config.local.toml` affects this checkout only.
  It is distinct from the user-global file with the same basename.
- **Boundary:** provisioning files contain no machine-specific tool requests.
  Put machine-specific requests in global local configuration, not a platform file.
- **Runtimes:** asdf reads `.tool-versions`; mise's deployed `miserc.toml` disables
  that discovery without disabling explicit TOML tool requests. Managing the asdf
  executable with mise does not transfer runtime ownership.

## Official Documentation

- [Configuration and discovery](https://mise.jdx.dev/configuration.html)
- [Configuration environments](https://mise.jdx.dev/configuration/environments.html)
- [Dotfiles](https://mise.jdx.dev/dotfiles.html)
- [macOS preferences](https://mise.jdx.dev/bootstrap/macos-defaults.html)
- [macOS LaunchAgents](https://mise.jdx.dev/bootstrap/launchd.html)
- [asdf version selection](https://asdf-vm.com/manage/configuration.html)

For agent safety and verification, see [deployment instructions](../instructions/mise-dotfiles.md)
and [package ownership policy](../instructions/package-management.md).
