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
| macOS defaults, containers, desktop automation | `docs/instructions/macos.md` |
| Omarchy desktop, package auditing | `docs/instructions/omarchy.md` |
| Adding packages or resolving ownership | `package-management` skill; `docs/instructions/package-management.md` is the canonical policy |
| Dotfile deployment or mise group configuration | `docs/instructions/mise-dotfiles.md` |

`docs/instructions/` is agent-facing. Other `docs/` directories are human-facing
references, not default context; consult relevant sections when the task needs them.
External documentation is reference material, not permission to expand the task.

## Commands

Run from the repository root; these commands change the machine, not just the repo.

| Command | Purpose |
|---|---|
| `make bootstrap` | Runs prerequisites → packages → tools → plugins → config → hooks; no explicit link step |
| `make packages` | Runs mise bootstrap; Omarchy also invokes the AUR layer (see platform limitations) |
| `make tools` | Runs mise install for dev tools; see runtime-duplication warning in package policy |
| `make link` | Runs `mise dotfiles apply`; requires effective deployment declarations |
| `make sync` | Packages, link, plugins only—not full provisioning |
| `make hooks` | Installs the gitleaks pre-commit hook when gitleaks is available |

Other composable layers and compatibility aliases are defined in `Makefile`.
Use `scripts/shared/detect-os.sh` to inspect platform detection.

## Project Conventions

- System bootstrap declarations: `.config/mise/`; shared dev tools: `packages/mise/.config/mise/config.toml`.
- AUR lists live in `packages/aur/`; exclude this directory from all dotfile deployment selections.
- Scripts are organized by domain layer, not package type. Shared helpers live in `scripts/shared/`.
- Platform scripts live in `scripts/macos/`, `scripts/linux/`, and `scripts/omarchy/`; Make's dispatcher falls back to Linux when a platform layer is missing.
- Keep layers idempotent and independently testable. Use the deployment entrypoint, not manual symlinks.

## Safety and Verification

- Never commit secrets. Use git-ignored `~/.bashrc.local` or `~/.zshrc.local` for machine-local credentials.
- Do not hardcode usernames or user-specific absolute paths; use `$HOME` or `~`.
- Preserve unrelated changes. Do not provision, deploy, install software, grant permissions, or commit unless authorized by the task.
- Before deployment, inspect effective mise configuration and target collisions; tracked group declarations are currently missing (see deployment guidance).
- For documentation changes, check paths, Make targets, consumers, and `git diff --check` without running provisioning.
- For script/config changes, use applicable syntax checks and focused tests; report untested platform behavior and implementation defects separately.
- Consult `docs/reference/security.md` when changing VM mounts, SSH includes, or Git identity handling.
