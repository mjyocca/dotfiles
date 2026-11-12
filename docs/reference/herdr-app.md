# Herdr desktop customization

## Customization

Use Herdr's locally generated `~/.config/herdr-app/AGENTS.md` for installed-version
guidance, and the adjacent `herdr.d.ts` and `gpui-kit.d.ts` for mods and app APIs.
Herdr generates these files on startup; don't edit them. Use settings for appearance
changes and clone shipped layouts or mods before changing their structure or code.

Follow the repository's [deployment guidance](../instructions/mise-dotfiles.md)
when making changes persistent. Shared key customizations live in
`packages/herdr-app/.config/herdr-app/keys.json`; each platform merges them into
the existing keymap rather than replacing Herdr's platform defaults.

Open Herdr once on a new machine before deploying its key customizations so it
can create its default keymap. A merge into a missing file only creates the
supplied bindings. Native key sequences have no prefix popup and unmatched input
may be replayed into the terminal. Ctrl+S can pause output when terminal flow
control is enabled; Ctrl+Q resumes it. These customizations do not change TTY
flow-control settings.

## Upstream references

- [Official Herdr desktop documentation](https://github.com/herdrdev/herdr-app#readme)
  — app overview, usage, and customization entry points.
- [Herdr guide](https://herdr.dev/guide/) — starting point for customization.
- [Official command reference](https://github.com/herdrdev/herdr-app/blob/master/docs/commands.md)
  — available actions, arguments, and terminal-closing behavior; use
  `herdr-app commands` for the installed version.
- [Agent guide source](https://github.com/herdrdev/herdr-app/blob/master/defaults/AGENTS.md)
  — online reference; the locally generated guide is version-specific.
- [Layouts and mods](https://github.com/herdrdev/herdr-app/blob/master/docs/mods.md)
  — customization boundaries, live reload, and validation.
- [Herdr key loader](https://github.com/herdrdev/herdr-app/blob/v0.1.12/src/keys.rs)
  and [GPUI sequence parser](https://github.com/herdrdev/herdr-app/blob/v0.1.12/vendor/gpui-pre/src/keymap/binding.rs)
  — native space-separated key sequences used by the current configuration.
