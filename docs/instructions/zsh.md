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

## PATH and Hook Ordering

Use idempotent `case ":$PATH:"` guards for new PATH entries in either startup
file. Interactive-only entries are allowed in `.zshrc`; entries scripts need go
in `.zshenv`. Keep one concern per commented section.
Use `packages/shell/.config/dotfiles/runtime-path.sh` for runtime shim priority and
deduplication rather than adding shell-specific implementations.

Follow the deployed machine runtime policy for non-interactive shims and priority
after interactive tool activation. Inspect the late `.zshrc` PATH adjustment before
deduplicating entries; local overrides may intentionally change resolution afterward.

Keep mise activation before hooks that need its tools. Add availability guards
for new optional hooks; do not assume every machine has an optional dependency.
Inspect current asdf plugin/completion and Homebrew sourcing paths when changing
startup; do not silently migrate runtime ownership as part of shell cleanup.
Keep the policy load in `.zshenv` before runtime PATH setup. Do not add per-project
hook switching or register both environment loaders; see the
[machine ownership architecture](../architecture/mise.md#choosing-runtimes-and-an-environment-loader).

## Verification

Use `zsh -n` on changed files for syntax without sourcing them. Runtime startup
may execute hooks and create the local override file; run it only when appropriate
to the task. For PATH work, verify interactive and non-interactive resolution
separately in fresh shells and distinguish intentional priority from duplication.

See the [Zsh startup-file reference](https://zsh.sourceforge.io/Doc/Release/Files.html)
for shell behavior. Load Bash guidance only for changes that also affect Bash.
