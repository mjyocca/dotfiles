# Spec: Local provider selection and domain adapters

Status: Draft v0.2 — architecture proposal; no implementation approved
Created: 2026-10-28
Repository handoff: 2026-10-29

## 1. Purpose and context

Allow each checkout/machine to select independent implementations for dotfile deployment, developer tools, language runtimes, project environments, secrets, and provisioning while preserving simple Make/Bash entrypoints.

Required context: [Dotfiles and secrets evaluation](./spec_dotfiles_secrets_evaluation.md). That spec contains the Stow/mise/chezmoi/yadm comparison, verified upstream capabilities, secret-delivery distinctions, source links, experimental-feature caveats, and related GitHub issues. This document defines composition and boundaries; it does not select a winning deployment or secret provider.

Historical context only: an earlier local-only `spec_unified_package_management.md` informed package planning but is not included in this handoff. Current repository instructions supersede its older manifest paths and package ownership rules; the baseline below captures the relevant context.

User requirements:
- Do NOT require `MACHINE=...` on routine Make/script commands.
- Read selections from a git-ignored local file, initialized from a tracked starter template.
- Select implementations independently by domain: e.g. mise developer tools, asdf runtimes, mise dotfiles.
- Preserve ordinary source files and Make/Bash orchestration; avoid unnecessary reliance on one tool.
- Support existing approaches and incremental adoption, including custom scripts when justified.
- Iterate on these repository specs before implementing provider/configuration changes.

Scope boundary: the proposed template, local config, ignore rules, scripts, and Make targets below are NOT created by this spec. Publishing these documents does not authorize implementing the proposal. `docs/specs/` is now the shared source of truth; local planning copies are not synchronized.

## 2. Baseline and design direction

Current repository:
- `packages/` contains GNU Stow-style home-relative configuration sources.
- `profiles/macos` and `profiles/omarchy` are current package allow-lists, with a repository-local `.stow-ignore.local` exclusion file.
- `manifests/pacman/` contains repository-only package lists and optional explicitly selected hardware overlays.
- Make and Bash scripts orchestrate provisioning; mise installs selected developer tools; asdf remains the runtime owner pending a separate migration.
- Shell startup already includes provider-specific activation and PATH assumptions. Dispatch changes alone cannot safely change runtime ownership.

Direction: separate intent, local policy, provider configuration, and execution. Introduce only enough dispatch to select proven implementations, not a general configuration-management framework.

## 3. Domain boundaries

| Domain | Owns | Candidate adapters / implementations |
| --- | --- | --- |
| Dotfile deployment | Target paths, links, copies, rendered configuration, deployment ownership | Stow, mise dotfiles, chezmoi; yadm requires evaluating its distinct live-file model; custom script |
| System packages | OS-integrated packages and native dependencies | Homebrew, pacman/yay, existing platform scripts |
| Language runtimes | Installation and active selection of Node, Ruby, Go, etc. | asdf, mise, external management |
| Developer tools | Explicitly declared version-sensitive/optional CLI tools | mise; native packages where ownership rules require them |
| Project environment | Nonsecret variables, project PATH/context, shell activation | mise, direnv, explicit scripts, disabled |
| Secret source | Encrypted storage, access control, references, authentication | 1Password, HashiCorp Vault, SOPS/age; more only if needed |
| Secret delivery | Resolve and deliver required keys to an explicit child process or required credential file | `op run`, standalone fnox, mise/fnox grants, narrowly scoped custom integration |
| OS/user settings | Preferences, user services, selected system/session changes | Existing scripts, selected mise bootstrap resources, external management |
| Application extensions | gh/tmux/Zellij or similar extensions and plugins | Native managers, existing scripts, supported mise package plugins |

Bootstrap is an ordered coordinator over these domains, not an additional owner. Selecting mise for one domain must not silently enable its other domains.

Tool/runtime separation is policy, not a claim that the underlying engines are independent. A mise provider must install only the declarations assigned to it; it must not blanket-install asdf runtimes inherited from `.tool-versions`.

## 4. Local selection file and starter template

Proposed names, open to refinement:
- Tracked: `.dotfiles.local.conf.example` — documented provider choices; no credentials.
- Git-ignored: `.dotfiles.local.conf` — this checkout's selected implementations.

Routine usage after setup:

```bash
make doctor
make dotfiles
make tools
make runtimes
make bootstrap
```

No routine command requires a machine name. An explicit future initialization command may copy the template only when the local file does not exist; it must never overwrite existing choices.

Illustrative schema, NOT a finalized set of supported adapters:

```text
CONFIG_VERSION=1
DOTFILES_PROVIDER=mise
TOOLS_PROVIDER=mise
RUNTIMES_PROVIDER=asdf
ENV_PROVIDER=mise
SECRETS_BACKEND=1password
SECRETS_DELIVERY=fnox
SYSTEM_PACKAGES_PROVIDER=platform
SETTINGS_PROVIDER=scripts
EXTENSIONS_PROVIDER=scripts
```

Naming deliberately distinguishes developer-tool versions from language runtime versions; `.tool-versions` is an existing asdf/mise filename, not the domain name.

Validation rules:
- Treat the file as data. Do not `source`, `eval`, or include it as arbitrary Make code.
- Prefer a small Bash parser for documented `KEY=identifier` entries, comments, and blank lines. No command substitution, interpolation, executable values, or arbitrary script paths.
- Reject unknown keys, duplicates, invalid values/schema versions, and unsupported provider combinations before mutation.
- Keep credentials, provider tokens, decrypted values, and secret-bearing environment variables OUT of this file and template. Git-ignore does not make plaintext safe.
- Never silently fall back to a different provider because the selected binary is missing. Explain prerequisites and stop.
- Document `disabled` versus `external` where applicable: disabled performs no work; external validates only an explicitly defined prerequisite contract and never takes ownership.
- Provide safe selector reporting without dumping effective environments, provider credentials, or native configs containing secrets.

The starter template should preserve currently supported behavior, not turn on experimental integrations or migrate ownership automatically. The mise/asdf example above demonstrates composition; it is not the promised default for every domain.

## 5. Resolution and scope

Proposed resolution:
1. Locate the repository root, not the caller's current directory.
2. Read and validate the local selection file once for the operation.
3. Detect OS only for platform compatibility and existing package-profile defaults.
4. Resolve the selected adapters and their declared dependencies.
5. Validate compatibility/ownership, then execute the requested operation.

Avoid deep inheritance in v1. Prefer one complete local selection file plus ordinary platform logic. Do not infer employer policy, secret access, hostname, or hardware from detection.

Missing-file behavior: proposed fail with initialization guidance before mutating anything. `make help` and a safe `doctor` should still explain the missing file. Existing default behavior during any compatibility transition needs an explicit rollout decision, not accidental fallback.

Scope is checkout-local, not a globally synchronized machine identity. New clones and linked worktrees do not inherit ignored files automatically. Document initialization for each checkout; never copy secret credentials as part of it. Whether a separate per-user configuration location is useful later remains open.

Existing hardware overlays are a different concern from provider selection. Preserve explicit overlay selection, with no hardware detection. A future local optional package-set selector may save repeated overlay arguments, but that is a separate schema decision; never silently bind the hardware overlay to the provider choices.

## 6. Sources, manifests, and provider-specific configuration

Keep these concepts distinct:
- Ordinary dotfile sources: current `packages/` where practical.
- Package/runtime/tool declarations: their existing manifests/native configs until a justified migration.
- Local selection policy: ignored file.
- Provider-native deployment/configuration: repository-only adapter configuration, not accidentally stowed into home.
- Provider state: native state locations with explicit backup/recovery implications.

Stow and mise symlink adapters should reuse the same ordinary package source where practical. Validate directory folding/per-file-link ownership rather than assuming identical behavior.

Chezmoi's source-state names and Go templates may require a separate source subtree for provider-specific material. Yadm's home worktree is a larger architectural difference than swapping a link command. Research compatibility rather than promising interchangeable sources for all tools.

Do NOT create a universal template engine, provider config translator, or one normalized package manifest for every manager in v1. Use native formats, with explicit ownership and limited duplication. Rendered outputs must not become competing sources of truth.

Local selection controls activation as well as install dispatch. Existing shared mise/asdf configuration and shell hooks must not activate unselected ownership. Work out how generated/selected activation fragments are represented without embedding secrets or forcing native provider choices into every shared shell file.

## 7. Thin adapter contracts

Proposed flow:

```text
Make entrypoint → Bash dispatcher → validated local policy → domain adapter → native tool
```

Capabilities vary by domain/provider:
- Deployment/settings: validate, preview where supported, apply.
- Tools/runtimes: validate declarations, install selected requests, inspect active resolution.
- Environment: validate configuration/activation; distinguish interactive loading from explicit execution.
- Secrets: validate references/authentication without printing values; execute with explicitly required keys.
- All: consistent error propagation and safe identification of the selected adapter.

Do not manufacture fake parity. Stow simulation, mise status, chezmoi rendered diff, and Git diff are not equivalent. Unsupported operations must be reported, not implemented as successful no-ops. Preview may evaluate native templates; it is not automatically side-effect-free.

Provider-specific escape hatches remain explicit and separate, e.g. an existing Stow-specific target can retain its documented flags. Generic targets must not indiscriminately forward arbitrary provider flags.

For process execution, use a script accepting argv after `--`, preserving each argument. Do not construct secret-bearing shell commands from Make variables or use `eval`.

Custom adapters are repository-maintained scripts registered by allow-listed name, not arbitrary commands loaded from the local policy file. Add them only for a concrete unmet requirement.

## 8. Secret and project boundary

Machine-local policy chooses the allowed/default mechanism. A project's own config identifies references, environment names, required keys, and tasks. Machine selection must not globally decrypt or export every project's credentials.

- 1Password + `op run`, fnox + 1Password/Vault, and mise/fnox grants can eliminate `.envrc` and direnv.
- `SECRETS_BACKEND` is a default/constraint, not a magic translation layer. A project using `op://` references cannot be switched to Vault by changing this single key; references, auth, and native config need an explicit mapping/migration.
- Provider-neutral script entrypoints can remain stable even when provider-native references differ.
- Validate delivery/backend compatibility. `op run` supports 1Password, not arbitrary Vault backends.
- Do not enable automatic secret shell exports simply because mise manages nonsecret environments.
- Do not treat same-user task grants as OS isolation. A granted application can read/exfiltrate its credentials; authentication tokens and broad vault sessions need their own least-privilege controls.
- Work policy and project trust must not be silently overridden by choosing a provider in a local file.
- Loading project config can execute code; discovery/doctor must not resolve secrets or execute unreviewed project configuration merely to inventory it.

## 9. Ownership, migration, and operational safety

1. One deployer owns each target path, including a directory's nested targets. Never allow two providers to compete over a symlinked directory.
2. One selected owner per runtime/tool request. Preserve required OS packages rather than uninstalling them solely to remove overlaps.
3. Selecting a new provider is NOT a migration. Detect existing ownership mismatches and stop with instructions before apply.
4. Provider changes require a reviewed handoff: inspect live state, backup nonsecret data safely, detach prior ownership, preview new deployment, verify, document reversal. Do not force-overwrite automatically.
5. Preserve native state needed for safe unapply/cleanup; local selectors do not replace native ownership records.
6. Fail fast on incompatible combinations or missing dependencies; propagate failures without pretending earlier changes rolled back.
7. Bootstrap must sequence dependencies and avoid provider cycles: provisioning installs mise independently, then uses a repository-scoped config to deploy mise's global config if required.
8. Only invoke selected mise bootstrap parts. A blanket bootstrap could otherwise claim dotfiles, shell activation, packages, or services assigned to other adapters.
9. Work machines can leave employer-managed settings, packages, and credentials untouched.
10. Diagnostics must be redacted by design; tests use dummy secrets and isolated config/state, never real `.envrc` contents.

## 10. Incremental scope and validation

Stage 0 — agree on boundaries/config:
- Finalize local file name/schema, initialization, missing-file behavior, and supported versus aspirational choices.
- Keep existing configuration/ownership working; no automatic migration.

Stage 1 — extract current implementations:
- Thin dispatch around current Stow, system-package scripts, mise tools, asdf runtimes, and existing settings/extensions scripts.
- Preserve current entrypoints as compatibility wrappers where practical.
- Validate safe failure, argument preservation, repeated execution, missing providers, and ignored local-file behavior.

Stage 2 — prove two independent compositions:
- Same ordinary package fixture deployable through Stow or mise in isolated targets, with no ownership overlap.
- Mise tools plus asdf runtimes: verify install requests, fresh-shell PATH, project version selection, and no duplicate automatic runtime installation.
- Confirm runtime migration can proceed independently from dotfile provider choice.

Stage 3 — one project-secret pilot:
- Choose a real requirement but use dummy credentials: explicit exec wrapper plus one backend.
- Verify intended recipient gets only required secrets; parent shell/unrelated tasks do not.
- Compare standalone provider/fnox execution with experimental mise grants before selecting either.

Stage 4 — only if evidence warrants:
- Add selected mise bootstrap resources, chezmoi/yadm evaluation or an adapter, additional secret backends, and finer resource-level ownership.
- Avoid an all-providers-by-all-platforms support matrix before any user needs it.

For this repository, validation should remain Bash-based and lightweight; do not introduce a Python framework or commit a new test suite without a separate decision. The prior package work explicitly removed added tests.

## 11. Open decisions for iteration

- Is one dotfile provider for all selected packages sufficient initially? Proposed yes; per-package mixed deployment is deferred.
- Exact config/template filenames and parser syntax; complete local choices versus a few platform defaults.
- How to initialize a new clone safely before the selected provider has been installed.
- Whether existing `profiles/` should become provider-neutral package sets or retain their current semantics behind adapters.
- Where native adapter configs live, and how template-specific sources coexist without duplicating ordinary files.
- How runtime/tool ownership is reflected in shared config and fresh-shell activation, not just installation.
- How to represent externally managed resources and which validations are safe on a work machine.
- Whether project-secret adapters belong in this personal repository, individual project repositories, or both via a documented executable interface.
- How project backend requirements interact with machine policy when they differ: fail with guidance, never silently substitute.
- Which exact provider versions/capabilities are supported; experimental mise/fnox remains opt-in.
- How to document provider transitions without implementing a generic automatic migration engine.
- Whether to persist explicit hardware package-set selection locally later; no automatic machine/hardware detection.

## 12. Decision log

- v0.1 (2026-10-28): Create a dedicated architecture spec linked to the existing investigation. User prefers a git-ignored local provider-selection file with a tracked starter template, not machine arguments on routine Make commands. No implementation or provider migration selected.
- v0.2 (2026-10-29): Publish under `docs/specs/` for cross-machine iteration; preserve the evaluation cross-link and remove dependence on a local-only historical plan. No adapters, local configuration, or migrations implemented.
