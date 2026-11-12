# Bash Configuration

Source files live in `packages/bash/`. Inspect both login and interactive startup
paths; do not assume non-interactive Bash reads `.bashrc`.

## Placement and Omarchy Integration

- Preserve Omarchy's environment bootstrap before the interactive guard and its
  interactive defaults after it. Do not use `OMARCHY_PATH` as proof of OS identity.
- Keep standalone initialization separate from Omarchy-owned hooks; inspect
  installed defaults before adding another initialization path.
- Inspect tracked upstream initialization when application config appears ignored;
  ask for redacted diagnostics rather than reading machine-local overrides.
- Keep `~/.bashrc.local` ignored and sourced **last** for machine-specific settings
  and credentials. Agents must not read or source the real file; see
  [security constraints](security.md#sensitive-local-files).

## Change Constraints

- Add PATH entries with idempotent `case ":$PATH:"` guards. Inspect the resulting
  order after tool activation. Keep mise activation after the interactive guard;
  non-interactive children inherit real tool paths. Do not prepend shims over them.
- Put script-relevant exports before the interactive check; keep prompts,
  aliases, completions, and hooks after it. Guard new optional hooks with
  `command -v` and keep one concern per commented section.
- Mise owns runtimes and project environments. Keep asdf and direnv installed but
  uninitialized. Omarchy's upstream rc owns full mise activation; do not wrap it or
  add a second activation. Verify upstream initialization before changing it.

## Verification and References

Use `bash -n` on changed source files for syntax without sourcing them. Run syntax
and startup checks in an isolated fixture that cannot load real local overrides
or dotenv files; startup can run hooks and create files. Report untested platform
behavior and use user-provided redacted results for real-machine startup issues.
Consult the relevant upstream page instead of copying initialization recipes:

- [Bash startup files](https://www.gnu.org/software/bash/manual/bash.html#Bash-Startup-Files)
- [Omarchy manual](https://omarchy.org/manual/)
- [mise activation](https://mise.jdx.dev/cli/activate.html)
