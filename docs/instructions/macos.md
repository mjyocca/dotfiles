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
- User preferences live under `[bootstrap.macos.defaults]` in
  `.config/mise/config.macos.toml`. Quote dotted domains and preference keys.
  `make config` applies only native mise defaults. `make packages` installs packages
  only, without deployment, preferences, or LaunchAgents. Direct full
  `mise bootstrap` includes both preferences and agents, so scope inspection and
  application explicitly.
- Inspect with `mise -E macos bootstrap macos defaults status`; preview with
  `mise -E macos bootstrap macos defaults apply --dry-run`. Preserve value types
  and undeclared runtime/security state. Removing a declaration does not reset
  the stored preference. App restarts require separate authorization.
- LaunchAgents are native `[bootstrap.macos.launchd.agents]` declarations in
  `config.macos.toml`. Inspect status and `apply --dry-run` with
  `mise -E macos bootstrap macos launchd-agents` before authorized activation.
  Check existing `com.local.remap_caps_lock` and `addssh` jobs before migration:
  mise uses `dev.mise.*` labels and does not replace those legacy jobs.
- `.config/mise/macos/` is reserved for future supporting files; `.gitkeep` is
  only a repository placeholder, not a deployment source.
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
