# Zsh Configuration

Source files live in `packages/zsh/`. Read the affected startup file rather than
relying on a copied snapshot of its contents.

## Startup Placement

- Keep `.zshenv` fast, silent, and limited to required environment/PATH exports.
  Preserve explicit environment overrides; do not add prompts, plugin hooks, or aliases.
- `.zshrc` owns interactive activation, prompts, completions, hooks, aliases, and
  interactive-only PATH entries. Universal script dependencies
  belong in `.zshenv`, not here.
- Keep `~/.zshrc.pre.local` and `~/.zshrc.local` ignored. Source the pre-local
  override immediately before mise for machine-specific PATH changes and
  variables needed during activation. Source `.zshrc.local` **last** for aliases,
  functions, hooks, and settings that do not change PATH or `MISE_*` state.
  Mise deployment seeds both with create-only private files and never replaces
  existing contents.
  Agents must not read or source either real file; see
  [security constraints](security.md#sensitive-local-files).
- Do not set a shell-wide default for `MISE_ENV`. Keep dotfiles platform selection
  in Make and the checkout-local environment seed; preserve explicit user exports
  so unrelated projects can select their own environments.

## PATH and Hook Ordering

Use idempotent `case ":$PATH:"` guards for new PATH entries in either startup
file. Interactive-only entries are allowed in `.zshrc`; entries scripts need go
in `.zshenv`. Put deterministic interactive PATH changes before mise activation
so its initial state snapshot includes them; use `.zshrc.pre.local` for private
ones. PATH changes after activation cause mise to recalculate the environment at
the first prompt. Keep one concern per commented section.
Keep mise activation in `.zshrc`. Do not inject shims in `.zshenv`: non-interactive
children must retain inherited real runtime paths rather than reselect versions
from their own working directory.

Check non-interactive inheritance separately from interactive activation. Keep
machine-specific command resolution changes in the pre-local override so mise
captures their ordering during activation.

Keep mise activation before hooks that need its tools. Add availability guards
for new optional hooks; do not assume every machine has an optional dependency.
Preserve Homebrew source-path quoting. Mise owns runtimes and project environments;
asdf and direnv remain dependencies without automatic initialization. Do not add
per-project hook switching or register another environment loader; see the
[runtime architecture](../architecture/mise.md#runtimes-and-project-environments).

## Verification

Use `zsh -n` on changed source files for syntax without sourcing them. Run syntax
and startup checks in an isolated fixture that cannot load real local overrides
or dotenv files; startup may execute hooks and create files. For PATH work, check
interactive and non-interactive resolution separately in that fixture. Request
redacted diagnostics for real-machine behavior and report untested cases.

See the [Zsh startup-file reference](https://zsh.sourceforge.io/Doc/Release/Files.html)
for shell behavior. Load Bash guidance only for changes that also affect Bash.
