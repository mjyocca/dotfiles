# Project Secrets with Fnox and Mise

Mise's experimental fnox integration gives selected tasks access to secrets without
exporting those values to your interactive shell. This guide covers project setup
and migration from `.env` and `.envrc` files. Dotfiles declares the supporting tools;
it does not configure providers or grant secrets to projects automatically.

## What This Solves

Projects need environment variables—database URLs, API tokens, signing keys. Storing them in plaintext `.env` files creates risk: accidental commits, broad shell exposure, and unclear who gets what.

Fnox resolves secrets from a provider, such as 1Password, AWS Secrets Manager, or
age-encrypted values. Mise controls which tasks receive them and redacts captured
task output. Granted values reach the task and its children; grants do not sanitize
existing shell exports or isolate processes running as the same user. Interactive
or raw tasks and one-off commands have [redaction limits](#output-shows-plaintext-secret).

## Prerequisites

Before starting:

- **Mise version**: 2026.10.4 or newer supports the `secrets` field on tasks. Check with `mise --version`.
- **Fnox**: 1.39.0 or newer is required by mise's integration. Fnox is declared in
  the [global tool configuration](../.config/mise/global/tools.toml); declarations
  do not prove it is installed. Verify the available version with:
  ```bash
  mise exec -- fnox --version
  ```
  If missing, use the [tool installation workflow](commands.md#updating-existing-deployments).
- **Provider access**: for 1Password, sign in with the desktop app integration or `op signin`. Verify with `op vault list`. For other providers, follow their authentication flow.

In this dotfiles setup, mise manages fnox as a global development tool and the
platform package manager supplies `op`. A project or CI runner cannot assume those
tools are present; declare or provision its required tools separately.

Run the setup and task commands below from the target project's root, not the
dotfiles checkout. Replace the example vault, item, and task names with your own.
Review the project's configuration and commands before trusting or running them.
The examples assume your project defines the Make targets they invoke; this guide
does not create those targets or an application schema.

## Core Concepts

### Fnox vs. Mise Roles

- **Fnox** decides where a secret comes from and how to fetch it. Project-level `fnox.toml` stores provider configuration and secret references—not plaintext values.
- **Mise** decides which process receives a secret. Tasks list the keys they need in `secrets = [...]`. Mise fetches them from fnox and passes them to that task only.

Your shell, other tasks, and `mise env` never see the values unless you explicitly grant them.

### Project vs. Global Configuration

**Project-owned secrets** live in `fnox.toml` at the project root. Tasks in `mise.toml` or `mise.local.toml` can grant these keys automatically when you run `mise run <task>`.

**Global secrets** live in `~/.config/fnox/config.toml`. They belong to you, not the project. Tasks cannot grant global keys automatically—you must name them explicitly:

```bash
mise x --secrets MY_GLOBAL_KEY -- make dev
mise run --secrets MY_GLOBAL_KEY <task>
```

With fnox versions that report key provenance, mise rejects automatic project grants
for keys from your own config. Older versions may not provide that distinction;
review the [current integration restrictions](https://mise.jdx.dev/environments/secrets/fnox.html#personal-keys)
before relying on it. Grants are not a sandbox against a repository's executable code.

### Grants vs. Inheritance

A secret grant gives a value to a specific process and its children. It doesn't sanitize your existing shell environment. If you've exported `OTHER_SECRET` from `.bashrc` or direnv, child processes inherit it regardless of fnox grants.

To fully migrate a secret: move the value into your provider, remove the old shell export, then open a fresh shell or `unset VARIABLE_NAME`.

## Setup Workflow

### 1. Configure Fnox Providers

Create `fnox.toml` at the project root with provider definitions and secret references.
The dotfiles-managed global ignore excludes it, but verify that your project uses
that rule and that the file is not already tracked:

```bash
git check-ignore -v fnox.toml
git ls-files -- fnox.toml
```

The first command should identify an ignore rule; the second should print nothing.
If either check disagrees, resolve the project's tracking policy before adding
private references. An ignore rule does not untrack an existing file. Never put
plaintext secret values into this file, even when it is ignored.

```toml
# fnox.toml — project secret references
# This file is gitignored by the dotfiles-managed global ignore.

[providers.op]
type = "1password"
vault = "Engineering"

[secrets]
DATABASE_URL = { provider = "op", value = "Database/url" }
API_TOKEN = { provider = "op", value = "API/Key" }
```

The `value` field stores only a reference—`Database/url` means the `url` field of the `Database` item in the `Engineering` vault. Fnox fetches the actual value from 1Password when a task requests it.

Verify provider access:

```bash
fnox provider test op
```

Expected output: confirmation that fnox can reach the provider. If it fails, check your 1Password authentication state with `op vault list`.

### 2. Enable Fnox in Mise Configuration

Add to `mise.toml` or `mise.local.toml`:

```toml
min_version = "2026.10.4"

[settings]
experimental = true  # mise secrets is experimental

[secrets.fnox]
```

The `[secrets.fnox]` block declares fnox as the project's secret source. You can optionally specify a profile here: `profile = "dev"`.

### 3. Grant Secrets to Tasks

In the same file, define tasks with explicit key grants:

```toml
[tasks.dev]
secrets = ["DATABASE_URL", "API_TOKEN"]
run = "make dev"

[tasks.test]
secrets = ["DATABASE_URL"]
run = "make test"
```

The `dev` task receives both keys; `test` receives only `DATABASE_URL`. Tasks without
grants receive no fnox values from this integration. Dependencies need their own
grants, while ordinary child processes inherit the granted task's environment.

### 4. Verify the Configuration

Check what mise sees:

```bash
mise secrets ls
```

The listing shows key names, task grants, and whether a key is injectable, not secret
values. If mise reports an unknown key, check its spelling and the selected profile
in `fnox.toml`. A successful listing alone does not prove that all grants are valid;
review warnings and validate the task definitions too.

Validate task definitions:

```bash
mise tasks validate
```

Expected output: no errors. If a task grants an unknown key, mise reports it here.

### 5. Run a Task

```bash
mise run dev
```

Fnox resolves the requested keys and mise passes them to `make dev`. Mise redacts
captured task output; tasks explicitly configured as raw or interactive can bypass
that capture in a terminal. If provider authentication needs a prompt, fnox can
receive the terminal while mise waits.

## Usage Patterns

### Task-Scoped Grants

The standard workflow: define tasks with `secrets = [...]`, then run them with `mise run`.

```bash
mise run dev
mise run deploy
```

Tasks without grants receive no fnox values from this integration. Dependencies
receive only their own grants, not those of the tasks that depend on them. Existing
environment variables and ordinary child-process inheritance still apply.

### One-Off Commands

For ad-hoc access without defining a task:

```bash
mise x --secrets DATABASE_URL,API_TOKEN -- make dev
mise x --secrets DATABASE_URL -- make test
```

The command after `--` receives the granted keys. **`mise x` does not redact output**—avoid printing secrets.

### Wrapping Make Targets

If your project uses Make, wrap individual targets:

```toml
[tasks.dev]
secrets = ["DATABASE_URL"]
run = "make dev"

[tasks.test]
secrets = ["DATABASE_URL", "TEST_API_KEY"]
run = "make test"
```

Or use one-off grants for targets you run occasionally:

```bash
mise x --secrets DATABASE_URL -- make migrate
```

Prefer wrapping specific targets with only their required keys, rather than granting everything to a broad `make all`.

### Composed Values

You can reference secrets in task environment variables without exporting the raw value:

```toml
[tasks.migrate]
env.DATABASE_URL = "postgres://app:{{ secrets.DB_PASSWORD }}@db.internal/app"
run = "make migrate"
```

The task receives `DATABASE_URL` as a composed value, which the project's migration
target must consume. `DB_PASSWORD` itself is not exported unless you also list it
in `secrets`. Avoid expanding secret values into command arguments or logging them.

## Migrating from .env and .envrc

Migration is deliberate, project by project—not automatic. The fnox integration
does not automatically load `.env` or `.envrc`. Mise can load a dotenv file through
an explicit `_.file` declaration; those values enter its broader `[env]`
environment rather than task-scoped grants.

### What Moves

1. **Secrets** (database URLs, API tokens, signing keys): move into your provider through its secure UI or interactive workflow. Store only references in `fnox.toml`.
2. **Non-secret environment** (feature flags, debug settings, local ports): move into mise's `[env]` block in `mise.toml` or `mise.local.toml`.
3. **PATH and runtime configuration**: use mise's `[tools]` and `_.path`. This
   dotfiles setup activates real tool paths interactively and preserves inherited
   paths in child shells; it does not inject shims into non-interactive startup.

### Migration Steps

For each project:

1. Audit the `.envrc` or `.env` file. Identify which variables are secrets and which are configuration.
2. Move secrets into your provider. For 1Password, create items in the appropriate vault. Record references in `fnox.toml`.
3. Move non-secret configuration into mise's `[env]` block.
4. Update tasks to grant only the keys they need. Test with `mise secrets ls` and `mise tasks validate`.
5. Verify the application works with `mise run <task>`. Check that unrelated tasks receive no secrets.
6. Remove the `.envrc` or `.env` file only after confirming no other tools load it. Check for scripts that source it directly.

### What Doesn't Migrate

- **Direnv's standard library** (`layout python`, `dotenv`, etc.): mise provides its own environment features. Translate direnv idioms to mise equivalents.
- **Executable shell loading**: mise does not automatically source `.envrc`.
  Explicit `_.source` scripts can run during environment activation; review their
  side effects rather than assuming they behave like task-scoped secret grants.

Direnv remains an installed dependency, but this dotfiles setup does not register
its shell hook. Retain legacy files until their consumers have migrated; do not
enable both environment loaders for the same project. See the
[environment migration guide](commands.md#migrating-project-environments-and-editor-setup).

## Troubleshooting

### Provider Authentication

**Problem**: `fnox provider test op` fails or `mise run` prompts repeatedly.

**Check**:
```bash
op vault list  # verify 1Password authentication
op whoami      # confirm signed-in identity
```

**Fix**: sign in with the desktop app integration or `op signin`. Fnox uses whatever
session `op` has. In CI, supply `OP_SERVICE_ACCOUNT_TOKEN` through the CI secret
store on the step that needs it, not as a checked-in value or a job-wide export.

### Unknown Secret

**Problem**: `mise secrets ls` shows a key as "unknown" or `mise tasks validate` reports a grant error.

**Check**:
- Spelling in the task's `secrets` list
- The key exists in `fnox.toml`
- The profile matches (if using `profile = "dev"`)

**Fix**: correct the reference or define the key in the intended fnox configuration.
Check the selected profile rather than assuming it has the same keys as another
profile; consult [fnox profiles](https://fnox.jdx.dev/guide/profiles.html) for composition rules.

### Secret Not Reaching Task

**Problem**: a task runs but doesn't receive the expected secret.

**Check**:
```bash
mise secrets ls  # confirm the key is granted to this task
```

**Verify** the task's `secrets` list includes the key. Dependencies don't inherit secrets from their parents. If you need a secret in a dependency, grant it there too.

### Output Shows Plaintext Secret

**Problem**: a secret value appears in task output.

**Cause**: `mise x` does not redact output. In a terminal, a task explicitly marked
`raw = true` or `interactive = true` also receives the terminal without redaction.
Redaction applies to captured output, not every place a program can write a value.

**Fix**: avoid printing secrets. Prefer a task with captured output through
`mise run` when redaction is needed; do not rely on it for raw or interactive tasks,
files, or transformed values. If a real secret reached shared logs, treat it as
exposed and rotate it through the provider's secure workflow.

### Shell Still Has Old Secret

**Problem**: after migrating a secret to fnox, child processes still see the old value.

**Cause**: the secret is still exported from your shell configuration or direnv.

**Fix**: remove the export from `.bashrc`, `.zshrc`, or the project's `.envrc`. Open a fresh shell or `unset VARIABLE_NAME`. Fnox grants don't sanitize your existing environment.

## Trust and Security Boundaries

### What Grants Provide

A secret grant gives a value to a specific process and its children. That process can pass the value to every program it starts. A task that wraps `make dev` gives `make` and every command `make` invokes access to the granted secrets.

**Grants are not a sandbox.** They limit what fnox fetches, not what a process can inherit from your existing shell environment.

### Trust Model

Outside paranoid mode, `mise run` implicitly trusts the active configuration. In CI, mise trusts every config file. Cloning a repository and running a task in it runs that repository's tasks, including any that list secrets.

For machines where AI agents or untrusted repositories are common, set `paranoid = true` so every config must be trusted explicitly.

### What's Protected

- Secrets don't reach your shell, `mise env`, shims you run yourself, or the task cache.
- Captured task output is redacted when using `mise run`; raw or interactive
  terminal output is not.
- Keys provided as files (`as_file = true`) are written to owner-only directories and deleted when the task ends.

### What's Not Protected

- A task's child processes inherit granted secrets.
- Other processes running as the same user can read a granted task's environment while it runs.
- `mise x` output is not redacted.
- Raw or interactive task output in a terminal is not redacted.
- Existing shell exports remain accessible to child processes.

## References

- [Mise secrets documentation](https://mise.jdx.dev/environments/secrets/)
- [Mise fnox integration](https://mise.jdx.dev/environments/secrets/fnox.html)
- [Fnox providers](https://fnox.jdx.dev/providers/overview.html)
- [1Password provider](https://fnox.jdx.dev/providers/1password.html)
- [Fnox installation](https://fnox.jdx.dev/guide/installation.html)
- [Dotfiles toolbox](reference/dotf.md) for project scaffolding with `mise.local.toml` templates
