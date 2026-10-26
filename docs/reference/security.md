# Security Practices

Learnings from a security audit of this repo. Apply these when adding or modifying any package config.

## Never commit secrets or credentials

- Secrets, API keys, and tokens belong in `~/.zshrc.local` (git-ignored)
- Never put real values in `.zshenv` or `.zshrc` — those are committed
- The `.zshrc.local` bootstrap in `.zshrc` exists specifically for this

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

- `.stow-ignore.local` — machine-specific package ignore list
- `packages/zsh/.zshrc.local` — machine-specific shell overrides
- `packages/zsh/.global_env.sh` — legacy, replaced by `.zshrc.local`

## Gitleaks — secret scanning

**Automatic:** Pre-commit hook scans staged changes on every `git commit`. Install with `make install_git_hooks`.

**Manual usage:**

```bash
# Scan staged changes (what the pre-commit hook does)
gitleaks protect --staged

# Scan entire repository history
gitleaks detect --source . --log-level info

# Scan specific commit
gitleaks detect --source . --commit <sha>

# Scan uncommitted changes (working directory)
gitleaks protect --verbose

# Scan a specific file or directory
gitleaks dir <path>
```

**When to use manually:**
- Before pushing to verify no secrets in recent commits
- When reviewing a PR from another contributor
- To audit repository history after adding new sensitive files
- To scan a specific branch: `gitleaks detect --source . --log-opts <branch>..HEAD`

**Configuration:** `.gitleaks.toml` in repo root (allowlists specific paths, custom patterns)
