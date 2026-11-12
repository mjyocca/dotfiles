---
name: package-management
description: Add packages, update tracked declarations, or resolve ownership conflicts across Homebrew, pacman, mise, and asdf.
---

# Package Management Workflow

Paths below are relative to the **repository root**, not this skill's directory.

1. Read `docs/instructions/package-management.md` once for ownership policy. Read
   `docs/instructions/macos.md` or `docs/instructions/omarchy.md` only when the
   affected platform requires it; do not load both for a single-platform task.
2. Inspect tracked declarations, effective configuration (including system defaults),
   and command resolution. Use the policy's tie-breakers when ownership is unclear.
3. Confirm the actual package/backend name and supported platforms using the
   relevant registry or upstream documentation. Check consumer scripts before
   treating retained manifests as installation inputs.
4. Edit the appropriate tracked declaration directly, preserving unrelated changes.
5. Validate the diff and declaration syntax. If installation is authorized, prefer
   the narrowest relevant operation. Normal mise discovery includes effective TOML
   requests beyond tracked defaults; preview those requests rather than running
   full bootstrap merely to add one tool.
6. For owner changes, verify the new provider before removing the old user-managed
   provider. Never remove OS-required packages to force a single installation.
7. When runtime validation is authorized, recheck resolution and non-secret manager
   metadata without reading private overrides. Fresh-shell tests must follow
   `docs/instructions/security.md` isolation requirements; otherwise request
   redacted user diagnostics. Report declaration changes separately
   from installation/verification results and note unresolved consumer defects.

Installation, removal, deployment, and commits require authorization within the
active task; none is an automatic final step of this workflow.
