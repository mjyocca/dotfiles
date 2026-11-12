# mise Configuration Architecture

This page maps repository-specific wiring, not installed-machine state. The
TOML files and `Makefile` are authoritative; consult upstream for mise semantics.
For operational procedures, see [commands and setup](../commands.md), including
[deployment](../commands.md#updating-existing-deployments) and
[project environment migration](../commands.md#migrating-project-environments-and-editor-setup).

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
| `conf.d/workspace.toml.example` | Sanitized optional private-repository declaration |
| `conf.d/workspace.toml` | Gitignored checkout provisioning, seeded only when missing |
| `workspace/opencode.jsonc.example` | Sanitized workspace-local OpenCode scaffold |
| `workspace/miserc.<platform>.toml` | Create-only source for the checkout's ignored `.miserc.local.toml` environment default |
| `miserc.toml` | Checkout discovery policy, also rendered globally; older global symlinks remain compatible |
| `omarchy/` | Omarchy hook scripts, theme templates, and user-override snippets deployed by the platform config |

The `global/` directory holds deployment sources, not another mise discovery
root. Native `conf.d` discovery composes the deployed files.

Deployment also seeds the checkout's ignored `opencode.jsonc` from
`workspace/opencode.jsonc.example`, and `conf.d/workspace.toml` from its adjacent example.
These and the platform-selected `.miserc.local.toml` seed are create-only copies:
existing files, symlinks, and local edits are left alone. The OpenCode example
relies on automatic `AGENTS.md` discovery and offers an optional local project
reference, not a skill source.

To opt into private checkout provisioning, first create the scaffolds with
`make link`, then edit the ignored workspace fragment locally. With the intended
platform selected, preview repository provisioning using
`mise -E <profile> bootstrap repos apply --dry-run` before applying it. Repository
cloning runs before dotfile creation, so a declaration added to the new fragment
takes effect on a later provisioning run. It does not execute the cloned
project's configuration or deploy its skills. Keep remote identities out of
tracked examples and leave `config.local.toml` for existing local overrides.

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
Each platform's deployment seeds `<repo>/.miserc.local.toml` with its environment.
mise reads this early file before discovering ordinary config, so direct commands
inside the checkout and its subdirectories inherit the platform when `-E` and
`MISE_ENV` are absent. This works in Bash, Zsh, and non-interactive invocations
without shell initialization. It selects mise's environment, not a parent-shell
export, and does not select a platform in unrelated projects.

Explicit `-E` and then `MISE_ENV` take precedence over the workspace default.
Shell startup does not set a default `MISE_ENV`; explicit exports remain valid.
Initial deployment needs Make's profile selection or explicit `-E`. The seed is
create-only: edit the ignored file locally to change an existing checkout's
default, rather than expecting another deployment to overwrite it. Environment
names alone do not perform OS or hostname detection.

Global tools and machine-local configuration still compose normally. Keep the
workspace selection out of `miserc.toml`: that discovery policy
deploys globally and must not impose this checkout's platform on other projects.
Do not assume workspace and global `miserc` environment defaults are combined on
every mise version. If a global environment profile must apply here too, include
it alongside the platform in the ignored workspace `env` list and verify
`mise config ls`. This is separate from always-loaded global config and fragments.

### Adding a platform later

Add `config.<profile>.toml` with that platform's complete package set and explicit
dotfile-group selection. Override shared deployment definitions only where needed.
Include a create-only workspace environment seed, following the existing platforms.
Duplication of package intent across platforms is acceptable; no environment map,
include chain, or custom configuration merger is needed.

Add `scripts/<profile>/prerequisites.sh`, `packages.sh`, `plugins.sh`, and `hooks.sh`.
Make invokes those entrypoints directly, with no implicit platform fallback. Each
entrypoint sources reusable functions from `scripts/shared/`, or explicitly sources
the corresponding `scripts/linux/` entrypoint. Override functions or compose shared
operations to add platform-specific behavior. `config.sh` is optional for additional
platform preferences; dotfiles always deploy in the separate `link` stage.

Sourcing an entrypoint defines functions but does not execute its stage. Keep the
call behind a `[[ "${BASH_SOURCE[0]}" == "$0" ]]` guard. Shared utility initialization
is guarded too, so composing multiple sources does not redefine readonly values.
For example, Omarchy's package interface sources the Linux interface, then replaces
`install_packages` with a function calling `install_system_packages` followed by
`install_aur_packages`. Its plugin and hook interfaces reuse Linux functions unchanged.

A new Linux distro's unchanged plugin entrypoint can be just:

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../linux/plugins.sh"

# Define install_plugins here only when this distro needs different behavior.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_plugins "$@"
fi
```

Inspect detection and prerequisite support, including how mise itself is installed.
Detection alone does not establish provisioning support. The Linux prerequisite
implementation has apt/dnf/pacman branches, but only macOS and Omarchy have complete
tracked provisioning configurations. A new distro needs an appropriate mise provider
as well as its package declarations; the shared installer currently installs missing
mise on macOS or pacman-based Linux, preserving an existing provider everywhere.

The default global tool overlay can be reused. Add a platform tool fragment and
override its deployment source only when providers or exclusions differ. Keep
these tool sources separate from repository-only bootstrap declarations.

## Installation and Bootstrap Lifecycle

macOS user preferences are native `[bootstrap.macos.defaults]` declarations in
`config.macos.toml`. `make config` applies only those preferences; the macOS
package layer runs only packages, without deployment, preferences, agents, or tools.
Direct full `mise bootstrap` includes declared preferences and agents. LaunchAgents
are native `[bootstrap.macos.launchd.agents]` declarations, not tracked plists. Explicit
`mise -E macos bootstrap macos launchd-agents apply` writes and loads them under
`dev.mise.*` labels. Inspect status and dry-run first, including legacy jobs with
different labels; removing a declaration does not unload an installed agent.

| Context | Loaded scope |
|---|---|
| Repository management (`make packages`, `make repos`, `make link`) | Global tools plus repository provisioning rules and the selected platform environment, with each command applying only its stage |
| `make tools` | Normal effective requests, including machine-local additions and project overrides; requires deployed global fragments and discovery policy |
| Everyday use outside this repository | System and user-global configuration, plus configuration discovered for the current project |

Make owns stage ordering; see [workflows](../commands.md#workflows) and
[individual stages](../commands.md#individual-stages) for sequences and operational
boundaries. Deployment precedes tool installation so mise can discover the global
tool fragments and `.tool-versions` policy. Scripts pin mise operations to the
repository root rather than interactive shell state. Repository application can
enforce a configured ref without requesting the separate repository update operation.

## Global Deployment and Overrides

Deployment links tool fragments and renders the machine discovery policy:

```text
~/.config/mise/                        Source in <repo>/.config/mise/
  conf.d/
    10-dotfiles-tools.toml ──────────► global/tools.toml
    20-dotfiles-platform.toml ───────► global/platform[.omarchy].toml
  config.toml                         Existing machine configuration, preserved
  config.local.toml                   Optional untracked machine overrides
  miserc.toml                         Rendered from miserc.toml
```

Bootstrap and deployment rules are not loaded globally. Check links on the target
machine to confirm deployment.

The existing global `config.toml` overrides the tracked fragments; deployment
never rewrites it or machine-local overrides. Do not treat `mise use -g` as an edit
to tracked declarations. Consult upstream [configuration discovery and precedence](https://mise.jdx.dev/configuration.html#configuration-hierarchy)
and inspect effective configuration for the target machine.

## Machine Scope and Runtime Ownership

- **Platform:** `config.macos.toml` and `config.omarchy.toml` are environment
  selections, not hostname overlays. No automatic machine-overlay loader exists.
- **Machine:** the preserved `~/.config/mise/config.toml` is machine-local.
- **Checkout:** `<repo>/.config/mise/config.local.toml` configures this checkout's
  provisioning and deployment. It is distinct from the user-global file with the
  same basename.
- **Boundary:** provisioning files contain no machine-specific tool requests.
  Put machine-specific requests in global local configuration, not a platform file.
- **Project:** `mise.toml` declares shared tools and environments; an ignored
  `mise.local.toml` overrides them for one checkout on one machine.
- **Runtimes:** mise reads `.tool-versions` and explicit TOML tool requests. Asdf
  and direnv remain installed dependencies, not automatic runtime or environment
  providers. Existing asdf installations are not reused by mise.

### Runtimes and project environments

Both shells use full mise activation for interactive runtime and environment
updates. No direnv hook, asdf completion/plugin initialization, or global asdf
version-export mechanism is registered. Legacy ownership preferences have no effect.

Zsh activates mise in `.zshrc`; standalone Bash activates it in the interactive
portion of `.bashrc`, which `.bash_profile` also sources. Activation adds real
tool paths. Non-interactive startup does not inject shims ahead of inherited
paths, so child shells retain the launching runtime even when their working
directory changes. Machine-local shell overrides remain last.

Ordinary non-interactive Bash does not automatically read `.bashrc`. Scripts
inherit PATH or use `mise exec -- <command>` to resolve a project explicitly.
Omarchy's upstream Bash defaults already activate mise; the local startup does
not wrap that invocation or activate it a second time. Verify actual startup
against the installed Omarchy version.

Shell startup and discovery policy must deploy together. Native dependencies order
selected entries without expanding a scoped apply. The command guide owns
[scoped previews](../commands.md#scoped-previews) and
[complete deployment and tool installation](../commands.md#updating-existing-deployments),
including collision checks and fresh-shell verification.

### Migrating project environments and editor setup

Project environments and editor processes use mise's runtime ownership described
above; neither platform automatically loads `.envrc`. Follow the
[migration procedure](../commands.md#migrating-project-environments-and-editor-setup)
for exports, PATH, legacy consumers, and editor launch behavior. For optional
task-scoped secrets, see the [project secrets guide](../secrets.md); dotfiles
deployment does not configure a project's providers or grant its secrets.

## Official Documentation

- [Configuration and discovery](https://mise.jdx.dev/configuration.html)
- [Configuration environments](https://mise.jdx.dev/configuration/environments.html)
- [Dotfiles](https://mise.jdx.dev/dotfiles.html)
- [macOS preferences](https://mise.jdx.dev/bootstrap/macos-defaults.html)
- [macOS LaunchAgents](https://mise.jdx.dev/bootstrap/launchd.html)
- [Project environments](https://mise.jdx.dev/environments/)
- [asdf plugin backend](https://mise.jdx.dev/dev-tools/backends/asdf.html)

For agent safety and verification, see [deployment instructions](../instructions/mise-dotfiles.md)
and [package ownership policy](../instructions/package-management.md).
