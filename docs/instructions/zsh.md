# Zsh Configuration

Source files live in `packages/zsh/`. Read the affected startup file rather than
relying on a copied snapshot of its contents.

## Startup Placement

- Keep `.zshenv` fast, silent, and limited to required environment/PATH exports.
  Preserve explicit environment overrides; do not add prompts, plugin hooks, or aliases.
- `.zshrc` owns interactive activation, prompts, completions, hooks, aliases, and
  interactive-only PATH entries. Universal script dependencies
  belong in `.zshenv`, not here.
- Keep `~/.zshrc.local` ignored and sourced **last**.
  Keep machine-specific settings and credentials there, not in shared files.
- Do not set a shell-wide default for `MISE_ENV`. Keep dotfiles platform selection
  in Make and the checkout-local environment seed; preserve explicit user exports
  so unrelated projects can select their own environments.

## PATH and Hook Ordering

Use idempotent `case ":$PATH:"` guards for new PATH entries in either startup
file. Interactive-only entries are allowed in `.zshrc`; entries scripts need go
in `.zshenv`. Keep one concern per commented section.
Keep mise activation in `.zshrc`. Do not inject shims in `.zshenv`: non-interactive
children must retain inherited real runtime paths rather than reselect versions
from their own working directory.

Check non-interactive inheritance separately from interactive activation; local
overrides may intentionally change command resolution afterward.

Keep mise activation before hooks that need its tools. Add availability guards
for new optional hooks; do not assume every machine has an optional dependency.
Preserve Homebrew source-path quoting. Mise owns runtimes and project environments;
asdf and direnv remain dependencies without automatic initialization. Do not add
per-project hook switching or register another environment loader; see the
[runtime architecture](../architecture/mise.md#runtimes-and-project-environments).

## Verification

Use `zsh -n` on changed files for syntax without sourcing them. Runtime startup
may execute hooks and create the local override file; run it only when appropriate
to the task. For PATH work, verify interactive and non-interactive resolution
separately in fresh shells and distinguish intentional priority from duplication.

See the [Zsh startup-file reference](https://zsh.sourceforge.io/Doc/Release/Files.html)
for shell behavior. Load Bash guidance only for changes that also affect Bash.
