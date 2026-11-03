---
name: package-management
description: Add packages, update tracked package declarations, or resolve ownership conflicts across Homebrew, pacman, mise, and interim asdf.
---

# Package Management Workflow

Paths below are relative to the **repository root**, not this skill's directory.

1. Read `docs/instructions/package-management.md` once for ownership policy. Read
   `docs/instructions/macos.md` or `docs/instructions/omarchy.md` only when the
   affected platform requires it; do not load both for a single-platform task.
2. Inspect existing declarations, effective manager configuration, and installed
   providers. Check `command -v <tool>` and `mise config ls`; inspect system mise
   defaults on Omarchy when relevant. Use the policy's tie-breakers if unclear;
   consult version-matched [Omarchy source](https://github.com/omacom/omarchy)
   only when local evidence is insufficient.
3. Confirm the actual package/backend name and supported platforms using the
   relevant registry or upstream documentation. Check consumer scripts before
   treating retained manifests as installation inputs.
4. Edit the appropriate tracked declaration directly. Do not assume `mise use -g`
   or `asdf set -u` updates the repository file. Keep unrelated edits intact.
5. Validate the diff and declaration syntax. If installation is authorized, prefer
   the narrowest relevant operation; blanket `mise install` can duplicate asdf
   runtimes. Do not run full bootstrap merely to add one tool.
6. For owner changes, verify the new provider before removing the old user-managed
   provider. Never remove OS-required packages to force a single installation.
7. Recheck resolution in a fresh shell and the effective manager configuration
   when runtime validation is authorized. Report declaration changes separately
   from installation/verification results and note unresolved consumer defects.

Installation, removal, deployment, and commits require authorization within the
active task; none is an automatic final step of this workflow.
