# Package Ownership Policy

This is the canonical ownership policy. Use the `package-management` skill for
the workflow; read only the applicable platform guide for platform-specific work.

## Sources of Truth

| Owner | Repository declaration |
|---|---|
| System packages via mise bootstrap | `.config/mise/config.toml` plus `config.macos.toml` or `config.omarchy.toml` in the same directory, under `[bootstrap.packages]` |
| AUR packages via interactive yay | `packages/aur/packages.txt`; machine-specific tracking under `packages/aur/machines/` |
| mise dev tools | `.config/mise/global/` shared and platform tool fragments |
| Language runtimes via asdf (interim) | `packages/tool-versions/.tool-versions` |

See [mise architecture](../architecture/mise.md) for composition and scope.
Inspect effective configuration, including system defaults, before installing.

## Choosing an Owner

1. **OS-integrated or session-critical:** use system packages via bootstrap
   (`brew:` / `brew-cask:` on macOS, `pacman:` on Omarchy). This includes services,
   libraries, shell startup dependencies, prompts, and session managers.
2. **Version-switched or tied to a fast-moving cloud API:** use mise dev tools,
   unless availability independent of mise is required by rule 1.
3. **Otherwise:** keep existing ownership. An optional CLI/TUI may use mise if its
   backend supports both platforms and it has no OS/session dependency; otherwise
   use the platform manager and document the exception.

Language runtimes remain on asdf until a separately scoped migration. Do not
install duplicate mise runtimes or move runtime ownership incidentally; Terraform
ownership changes are also a separate migration, not implied by these rules.
mise owns the asdf executable, not its runtimes. `make plugins` installs the
declared asdf plugins without installing language versions.

When criteria do not settle a choice, compare similar tracked tools, then inspect
the installed OS's package and mise defaults or version-matched upstream sources.
These are tie-breakers, not overrides. Package names and executable names can differ.
Do not remove OS-required packages merely to eliminate an overlap; build dependencies
may legitimately require a system runtime alongside the selected asdf version.

## Declaration and Installation Boundaries

- Put shared system dependencies in `.config/mise/config.toml`; platform-only
  dependencies go in the corresponding platform file. Avoid duplicate declarations.
  Shared `brew:` entries must specify `os = "macos"` and `pacman:` entries
  `os = "linux"`: mise's built-in Brew backend also runs on Linux without brew.
- Shared dev tools belong in `.config/mise/global/tools.toml`; put platform
  differences in that directory's platform fragments. Verify backend/platform
  support and inspect effective provider exclusions. Do not put optional dev tools into platform
  bootstrap just because they are CLI apps.
- Track runtime version changes directly in `packages/tool-versions/.tool-versions`.
  Do not assume a global manager command edits the tracked file on this machine.
- AUR installation reads `packages/aur/packages.txt`, outside mise bootstrap and
  dotfile deployment. Machine lists are tracking-only, not automatic installation
  overlays; read `docs/instructions/omarchy.md` before editing them.
- `make tools` uses normal mise discovery, including intentional machine-local
  requests; preview with `TOOLS_ARGS=--dry-run`. Deploy the global fragments first.
  Preserve bootstrap's skipped tools phase so deployment precedes installation.
- Keep mise's `.tool-versions` discovery disabled while asdf owns those files.
  Explicit mise TOML requests remain separate; do not migrate them incidentally.
- Prerequisites preserve an existing mise provider. On a fresh Mac they install
  standalone mise before Homebrew; on Omarchy they use pacman when mise is absent.
  Provisioning adds executable search paths without activating language runtimes.

## Ownership Changes

Inspect declarations, installed packages, and command resolution first. When
installation/removal is authorized, verify the new provider before removing the old
user-managed one. Preserve OS dependencies and unrelated edits. Check resolution in
a fresh shell with `command -v <tool>` and inspect `mise config ls`, `mise current`,
or `asdf current` as applicable. Do not infer successful installation from a text edit.

## Upstream References

- [mise](https://mise.jdx.dev/) — registry, backends, effective configuration
- [asdf](https://asdf-vm.com/) — runtime installation and version selection
