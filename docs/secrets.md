# Project Secrets with Fnox and Mise

Mise's experimental fnox integration gives selected tasks access to secrets without
exporting those values to your interactive shell. This guide covers project setup
and migration from `.env` and `.envrc` files. Dotfiles declares the supporting tools;
it does not configure providers or grant secrets to projects automatically.

## What This Solves

Instead of keeping secrets in plaintext `.env` files, fnox resolves them from a
provider such as 1Password, AWS Secrets Manager, or age-encrypted values.
Project-level `fnox.toml` stores provider configuration and references, not
plaintext values. Mise controls which tasks receive them through `secrets = [...]`
and redacts captured task output. Grants are not process isolation; see
[security boundaries](#trust-and-security-boundaries). Interactive or raw tasks
and one-off commands have [redaction limits](#output-shows-plaintext-secret).

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
Prefer specific Make targets with only their required keys over broad grants to
`make all`. Existing shell exports remain inherited regardless of these grants.

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

### One-Off Commands

For ad-hoc access without defining a task:

```bash
mise x --secrets DATABASE_URL,API_TOKEN -- make dev
mise x --secrets DATABASE_URL -- make test
```

The command after `--` receives the granted keys. **`mise x` does not redact output**—avoid printing secrets.

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

For each project:

1. Identify secret variables and non-secret configuration.
2. Move secrets through your provider's secure UI or interactive workflow. For
   1Password, create vault items and store only references in `fnox.toml`.
3. Move non-secret configuration into `[env]` in `mise.toml` or `mise.local.toml`;
   use `[tools]` and `_.path` for runtimes and PATH additions.
4. Update tasks to grant only the keys they need. Test with `mise secrets ls` and `mise tasks validate`.
5. Verify the application works with `mise run <task>`. Check that unrelated tasks receive no secrets.
6. Remove the `.envrc` or `.env` file only after confirming no other tools load it. Check for scripts that source it directly.

This dotfiles setup activates real tool paths interactively; child shells retain
those paths rather than receiving shims. Direnv remains installed without its
shell hook. Translate its standard-library calls rather than sourcing `.envrc`;
explicit `_.source` scripts can run during activation and need side-effect review.
Retain legacy files until their consumers migrate, and do not enable both loaders
for one project. See the
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

If `mise secrets ls` reports an unknown key or `mise tasks validate` reports a grant
error, check spelling, the key's definition in `fnox.toml`, and the selected profile.
Correct the reference or define the missing key; consult
[fnox profiles](https://fnox.jdx.dev/guide/profiles.html) for composition rules.

### Secret Not Reaching Task

Use `mise secrets ls` to check the task's grants. Add a missing key to that task's
`secrets` list, including a dependency's own list when it needs the key.

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

### Trust Model

Outside paranoid mode, `mise run` implicitly trusts the active configuration. In CI, mise trusts every config file. Cloning a repository and running a task in it runs that repository's tasks, including any that list secrets.

For machines where AI agents or untrusted repositories are common, set `paranoid = true` so every config must be trusted explicitly.

### Delivery and Isolation

**Grants are not a sandbox.** They limit what fnox fetches, not existing shell
exports or access by other processes running as the same user. Granted secrets
reach the task and all its children: wrapping `make dev` also grants them to every
command it invokes. Fnox does not sanitize inherited environment variables.

The integration does not deliver values to your interactive shell, `mise env`,
shims you run yourself, or the task cache. File grants (`as_file = true`) use
owner-only directories and are deleted when the task ends. Captured `mise run`
output is redacted, but `mise x` and raw or interactive terminal output are not;
see [output troubleshooting](#output-shows-plaintext-secret) for exposure recovery.

## References

- [Mise secrets documentation](https://mise.jdx.dev/environments/secrets/)
- [Mise fnox integration](https://mise.jdx.dev/environments/secrets/fnox.html)
- [Fnox providers](https://fnox.jdx.dev/providers/overview.html)
- [1Password provider](https://fnox.jdx.dev/providers/1password.html)
- [Fnox installation](https://fnox.jdx.dev/guide/installation.html)
- [Dotfiles toolbox](reference/dotf.md) for project scaffolding with `mise.local.toml` templates
