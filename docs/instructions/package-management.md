# Package Ownership Policy

This is the canonical ownership policy. Use the `package-management` skill for
the workflow; read only the applicable platform guide for platform-specific work.

## Sources of Truth

| Owner | Repository declaration |
|---|---|
| System packages via mise bootstrap | `.config/mise/config.toml` plus `config.macos.toml` or `config.omarchy.toml` in the same directory, under `[bootstrap.packages]` |
| AUR packages via interactive yay | `packages/aur/packages.txt`; machine-specific tracking under `packages/aur/machines/` |
| Shared mise dev tools | `packages/mise/.config/mise/config.toml`, under `[tools]`; intended home destination: `~/.config/mise/config.toml` |
| Language runtimes via asdf (interim) | `packages/tool-versions/.tool-versions` |

The repository bootstrap config and deployed dev-tool config have different roles.
Inspect effective mise configuration and environment selection before installing;
system defaults (notably `/etc/mise/conf.d/` on Omarchy) may also provide tools.

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

When criteria do not settle a choice, compare similar tracked tools, then inspect
the installed OS's package and mise defaults or version-matched upstream sources.
These are tie-breakers, not overrides. Package names and executable names can differ.
Do not remove OS-required packages merely to eliminate an overlap; build dependencies
may legitimately require a system runtime alongside the selected asdf version.

## Declaration and Installation Boundaries

- Put shared system dependencies in `.config/mise/config.toml`; platform-only
  dependencies go in the corresponding platform file. Avoid duplicate declarations.
- Shared dev tools belong in `packages/mise/.config/mise/config.toml`; verify the
  backend/platform support before adding one. Do not put optional dev tools into
  platform bootstrap just because they are CLI applications.
- Track runtime version changes directly in `packages/tool-versions/.tool-versions`.
  Do not assume a global manager command edits the tracked file on this machine.
- AUR installation reads `packages/aur/packages.txt`, outside mise bootstrap and
  dotfile deployment. Machine lists are tracking-only, not automatic installation
  overlays; read `docs/instructions/omarchy.md` before editing them.
- `make tools` installs only explicit requests parsed from the tracked shared
  `[tools]` declaration, using `mise --no-config` to exclude asdf/effective defaults.
  Package bootstrap skips its tools phase. Preserve both safeguards; a blanket
  `mise install` or unfiltered bootstrap can install duplicate asdf runtimes.

## Ownership Changes

Inspect declarations, installed packages, and command resolution first. When
installation/removal is authorized, verify the new provider before removing the old
user-managed one. Preserve OS dependencies and unrelated edits. Check resolution in
a fresh shell with `command -v <tool>` and inspect `mise config ls`, `mise current`,
or `asdf current` as applicable. Do not infer successful installation from a text edit.

## Upstream References

- [mise](https://mise.jdx.dev/) — registry, backends, effective configuration
- [asdf](https://asdf-vm.com/) — runtime installation and version selection
