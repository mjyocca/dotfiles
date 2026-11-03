# Omarchy Conventions

Treat `/usr/share/omarchy/` as read-only upstream material. Keep user overrides in
`~/.config/` (notably `hypr/` and `omarchy/`) and inspect actual tracked package
files before assuming a particular upstream layout. Bash is the desktop shell;
load `docs/instructions/bash.md` only for shell changes.

After Omarchy updates, inspect replaced configs, backups, and target collisions
before authorized redeployment. `make link` is the deployment entrypoint; Make
selects the detected platform environment unless `MISE_ENV` is already set. See
`docs/instructions/mise-dotfiles.md` when working on deployment.

## Installation Inputs

Ownership rules live in `docs/instructions/package-management.md`; this section
describes actual consumers, not another ownership policy.

- `scripts/linux/packages.sh` invokes `mise bootstrap`. Pacman declarations live
  in `.config/mise/config.toml` and `.config/mise/config.omarchy.toml`.
- `scripts/omarchy/packages.sh` invokes the Linux layer, then `aur.sh`. The AUR
  script reads `packages/aur/packages.txt` and invokes yay with review prompts.
  `scripts/linux/aur-installer.sh` is a standalone interactive alternative using
  the same list. Neither installer automatically includes machine-specific lists.
- `packages/aur/` contains repository-only data, not home-relative dotfiles.
  Never add it to mise dotfile groups or deployment selections.
- `scripts/omarchy/installer.sh` currently invokes generic `bootstrap_linux`, not
  `bootstrap_omarchy`, and does not implement machine overlay selection. Do not
  document `--machine` as an installer feature.

Use real package names, not executable names (`git-delta` provides `delta`).
Verify repository availability against the installed Omarchy version rather than
assuming every non-AUR target is in official Arch repositories. Preserve the
installed mise provider (for example `mise-bin`) and prefer concrete providers
such as `qemu-base` over ambiguous virtual targets. Never use `pacman -Sy` alone;
Arch partial upgrades are unsupported. Review AUR build instructions as the user,
not by automatically approving prompts or running yay as root.

## Discovery and Hardware Tracking

The obsolete manifest-based audit helper has been removed along with the duplicate
pacman lists. Use the declarations above when comparing installed packages.

Machine lists live beneath `packages/aur/machines/`; these are not automatically
installed. Keep hardware-specific direct dependencies out of shared declarations.
`amd-strix-halo/packages.txt` records `llama-cpp-rocm-git`; tracking is not proof
of package maintenance or fresh-build support. Check upstream before reinstalling.

For read-only inspection on the target machine, `pacman -Qqen` and `pacman -Qqem`
list explicit native and foreign packages. Foreign does not necessarily mean AUR.
Compare these with effective mise configuration (`mise config ls`, including
system defaults); package and tool names may differ. Track direct dependencies
even if preinstalled, but do not treat discovery as a complete ownership detector
or overwrite curated lists with command output.

## References

- [Omarchy manual](https://omarchy.org/manual/)
- [Omarchy source](https://github.com/omacom/omarchy) — compare against the installed version
- [Arch system maintenance](https://wiki.archlinux.org/title/System_maintenance)
