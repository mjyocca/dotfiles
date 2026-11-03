# Bash Configuration

Source files live in `packages/bash/`. `.bash_profile` sources `.bashrc` for login
shells; interactive non-login shells read `.bashrc` directly. Non-interactive Bash
does not universally read these files—do not promise script-wide environment setup.

## Placement and Omarchy Integration

- `.bashrc` starts with fast, silent environment/PATH exports and asdf shims.
  They apply when the file is sourced, including before its interactive guard.
- When readable, `/usr/share/omarchy/default/bash/env-bootstrap` is sourced before
  the guard. Interactive shells then load the Omarchy default Bash rc. Preserve
  this sequence; non-interactive sourcing must return before prompts/hooks run.
- The standalone initialization block runs when `OMARCHY_PATH` is absent. It
  initializes tools directly with availability checks; do not duplicate Omarchy
  defaults in the shared hook block or use the variable as proof of OS identity.
- Cross-platform extras (currently direnv and PNPM) follow the standalone block.
- `.config/bash/nvim.bash` owns editor aliases and variant shorthands.
- `~/.bashrc.local` is git-ignored, bootstrapped if missing, and sourced **last**
  for machine-specific settings and credentials.

## Change Constraints

- Add PATH entries with idempotent `case ":$PATH:"` guards. Inspect the resulting
  order after Omarchy/mise/PNPM hooks; early asdf insertion alone does not prove
  its shims remain first in interactive shells.
- Put script-relevant exports before the interactive check; keep prompts,
  aliases, completions, and hooks after it. Guard new optional hooks with
  `command -v` and keep one concern per commented section.
- Check installed Omarchy defaults before adding initialization. Tools already
  initialized there need only a guarded standalone counterpart on other systems.
- Preserve interim asdf ownership; shell edits are not a runtime migration.

## Verification and References

Use `bash -n` on changed files for syntax without sourcing them. Startup can run
hooks and create a local file; test fresh interactive/login contexts only when
appropriate, and report platform coverage. Consult the relevant upstream page
instead of copying tool initialization recipes:

- [Bash startup files](https://www.gnu.org/software/bash/manual/bash.html#Bash-Startup-Files)
- [Omarchy manual](https://omarchy.org/manual/)
- [mise activation](https://mise.jdx.dev/cli/activate.html)
- [direnv hooks](https://direnv.net/docs/hook.html)
