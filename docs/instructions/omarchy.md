# Omarchy Conventions

Treat `/usr/share/omarchy/` as read-only upstream material. Keep user overrides in
`~/.config/` (notably `hypr/` and `omarchy/`) and inspect actual tracked package
files before assuming a particular upstream layout. Bash is the desktop shell;
load `docs/instructions/bash.md` only for shell changes.

After Omarchy updates, inspect replaced configs, backups, target collisions, and
checkout-local exclusions before authorized redeployment. See
[deployment guidance](mise-dotfiles.md) for environment selection and scope.

Prefer narrowly managed user overrides over replacing Omarchy-owned files;
inspect the installed version's loading paths before editing desktop settings.

## Installation Inputs

Ownership rules live in `docs/instructions/package-management.md`; this section
describes actual consumers, not another ownership policy.

- Pacman declarations live in `.config/mise/config.omarchy.toml`.
- `scripts/omarchy/packages.sh` runs the Linux package layer, then `aur.sh`, which
  reads `packages/aur/packages.txt`. The standalone `scripts/linux/aur-installer.sh`
  uses the same list. Inspect these consumers before changing installation inputs.
- Machine lists beneath `packages/aur/machines/` are tracking-only, not automatic
  installation overlays. Keep hardware-specific dependencies out of shared declarations.
- Plain Arch or Manjaro detection does not establish Omarchy support. Inspect
  `scripts/shared/detect-os.sh` and platform prerequisites before extending support.

Use real package names, not executable names.
Verify repository availability against the installed Omarchy version rather than
assuming every non-AUR target is in official Arch repositories. Preserve the
installed mise provider and prefer concrete providers over ambiguous virtual
targets. Never use `pacman -Sy` alone;
Arch partial upgrades are unsupported. Review AUR build instructions as the user,
not by automatically approving prompts or running yay as root.

## Package Auditing

For read-only inspection on the target machine, `pacman -Qqen` and `pacman -Qqem`
list explicit native and foreign packages. Foreign does not necessarily mean AUR.
Compare these with the tracked declarations and effective mise configuration
(including system defaults); package and tool names may differ. Track direct dependencies
even if preinstalled, but do not treat discovery as a complete ownership detector
or overwrite curated lists with command output.

## References

- [Omarchy manual](https://omarchy.org/manual/)
- [Omarchy source](https://github.com/omacom/omarchy) — compare against the installed version
- [Arch system maintenance](https://wiki.archlinux.org/title/System_maintenance)
