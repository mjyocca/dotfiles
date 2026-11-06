# Security Constraints

## Credentials and Local Overrides

- Keep credentials in git-ignored shell-local overrides or the tool's credential
  store, never shared configuration. Use `$HOME` or `~`, not user-specific paths.
- Preserve Git-filtered deployment manifests and ignore machine-local files in
  the source tree. Inspect effective deployment scope before assuming a file is excluded.
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
