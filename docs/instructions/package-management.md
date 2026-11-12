# Package Ownership Policy

This is the canonical ownership policy. Use the `package-management` skill for
the workflow; read only the applicable platform guide for platform-specific work.

## Sources of Truth

| Owner | Repository declaration |
|---|---|
| System packages via mise bootstrap | `.config/mise/config.<platform>.toml`, under `[bootstrap.packages]` |
| AUR packages via interactive yay | `packages/aur/packages.txt`; machine-specific tracking under `packages/aur/machines/` |
| mise dev tools | `.config/mise/global/` shared and platform tool fragments |
| Language runtimes via mise | `packages/tool-versions/.tool-versions`; project and machine-local mise overrides |

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

Mise owns runtime selection and project environment loading. Asdf and direnv stay
installed dependencies without shell initialization or asdf plugin provisioning.
`make plugins` does not install runtimes; `make tools` installs effective mise
requests after deployment. See [runtime architecture](../architecture/mise.md#runtimes-and-project-environments)
for migration boundaries. Terraform ownership changes remain separate.

When criteria do not settle a choice, compare similar tracked tools, then inspect
the installed OS's package and mise defaults or version-matched upstream sources.
These are tie-breakers, not overrides. Package names and executable names can differ.
Do not remove OS-required packages merely to eliminate an overlap; build dependencies
may legitimately require a system runtime alongside the selected runtime version.

## Declaration and Installation Boundaries

- Keep `.config/mise/config.toml` platform-neutral; each platform file owns its
  complete system package set. Platforms are independent, not inherited; matching
  dependencies across platform files may be duplicated. Preserve existing OS
  filters: mise's built-in Brew backend also runs on Linux without brew, and
  `os = "linux"` does not distinguish distributions.
- Shared dev tools belong in `.config/mise/global/tools.toml`; put platform
  differences in that directory's platform fragments. Verify backend/platform
  support and effective provider exclusions; CLI apps do not automatically belong
  in system bootstrap.
- Track runtime version changes directly in `packages/tool-versions/.tool-versions`.
  Do not assume a global manager command edits the tracked file on this machine.
- AUR installation reads `packages/aur/packages.txt`, outside mise bootstrap and
  dotfile deployment. Machine lists are tracking-only, not automatic installation
  overlays; read `docs/instructions/omarchy.md` before editing them.
- `make tools` uses normal mise discovery, including intentional machine-local
  requests; preview with `TOOLS_ARGS=--dry-run`. Deploy the global fragments first.
  Keep package installation, deployment, and tools as separate stages, with
  deployment before tools. The package stage uses native packages-only scoping.
- Keep checkout and global `.tool-versions` discovery enabled for mise. Prefer native
  backends; use an asdf plugin through mise only for a concrete compatibility need.
- Preserve existing mise providers and keep provisioning independent of interactive
  shell startup and runtime activation. Inspect platform prerequisites before changing
  installation order.

## Ownership Changes

Inspect declarations, installed packages, and command resolution first. When
installation/removal is authorized, verify the new provider before removing the old
user-managed one. Preserve OS dependencies and unrelated edits. Check resolution
with `command -v <tool>` without loading private startup files; inspect only
non-secret metadata from `mise config ls` and `mise current`. Fresh-shell tests
must follow [isolation requirements](security.md#sensitive-local-files); request
redacted user diagnostics when actual local settings matter. Do not infer
successful installation from a text edit.

## Upstream References

- [mise configuration](https://mise.jdx.dev/configuration.html) — effective requests and discovery
- [mise asdf backend](https://mise.jdx.dev/dev-tools/backends/asdf.html) — plugin compatibility
