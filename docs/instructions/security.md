# Security Constraints

## Sensitive Local Files

- Agents must never read, search contents, print, or source real machine- or
  project-local files that may contain secrets or sensitive information. This
  includes `.bashrc.local`, `.zshrc.local`, other shell-local overrides, `.env`,
  `.env.*`, `.envrc`, local mise/fnox configuration, and credential stores.
  Treat these files as sensitive without opening them to check. Tracking or ignore
  status does not establish that their contents are safe.
- Do not bypass this restriction through symlinks, broad content searches,
  subprocesses, shell startup, hooks, or environment loaders. Scope searches to
  reviewed source files and exclude private files before reading content.
- Use synthetic fixtures, placeholder-only tracked templates, or narrowly scoped
  redacted excerpts supplied by the user. If private settings are needed, ask the
  user to perform the check and provide redacted results; do not open the file.
- Path/existence, permissions, symlink-target, and Git tracking/ignore checks are
  allowed without reading contents. Use `mise config ls` only for configuration
  selection metadata; never dump resolved environments with `mise env`, `env`,
  `printenv`, or shell tracing that could expose inherited secrets.
- Shell tests must use an isolated fixture with synthetic startup files and no
  access to real local overrides or dotenv files. Isolate home/config paths and
  startup variables such as `BASH_ENV`, `ENV`, and `ZDOTDIR`; disable hooks or
  loaders that reach outside the fixture. If isolation cannot be assured, stop
  at static checks and report runtime validation as not performed.

## Credentials and Local Overrides

- Keep credentials in git-ignored shell-local overrides or the tool's credential
  store, never shared configuration. Use `$HOME` or `~`, not user-specific paths.
- Preserve Git-filtered deployment manifests and ignore machine-local files in
  the source tree. Inspect effective deployment scope before assuming a file is excluded.
- Before writing private values to a local mise override, verify the destination
  is ignored with `git check-ignore` and is not already tracked. A `.local.toml`
  suffix alone does not protect a file from commits.
- Enter SSH key passphrases only through interactive prompts, never environment
  variables, command arguments, or key comments. Do not overwrite existing keys.
  If the old `scripts/github-ssh.sh` helper was used with a real `SSH_PASSPHRASE`,
  treat it as exposed through terminal output and the public key's comment.

## SSH and Git Identity

- Keep runtime-generated SSH includes and machine-specific hosts out of the tracked
  SSH template. Preserve them locally through supported overrides; do not remove
  working runtime configuration merely to clean the repository.
- Use GitHub's noreply address for tracked Git identity; keep personal email
  addresses in local overrides.

## VM Mounts

Scope mounts to required project directories and prefer read-only access where
possible. Do not expose `/Users` or an entire home directory to a VM. Inspect
effective mounts and write permissions; a VM backend alone does not isolate
credentials or configuration in mounted host files.

## Secret Scanning

- Run Gitleaks before an authorized push. Check `.gitleaks.toml`, the installed
  CLI's help, and [upstream guidance](https://github.com/gitleaks/gitleaks).
- Hook installation does not prove scanning is enforced. Verify the active hook
  and scan outcome; missing scanners and scan errors must block the commit.
- Preserve unfamiliar hooks and never write through an existing hook symlink.
- Redact scan output before sharing it. Do not bypass a failed scan to commit.
