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
  order after tool activation; early asdf insertion alone does not prove
  its shims remain first in interactive shells.
  Use `packages/shell/.config/dotfiles/runtime-path.sh` for runtime shim priority
  and deduplication rather than adding a Bash-specific implementation.
- Put script-relevant exports before the interactive check; keep prompts,
  aliases, completions, and hooks after it. Guard new optional hooks with
  `command -v` and keep one concern per commented section.
- Follow the deployed machine runtime policy; shell cleanup is not permission to
  change that selection. Load the policy before runtime PATH setup and register
  only the selected environment loader. Preserve the startup-only Omarchy mise
  adapter; verify upstream initialization before changing it.

## Verification and References

Use `bash -n` on changed files for syntax without sourcing them. Startup can run
hooks and create a local file; test fresh interactive/login contexts only when
appropriate, and report platform coverage. Consult the relevant upstream page
instead of copying tool initialization recipes:

- [Bash startup files](https://www.gnu.org/software/bash/manual/bash.html#Bash-Startup-Files)
- [Omarchy manual](https://omarchy.org/manual/)
- [mise activation](https://mise.jdx.dev/cli/activate.html)
- [direnv hooks](https://direnv.net/docs/hook.html)
