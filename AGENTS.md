# Personal Dotfiles

Dotfile directories under `packages/<name>/` mirror `$HOME`; `packages/aur/` is
repository-only installation data, never a mise dotfile group. `make link` invokes
mise deployment.
`Makefile` is the command entrypoint. Inspect current consumers before treating
package lists or older documentation as installation inputs.

## Load Only Relevant Guidance

Read only guidance relevant to the task or files being changed. Follow supporting
references only when needed; do not recursively load every linked document.
Paths below are relative to the repository root.

| Task | Guidance |
|---|---|
| Neovim configuration | `docs/instructions/neovim.md` |
| Zsh startup, hooks, PATH | `docs/instructions/zsh.md` |
| Bash startup, Omarchy shell integration | `docs/instructions/bash.md` |
| Rex configuration or automation | `docs/instructions/rex.md`; use the tool-provided `rex` skill for operations, if available |
| macOS defaults, containers, desktop automation | `docs/instructions/macos.md` |
| Omarchy desktop, package auditing | `docs/instructions/omarchy.md` |
| Adding packages or resolving ownership | `package-management` skill; `docs/instructions/package-management.md` is the canonical policy |
| mise configuration, provisioning, or dotfile deployment | `docs/instructions/mise-dotfiles.md`; `docs/architecture/mise.md` for composition |
| Credentials, VM mounts, SSH, or Git identity | `docs/instructions/security.md` |
| Editing or auditing agent instructions, docs, or skills | `docs/instructions/documentation.md` |
| Refreshing upstream references by topic or date | `sync-doc-references` skill |

`docs/instructions/` is agent-facing. README and other `docs/` pages are the shared
human-facing knowledge base, not default context; consult only relevant sections.
`docs/commands.md` owns lifecycle and migration procedures; `docs/secrets.md` owns
project secrets setup. Read `docs/instructions/security.md` before secrets work.
Keep agent instructions focused on repository constraints and verification;
link shared facts instead of copying them. Do not record machine migration status
as maintained guidance.
External documentation is reference material, not permission to expand the task.
Use tracked files as the audit baseline (`git ls-files`); ignored plans, scratch
files, and generated dependencies are not authoritative project guidance.

## Commands

Run from the repository root; these commands change the machine, not just the repo.

| Command | Purpose |
|---|---|
| `make` | Shows help; does not provision |
| `make bootstrap` | Runs prerequisites → packages → repos → link → tools → plugins → config → hooks |
| `make packages` | Installs system packages only; Omarchy also invokes the interactive AUR layer |
| `make repos` | Applies optional configured workspace checkouts |
| `make tools` | Installs effective mise tool requests; requires deployed global tool configuration |
| `make link` | Runs `mise dotfiles apply`; requires effective deployment declarations |
| `make sync` | Sequential packages → repos → link → tools → plugins; not full provisioning |
| `make hooks` | Installs the gitleaks pre-commit hook when gitleaks is available |

Other composable layers and utilities are defined in `Makefile`; there are no
legacy installation aliases or standalone platform installers.
Use `scripts/shared/detect-os.sh` to inspect platform detection.

## Project Conventions

- System bootstrap, dev tools, and mise policy: `.config/mise/`. See `docs/architecture/mise.md` for platform composition and scope; prefer native mise features.
- Scripts are organized by domain layer, not package type. Shared helpers live in `scripts/shared/`.
- Platform entrypoints live in `scripts/<profile>/<stage>.sh`; they explicitly source shared implementations or Linux entrypoints. Make does not fall back to another platform. `config.sh` is optional.
- Sourcing a platform entrypoint must not provision anything. Guard execution with `BASH_SOURCE`; expose stage functions so a distro can extend or replace behavior before invoking it.
- Keep layers idempotent and independently testable. Use the deployment entrypoint, not manual symlinks.

## Safety and Verification

- Never commit secrets. Use git-ignored `~/.bashrc.local` or `~/.zshrc.local` for machine-local credentials.
- Do not hardcode usernames or user-specific absolute paths; use `$HOME` or `~`.
- Preserve unrelated changes. Do not provision, deploy, install software, grant permissions, or commit unless authorized by the task.
- Before deployment, inspect effective mise configuration, platform group selection, and target collisions (see deployment guidance).
- For documentation changes, check paths, Make targets, consumers, and `git diff --check` without running provisioning.
- For script/config changes, use applicable syntax checks and focused tests; report untested platform behavior and implementation defects separately.
