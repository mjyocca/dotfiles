# macOS Conventions

Use for macOS integration, defaults, containers, and desktop automation. Load
`docs/instructions/zsh.md` only for shell changes; for package changes consult the
canonical `docs/instructions/package-management.md` policy.

## Configuration Sources

- `.config/mise/config.macos.toml` owns the complete macOS system package set;
  `.config/mise/config.toml` holds platform-neutral deployment definitions.
  Formulas use `brew:`, casks use `brew-cask:` under `[bootstrap.packages]`.
- Shared dev tools and interim asdf runtime versions have separate declarations
  identified in the package policy; runtime migration to mise is not complete.
- Fresh setup requires completed Command Line Tools, then installs standalone
  mise (if absent) before Homebrew. Existing mise providers are preserved.
  `scripts/shared/environment.sh` exposes `~/.local/bin` and Apple Silicon's
  `/opt/homebrew/bin` and `sbin` to each provisioning process without sourcing
  interactive startup files. The bootstrap scope is Apple Silicon macOS.
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
  `~/Library/LaunchAgents/`. General scripts should discover an installed prefix
  with `brew --prefix`; provisioning explicitly supports `/opt/homebrew`.

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
