# Security Practices

Learnings from a security audit of this repo. Apply these when adding or modifying any package config.

## Never commit secrets or credentials

- Secrets, API keys, and tokens belong in git-ignored `~/.zshrc.local` or `~/.bashrc.local`
- Never put real values in shared shell startup files — those are committed
- Both interactive shell configs bootstrap and source their local override file
- `scripts/github-ssh.sh` accepts passphrases only through ssh-keygen's interactive
  prompt, not `SSH_PASSPHRASE`, command arguments, or key comments. Existing key
  paths are never overwritten. If the old helper was used with a real passphrase,
  treat it as exposed through terminal output and the public key's comment.

## Never hardcode usernames or absolute paths

- Always use `$HOME` or `~` — never `/Users/<name>/...`
- Hardcoded paths break on other machines and leak identity in public repos

## Scope VM mounts tightly

- Do not mount `/Users` (entire home directory) into a VM — it grants every process in the VM read/write access to `~/.ssh`, `~/.aws`, `~/.config`, etc.
- Scope colima mounts to specific project directories (e.g. `~/code`)
- Mounts in colima are mutable post-creation via `~/.colima/<profile>/colima.yaml`

## Do not commit runtime SSH includes

- OrbStack and similar tools auto-inject `Include` directives into `~/.ssh/config`
- These reference runtime-generated files with internal hostnames and VM IPs
- Remove any auto-injected `Include` stanzas before committing `packages/ssh/.ssh/config`

## Keep git config email private

- Use GitHub's noreply address format: `<id>+<username>@users.noreply.github.com`
- Never commit a real personal email address in `packages/gitconfig/.gitconfig`

## git-ignore all per-machine local files

- Keep shell-local overrides ignored, including `packages/zsh/.zshrc.local` and `packages/bash/.bashrc.local` when they reside in the source tree
- Dotfile groups use `manifest = "git"`; preserve this filtering and check effective configuration before assuming ignored files cannot be deployed
- `.stow-ignore.local` and `packages/zsh/.global_env.sh` are legacy conventions, not current deployment configuration

## Gitleaks — secret scanning

`make hooks` links the canonical `.githooks/pre-commit` only when gitleaks is
available. It resolves Git's hooks directory (including worktrees and
`core.hooksPath`), preserves matching hooks, and refuses unfamiliar existing hooks.
The hook invokes `gitleaks protect --staged --redact --verbose` and skips scanning
with a warning if the binary is missing. Installation is not proof every commit is
scanned; inspect the active hook and installed CLI compatibility when auditing
enforcement. Never write through an existing hook symlink to replace its source.

For manual scans, consult the installed version's help and
[upstream Gitleaks guidance](https://github.com/gitleaks/gitleaks) instead of copying
version-sensitive command recipes. Check `.gitleaks.toml` in the repository root
for local allowlists and patterns. Review scan output for secrets before sharing it.
