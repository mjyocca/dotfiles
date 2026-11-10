# Bash Configuration

Source files live in `packages/bash/`. Inspect both login and interactive startup
paths; do not assume non-interactive Bash reads `.bashrc`.

## Placement and Omarchy Integration

- Preserve Omarchy's environment bootstrap before the interactive guard and its
  interactive defaults after it. Do not use `OMARCHY_PATH` as proof of OS identity.
- Keep standalone initialization separate from Omarchy-owned hooks; inspect
  installed defaults before adding another initialization path.
- Inspect upstream environment overrides when application config appears ignored;
  preserve intentional machine-local values.
- Keep `~/.bashrc.local` ignored and sourced **last** for machine-specific settings
  and credentials.

## Change Constraints

- Add PATH entries with idempotent `case ":$PATH:"` guards. Inspect the resulting
  order after tool activation. Use `packages/shell/.config/dotfiles/runtime-path.sh`
  for early mise shim setup and deduplication. Do not re-prepend shims over the
  real tool paths added by full mise activation.
- Put script-relevant exports before the interactive check; keep prompts,
  aliases, completions, and hooks after it. Guard new optional hooks with
  `command -v` and keep one concern per commented section.
- Mise owns runtimes and project environments. Keep asdf and direnv installed but
  uninitialized. Omarchy's upstream rc owns full mise activation; do not wrap it or
  add a second activation. Verify upstream initialization before changing it.

## Verification and References

Use `bash -n` on changed files for syntax without sourcing them. Startup can run
hooks and create a local file; test fresh interactive/login contexts only when
appropriate, and report platform coverage. Consult the relevant upstream page
instead of copying tool initialization recipes:

- [Bash startup files](https://www.gnu.org/software/bash/manual/bash.html#Bash-Startup-Files)
- [Omarchy manual](https://omarchy.org/manual/)
- [mise activation](https://mise.jdx.dev/cli/activate.html)
