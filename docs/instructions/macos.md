# macOS Conventions

Use for macOS integration, defaults, containers, and desktop automation. Load
`docs/instructions/zsh.md` only for shell changes; for package changes consult the
canonical `docs/instructions/package-management.md` policy.

## Configuration Sources

- `.config/mise/config.macos.toml` adds platform system packages to the shared
  `.config/mise/config.toml` bootstrap declarations. Formulas use `brew:`, casks
  use `brew-cask:` under `[bootstrap.packages]`.
- Shared dev tools and interim asdf runtime versions have separate declarations
  identified in the package policy; runtime migration to mise is not complete.
- `scripts/macos/config.sh` uses `apply-user-defaults`, when available, with
  `.config/macos/defaults.yml` and `.config/macos/defaults.apps.yml`, resolved
  relative to the repository rather than the caller's working directory.
  `make config` (also `make apply_settings`) applies them; it is not a read-only
  validation command and may skip defaults if the utility or input files are absent.
- `.config/macos/` is repository-only configuration, not a mise dotfile deployment
  source. Its `launchagents/` directory retains inactive plist files; no tracked
  step installs or loads them. The SSH key loader's `/var/log/addssh/` logging
  path needs review before any future activation.
- User configuration uses XDG paths under `~/.config/`; LaunchAgents live under
  `~/Library/LaunchAgents/`. Discover the Homebrew prefix with `brew --prefix`
  rather than assuming an Apple Silicon or Intel installation path.

## Containers and Virtualization

Colima is the preferred Docker runtime here, with Lima providing the VM layer.
`packages/colima/.config/colima/_templates/default.yaml` selects `vmType: vz`
(Apple's Virtualization framework) and `mountType: virtiofs`. This describes the
template, **not** the effective backend of every existing profile. Inspect a
profile before changing it; template edits do not prove an existing VM migrated.

Review host mounts and their write access before running untrusted workloads.
Neither a VM backend nor container use alone establishes safe isolation from
mounted host files. See `docs/reference/security.md` for local mount considerations.

- [Apple Virtualization framework](https://developer.apple.com/documentation/virtualization)
- [Colima](https://github.com/abiosoft/colima)
- [Lima VM backends](https://lima-vm.io/docs/config/vmtype/)

## Agentic Tooling

[Vercel Labs agent-desktop](https://github.com/vercel-labs/agent-desktop) provides
desktop automation through the OS accessibility tree. Before use, consult its
upstream instructions and version-matched desktop/platform guides. Accessibility
access requires user approval; snapshots, screenshots, clipboard reads, and debug
artifacts may expose private content. Keep them out of public logs and uploads.

This reference is not authorization to install tooling, grant permissions, or
operate desktop apps. Accessibility automation does not itself provide VM isolation.

## Platform Boundaries

Respect macOS privacy permissions and protected system paths; do not bypass them
to make automation work. For platform behavior, consult the relevant section of
[Apple documentation](https://developer.apple.com/documentation/), the
[macOS User Guide](https://support.apple.com/guide/mac-help), or
[Homebrew documentation](https://docs.brew.sh/) rather than maintaining local manuals.
