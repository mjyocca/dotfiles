# macOS Conventions

Use for macOS integration, defaults, containers, and desktop automation. Load
`docs/instructions/zsh.md` only for shell changes; for package changes consult the
canonical `docs/instructions/package-management.md` policy.

## Configuration Sources

- `.config/mise/config.macos.toml` owns the complete macOS system package set;
  `.config/mise/config.toml` holds platform-neutral deployment definitions.
  Formulas use `brew:`, casks use `brew-cask:` under `[bootstrap.packages]`.
- Shared dev tools and asdf-owned runtimes have separate declarations identified
  in the package policy; do not change runtime ownership incidentally.
- Fresh setup requires completed Command Line Tools, then installs standalone
  mise (if absent) before Homebrew. Existing mise providers are preserved.
  Provisioning uses `scripts/shared/environment.sh`, not interactive startup
  files. The bootstrap scope is Apple Silicon macOS.
- `scripts/macos/config.sh` uses `apply-user-defaults`, when available, with
  `.config/macos/defaults.yml` and `.config/macos/defaults.apps.yml`, resolved
  relative to the repository rather than the caller's working directory.
  `make config` (also `make apply_settings`) applies them; it is not a read-only
  validation command and may skip defaults if the utility or input files are absent.
- `.config/macos/` is repository-only configuration, not a mise dotfile deployment
  source. A retained plist is not authorization to install or load it.
- General scripts should discover the installed Homebrew prefix with `brew --prefix`.

## Containers and Virtualization

Inspect the effective Colima profile before changing it; the tracked template
defines new-profile defaults, not the state of existing VMs.

Review host mounts and their write access before running untrusted workloads.
Neither a VM backend nor container use alone establishes safe isolation from
mounted host files. See [security constraints](security.md) for mount boundaries.

- [Apple Virtualization framework](https://developer.apple.com/documentation/virtualization)
- [Colima](https://github.com/abiosoft/colima)
- [Lima VM backends](https://lima-vm.io/docs/config/vmtype/)

## Agentic Tooling

Desktop automation and accessibility access require explicit user approval.
Snapshots, screenshots, clipboard reads, and debug artifacts may expose private
content; keep them out of public logs and uploads. Consult the tool's upstream
platform guide before use; accessibility automation does not provide VM isolation.

## Platform Boundaries

Respect macOS privacy permissions and protected system paths; do not bypass them
to make automation work. For platform behavior, consult the relevant section of
[Apple documentation](https://developer.apple.com/documentation/), the
[macOS User Guide](https://support.apple.com/guide/mac-help), or
[Homebrew documentation](https://docs.brew.sh/) rather than maintaining local manuals.
