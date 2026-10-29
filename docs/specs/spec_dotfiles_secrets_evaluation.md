# Spec: Dotfile deployment and project secrets

Status: Research draft v0.6 — no migration selected
Research date: 2026-10-26
Repository handoff: 2026-10-29
Scope: Personal dotfiles on macOS/Zsh and Omarchy Linux/Bash; project environments across directories.

Related architecture proposal: [Local provider selection and domain adapters](./spec_local_provider_architecture.md) (created 2026-10-28). It explores independently selected implementations per domain through a git-ignored checkout-local file and a tracked starter template, without machine arguments on routine Make commands. This evaluation remains the research context; neither document authorizes implementation.

## 1. Intent and constraints

- Continue adopting mise for developer tools; runtime migration is already desired in principle but remains a separate implementation decision.
- Compare keeping GNU Stow with mise dotfiles, chezmoi, and credible alternatives. Keeping Stow is a valid outcome.
- Improve project-secret handling without assuming that replacing direnv alone improves security.
- Preserve Make/Bash entrypoints and readable configuration; avoid unnecessary tool-specific coupling.
- Allow incremental adoption, explicit local provider choices, independent components, and a practical exit path. Routine commands should read a git-ignored local selection file rather than require a machine argument; see the related architecture spec.
- Never put real credentials in this spec, examples, logs, GitHub issues, or research output.
- This is a research proposal, not implementation authorization. No installations, migrations, issue edits, or production-secret access have been performed for this investigation.

## 2. Verified repository baseline

- `packages/` mirrors home-directory paths and is deployed through GNU Stow.
- `profiles/macos` and `profiles/omarchy` select packages; `.stow-ignore.local` supports local exclusions.
- `make dotfiles`, `make stow`, Make targets, and Bash scripts provide orchestration.
- Pacman provisioning inputs are repository-only under `manifests/pacman/`, including explicit machine overlays. They are not dotfiles to deploy.
- `packages/mise/.config/mise/config.toml` currently declares developer tools, not dotfile deployment or secret sources.
- The shared Bash mise installer installs only repository-declared tool/version requests, independently of Stow deployment.
- Language runtimes remain in asdf / `packages/tool-versions/.tool-versions` until separately migrated.
- Tracked Zsh configuration activates mise and direnv and explicitly prioritizes asdf shims. An asdf/direnv compatibility helper also exists.
- The complete Bash activation path and actual per-project environment workflows have NOT yet been inventoried. Do not assume both platforms behave identically.
- Gitleaks is a useful preventive control, not a secret store or a guarantee against leakage.
- An earlier, local-only `spec_unified_package_management.md` informed historical planning but is not included in this handoff. Some ownership advice and manifest paths in it were superseded; current repository instructions and the baseline above are authoritative.

## 3. Related GitHub work

Read on the research date; issues remain unchanged.

| Issue | Current framing | Implication for this research |
| --- | --- | --- |
| [#11](https://github.com/mjyocca/dotfiles/issues/11) | Migrate Stow to mise | Reopen the architecture decision conceptually: compare before committing to replacement. |
| [#12](https://github.com/mjyocca/dotfiles/issues/12) | Migrate asdf runtimes to mise, after Stow migration | Dotfile migration is not a prerequisite; decouple scheduling and acceptance criteria. |
| [#13](https://github.com/mjyocca/dotfiles/issues/13) | Research mise package-manager plugins for extensions | Adjacent research, not a prerequisite for either decision. Custom plugin ownership needs a separate maintenance case. |

The user mentioned two issues; three open issues were returned. #11 and #12 are the directly relevant pair.
Claims in issue bodies about speed, conflict handling, or supply-chain protection are hypotheses, not comparative test results. Verification depends on backend, upstream artifacts, settings, and version.

## 4. Separate responsibilities

1. Tool/runtime installation and version selection: mise is the preferred direction.
2. Dotfile deployment: Stow, mise dotfiles, chezmoi, or another deployer.
3. Environment selection/loading: direnv, mise, or explicit command wrappers.
4. Secret source/storage: a password manager, encrypted files, OS keychain, or cloud secret manager.
5. Secret delivery: persistent file, interactive-shell environment, selected child process, or application-native credential mechanism.

These choices can be combined independently. Chezmoi is primarily a dotfile manager with encryption/password-manager integration, not a general replacement for directory-aware environment loading. Mise also implements actual dotfile deployment today; it is not limited to running deployment scripts.

## 5. Security requirements and threat model

Confirmed user context (v0.2): project secrets generally live as plaintext in direnv `.envrc` files. The desired improvement is encrypted/vault-backed storage, with 1Password or another vault preferred over plaintext files that can accidentally be committed. Directory auto-loading versus explicit command-scoped delivery remains undecided. Do not read existing `.envrc` contents during inventory; inspect structure using dummy fixtures instead.

Evaluate “more secure” against specific risks:

| Risk | Desired control | Residual limitation |
| --- | --- | --- |
| Plaintext committed or synced accidentally | Commit references or ciphertext; scan changes | References/metadata can still reveal project details. |
| Secrets persist in local `.env` or generated config | Prefer on-demand retrieval; avoid persistent plaintext where possible | Some applications require a file; define permissions, location, backup exclusions, and cleanup. |
| Every program in an interactive shell inherits credentials | Prefer command/task-scoped delivery; nonsecret values may auto-load | Recipient subprocesses still inherit credentials unless explicitly stripped. |
| Untrusted repository code reads credentials | Explicit config review, narrow vault access, no blanket trust | A command granted credentials can exfiltrate them. Trust prompts are not a sandbox. |
| Logs, diffs, shell history, debug tools leak values | No values in argv; no tracing; test redaction with dummy data | Redaction is incomplete and does not constrain program behavior. |
| Lost device/key or unavailable provider | Recovery plan, protected identities, documented offline behavior | Offline caches and long-lived sessions increase exposure. |
| Old ciphertext remains in Git history | Rotate underlying credentials when access is revoked | Removing a recipient does not revoke their ability to decrypt old ciphertext with an old key. |

Neither encryption at rest nor process-scoped environment injection protects against a compromised recipient application or a sufficiently privileged local attacker. Same-user process access, crash dumps, editor/agent access, caches, temporary files, and provider authentication scope require review. No tool here is assumed to provide that isolation automatically.

## 6. Dotfile deployment shortlist

| Option | Fit for this repository | Tradeoff / question |
| --- | --- | --- |
| Keep GNU Stow + Make/Bash | Existing package tree, simple source-of-truth, edits through links update the repository; no deployment database | Templates/copies/secret retrieval require separate components. Do we actually need them? |
| mise dotfiles | Symlink, symlink-each, copy, template, permissions, variants, diff/status/unapply; can coexist with plain source files | More coupling to mise config and state; verify installed-version support and precise ownership/removal semantics. |
| chezmoi | Rich machine-aware templates, permission attributes, diff/apply workflow, encryption and password-manager functions | Source-state naming/template conventions and edit/apply workflow differ from Stow. Generated secret files remain plaintext at the destination. |
| yadm | Git-centric management of live files; alternatives/templates and encrypted confidential files | Home-as-worktree workflow differs from package trees; encryption is not runtime-scoped secret delivery. |
| Dotbot | Explicit declarative links plus creation/shell actions; retains ordinary source files | Likely incremental benefit over existing Stow/Bash is small; Python runtime and optional plugins add dependencies. |

Secondary candidate only if requirements justify the complexity: Nix Home Manager. Research its store/secrets model before considering any secret-bearing configuration; reproducible home configuration is a broader change than this project's current scope.

Important verified mise behaviors: copy/template entries can overwrite destination content without `--force`; links pointing elsewhere can be repointed; removing a declaration does not automatically remove its target. `symlink-each` uses recorded ownership state. Dry-run does not render dotfile templates, but other trusted config expressions can still run. Do not treat “better conflict handling” as a universal property.

For chezmoi, target files remain usable without the manager, and archive/dump provide exit mechanisms. However, exporting rendered files loses template intent and can include plaintext secrets; an export is not automatically safe to commit.

### Dotfile feature parity clarification (v0.5)

Mise DOES support templating. Template availability alone is not a reason to prefer chezmoi. Compare workflow, template capabilities, safety, and integration instead. This table describes documented high-level capabilities, not identical semantics or installed-version compatibility.

| Capability | mise dotfiles + optional bootstrap | chezmoi | yadm |
| --- | --- | --- | --- |
| Primary model | Deploy sources as links/copies/templates, or track live files in place | Source state rendered/applied into target files | Git manages live dotfiles in place |
| Templating | Tera templates, variables, conditionals/functions | Go templates with extensive functions and machine/user data | Built-in limited processor; optional external engines including Jinja2/esh |
| Machine differences | OS/architecture/profile variants, config environments, selectable groups | Templates, data and ignore rules for machine-specific output | Alternate files/templates by OS, architecture, class, host and other conditions |
| Explicit machine selection | Profiles/groups/config environments | User-defined template data/configuration | Explicit local classes; can avoid hostname-based selection |
| Symlinks | File/directory links and per-file tree linking | Supported target type; regular-file deployment is typical | Ordinary tracked symlinks and automatically selected alternate links |
| Regular/generated files | Copy, template and inline content | Regular files, templates and permission attributes | Live files; templates generate alternate output |
| Partial-file management | Blocks, lines and structured merges | Modify scripts/templates and structured-value helpers | Custom scripts or application includes; not an equivalent declarative feature |
| Preview/drift | Dot diff/status/dry-run; bootstrap plan has narrower resource coverage | Diff/status/dry-run/verify | Git diff/status show tracked-file changes; not equivalent to a rendered-target deployment plan |
| History/recovery | Optional separate tracked-file history/checkpoints and rollback | Git for source history; merge/re-add workflow for target edits | Native Git history/reset/revert workflows; generated templates need separate care |
| Secret integration | Secret-aware templates/bootstrap inputs; separate mise env and fnox runtime delivery | Built-in password-manager template functions and encrypted source files | Encrypted archive via GPG/OpenSSL; external vault access requires custom integration |
| Machine provisioning | Declarative packages/files/services/repos/settings/tools via optional bootstrap | Scripts including run-once/on-change; package setup can be scripted | User-provided bootstrap executable and hooks |
| Ongoing tool/runtime management | Native mise responsibility, independent of dotfiles | Delegate to mise or another installer/manager | Delegate to mise or another installer/manager |
| Everyday edits | Direct for symlinks/tracked files; apply/capture for copied/generated files | Edit source then apply; supports capture/merge of live-file edits | Edit live tracked files then use Git; generated outputs are not template sources |
| Dependencies/coupling | mise binary, TOML/Tera; optional deployment/history state | chezmoi binary, source attributes/Go templates; provider CLIs where needed | Bash/Git, plus encryption or external template tools when used |

Security boundary: all can leave plaintext in live files; none of these dotfile features makes a generated credential file ephemeral or isolates it from same-user programs. Runtime secret delivery remains a separate comparison.

Implication for this repo: mise can cover both our Stow-style deployment and much of Make/Bash provisioning. Chezmoi is the focused source-to-target alternative, not the only templating-capable one. Yadm's strongest distinction is live-file/Git workflow, not richer provisioning. Retaining Make/Bash remains possible with each; declarative format and state still create migration costs.

## 7. Secret/environment shortlist

| Option | What it solves | Assessment to validate |
| --- | --- | --- |
| Keep direnv + external provider | Retains directory-aware env loading; can fetch instead of storing secrets locally | Valid baseline, not inherently insecure. Shell-wide export still exposes values to unrelated child processes. |
| mise `[env]` + encrypted SOPS/age values | Unified directory-aware environment; ciphertext can live in Git | Encryption improves storage, but decrypted values still reach the activated shell and everything loading that environment. |
| Provider CLI wrapper, e.g. 1Password `op run` | References in config; secrets supplied to a selected subprocess | Strong low-complexity candidate IF 1Password is the desired source. Authentication and vault scope still matter. |
| SOPS + age/KMS with explicit execution | Provider-independent encrypted project files and separate key custody | Compare supported execution modes, key recovery, rotation, metadata exposure, and CI authentication. Details not yet tested. |
| fnox standalone | Multiple provider references/encrypted values behind one CLI; explicit exec and optional directory loading | Promising provider-neutral adapter; investigate maturity, access scope, trust rules, caching, and exit costs. Avoid automatic shell loading if narrowing exposure is the goal. |
| mise + fnox per-task grants | Only named keys reach the task; ordinary shell/env commands receive none from the grants | Upstream currently marks integration EXPERIMENTAL; docs require mise >= 2026.10.4 and fnox >= 1.39.0. Pilot only until compatibility and security behavior are tested. |
| Chezmoi secret templates | Retrieves secrets when generating application config | Useful for necessary files, not the default solution for ephemeral project credentials. Restrict to explicit file requirements. |

Cloud/team platforms (Doppler, Infisical, Vault/OpenBao, cloud secret managers) remain conditional candidates if collaboration, audit, dynamic credentials, or production delivery are requirements. Avoid introducing a service solely for local dotfile deployment without a demonstrated need.

### Vault backend follow-up (v0.3)

- User already uses 1Password but asks whether Vault could replace it as the backend. HashiCorp Vault is the working interpretation, not yet confirmed.
- Verified upstream fnox has a `vault` provider for Vault KV secrets, using the `vault` CLI and authenticated Vault access. Committed config holds paths/field references; actual values remain in Vault.
- The same provider can feed standalone fnox execution or mise/fnox task grants. Neither `.envrc` nor direnv is required.
- Authentication remains a bootstrap requirement: use an appropriate login flow and narrowly scoped policies/short-lived tokens; never commit a token. Provider-scoped `credential_command` can perform on-demand login rather than requiring a globally exported token. Review credential caching and actual token lifetime separately.
- Dynamic Vault credentials use a separate fnox lease backend; it has not yet been researched/tested here. OpenBao compatibility is not established by the HashiCorp Vault provider documentation alone.
- Operational comparison: an existing organizational Vault is a strong candidate; introducing a new self-hosted Vault adds server availability, TLS, initialization/unsealing, backups, auth/policy management, and recovery obligations compared with an existing 1Password account.
- Next question: is Vault already available, or would this require running/procuring one?

Verified caveats:
- direnv requires authorization for `.envrc` execution and unloads its environment changes when leaving the directory. Replacing it is not automatically a security upgrade.
- Mise `[env]` decryption is not the same as per-task grants. `mise env` intentionally prints resolved values; `--redacted` selects sensitive variables but STILL prints their plaintext values.
- Mise/fnox task grants do not sandbox the task or prevent same-user access. Task definitions can change which secrets are requested.
- Upstream mise normal-mode commands such as `mise run` can implicitly trust configuration; paranoid mode changes trust behavior. Audit the actual pinned version/settings before relying on review gates.
- Redaction coverage differs across runners: mise exec/fnox exec do not redact child output; raw/interactive task output can bypass masking. Test the intended invocation, not just the advertised feature.
- Provider CLI credentials are themselves secrets. A narrowly scoped child environment does not prevent other programs from independently querying an already-authorized broad vault session.

## 8. Architecture candidates, not decisions

A. Minimal change: Stow + mise tools/runtimes + provider CLI for sensitive commands. Retain direnv or use mise only for nonsecret project variables.
B. Unified deployment: mise dotfiles + mise tools/runtimes + explicit provider CLI or fnox delivery.
C. Specialized deployer: chezmoi + mise tools/runtimes + explicit provider CLI or fnox delivery. Use chezmoi secret templates only for applications that require files.

Provisional preference: evaluate A as the baseline, B and C as challengers. Do not migrate deployment merely to gain secret handling. Keep Make/Bash as stable entrypoints, but recognize that wrappers alone do not eliminate configuration-format lock-in.

## 9. Evaluation criteria

Before numerical scoring, agree on priorities. Suggested order:
1. Security: plaintext location/lifetime, least privilege, trust boundary, recovery.
2. Reversibility: ordinary sources, documented export, recoverable key custody, no undocumented deployment state dependency.
3. Daily workflow: edit-through-link versus edit/apply; app-written changes; editor and shell integration.
4. macOS/Omarchy parity: bootstrap, Bash/Zsh, offline behavior, explicit machine selection.
5. Operational cost: dependencies, authentication prompts, provider accounts, CI setup, ongoing custom code.
6. Safety: accurate preview, unmanaged-file preservation, stale-target cleanup, rollback.
7. Maturity: released-version support, experimental flags, upgrade/deprecation policy, maintenance evidence.

## 10. Proposed experiments — not executed

Use dummy credentials and isolated target homes; some tools still use real XDG state/config unless explicitly redirected, so isolation must include those paths and provider sessions.

Dotfiles fixture:
- Plain file, whole-directory link, mixed managed/unmanaged directory, executable, private-permission file, and paths with spaces.
- One explicit platform/machine variant and one app-modified file.
- Existing-file conflict, wrong symlink, deleted source, removed declaration, changed destination, lost deployment state.
- Compare preview, repeat apply, edit synchronization, uninstall/rollback, and export to plain files.
- Never let two deployers own the same target during a pilot.

Secrets fixture:
- A nonsecret variable plus dummy dev/prod secrets, with one intended recipient command.
- Confirm parent shell and unrelated task/dependency see no scoped secret; intended subprocess does.
- Test missing/locked provider, changed config, nested directories, symlinked projects, and worktrees.
- Check generated files, diffs, logs, debug/raw modes, environment caches, and cleanup after interruption.
- Test offline behavior, key recovery, credential rotation, and a CI-shaped noninteractive run.
- Record exact versions, settings, provider authentication scope, evidence, and residual risks.

Exit gates: demonstrated benefit over baseline, no unmanaged-file loss, acceptable workflow on both platforms, no production secrets in the pilot, and a documented reversal procedure.

## 11. Open questions for the next iteration

1. Confirmed: secrets generally reside in plaintext `.envrc` files today, and 1Password is already used but not for workspace secret delivery. Preferred direction: 1Password or another vault. Still open: which vaults are appropriate, whether Vault is available, and the required degree of provider-neutral delivery.
2. Is explicit `make`/CLI invocation acceptable for secrets, or is automatic directory-entry loading essential? Could only nonsecret variables auto-load?
3. Which consumers need variables versus persistent files: local servers, CLI commands, IDEs, containers, SSH, background services, agents, CI?
4. Is this personal-only or shared with coworkers; are offline access, audits, revocation, and dynamic credentials required?
5. What concrete Stow pain exists: host differences, missing templates, conflicts, app-written files, or merely interest in consolidation?
6. What experimental-feature tolerance is acceptable? Does avoiding provider lock-in also mean avoiding paid hosted secret storage?
7. Repository home is now `docs/specs/`. Continue research here and in the linked architecture spec; local planning copies are not the shared source of truth.

## 12. Sources and evidence boundaries

Primary documentation checked on the research date. Live docs may describe versions newer than either machine has installed. These are documented capabilities, not hands-on validation or independent security audits. Installed versions, release history, and comparative performance remain unverified.

- GNU Stow manual: https://www.gnu.org/software/stow/manual/stow.html
- mise managed dotfiles: https://mise.jdx.dev/dotfiles/managed.html
- mise dotfiles approaches/groups/history: https://mise.jdx.dev/dotfiles.html
- mise bootstrap scope/order/preview: https://mise.jdx.dev/bootstrap.html
- mise environments: https://mise.jdx.dev/environments/
- mise secrets: https://mise.jdx.dev/environments/secrets/
- mise/fnox integration and minimum versions: https://mise.jdx.dev/environments/secrets/fnox.html
- mise trust/security: https://mise.jdx.dev/security.html
- chezmoi password-manager behavior: https://www.chezmoi.io/user-guide/password-managers/
- chezmoi file management: https://www.chezmoi.io/user-guide/manage-different-types-of-file/
- chezmoi exit mechanisms: https://www.chezmoi.io/user-guide/advanced/migrate-away-from-chezmoi/
- direnv loading and authorization: https://direnv.net/
- 1Password subprocess delivery: https://developer.1password.com/docs/cli/reference/commands/run/
- fnox overview: https://fnox.jdx.dev/
- fnox HashiCorp Vault provider/authentication: https://fnox.jdx.dev/providers/vault.html
- SOPS overview/docs: https://getsops.io/ and https://getsops.io/docs/
- yadm workflow: https://yadm.io/docs/overview
- yadm alternatives/templates/encryption/bootstrap: https://yadm.io/docs/alternates , https://yadm.io/docs/templates , https://yadm.io/docs/encryption , https://yadm.io/docs/bootstrap
- Dotbot features/runtime: https://github.com/anishathalye/dotbot

## 13. Research handoff and next steps

### Confirmed user context

- Already uses 1Password, but has not configured project/workspace secret delivery through it.
- Currently keeps project secrets primarily in plaintext `.envrc` files loaded by direnv.
- Wants vault-backed or encrypted storage to reduce accidental plaintext commits.
- Asked explicitly about eliminating BOTH `.envrc` and direnv; retaining either is not a requirement. Whether explicit command invocation is acceptable remains open.
- Asked about Vault as an alternative backend. HashiCorp Vault is the current interpretation; existing access or willingness to host it is unknown.
- Is sold on mise for tool management, but values independent components and Make/Bash entrypoints. No commitment to replace Stow or to adopt chezmoi/fnox.

### Options to carry forward

| Candidate | Dotfiles | Environment / secret delivery | Storage | Outstanding research |
| --- | --- | --- | --- | --- |
| Minimal-change baseline | Stow | Make/Bash wrapping `op run`; optionally mise for nonsecret env | Existing 1Password | Project reference format, authentication/vault scope, prompts, offline behavior, CI and editor integration. |
| mise-integrated, existing vault | Stow initially; deployment decision independent | mise tasks with fnox explicit grants | 1Password via fnox | Exact-version availability, experimental risk, per-task isolation limits, provider authentication and caching. |
| mise-integrated, Vault | Stow initially; deployment decision independent | mise tasks with fnox explicit grants | HashiCorp Vault KV | Existing service versus new hosting, policies/auth/token lifecycle, provider CLI dependencies, outage/recovery, separate dynamic lease support. |
| Provider-neutral command wrapper | Any independently chosen deployer | Make/Bash wrapping standalone fnox execution | 1Password or Vault | Secret selection/filtering, trust and output handling, portability, migration between providers without changing scripts. |
| Encrypted-file alternative | Any independently chosen deployer | Explicit SOPS execution or mise env loading | SOPS/age ciphertext with separately protected keys | Key custody/recovery, rotation and Git-history exposure, process versus shell scope, no central-vault revocation equivalent. |
| Keep loader, remove plaintext | Stow or another deployer | direnv retrieves vault secrets | 1Password or another vault | Useful comparison baseline only: still uses `.envrc`/direnv and usually exports secrets into the shell. |

Mise dotfiles and chezmoi remain deployment challengers to evaluate against Stow; neither is a prerequisite for any secret-delivery candidate above. Chezmoi secret templating is a separate, conditional solution for applications that require credential files, not a replacement for scoped runtime delivery.

### Next research sequence

1. Clarify workflow constraints: explicit invocation versus automatic loading, CLI/server/editor/container consumers, personal versus shared projects, offline and CI needs, and Vault availability.
2. Check release/install compatibility on macOS and Omarchy without dumping effective environments or reading real secret files. Record exact versions and distinguish released features from live documentation.
3. Compare 1Password and Vault authentication, least-privilege boundaries, session/token lifetime, local caching, revocation, cost, and operations. Separately assess fnox as an optional adapter rather than treating it as the vault itself.
4. Design dummy-secret pilots for provider CLI execution, standalone fnox, and mise/fnox grants. Obtain implementation approval before executing pilots or installing tools; planning alone does not authorize those changes.
5. Compare Stow/mise/chezmoi using the same isolated file fixture; quantify the actual missing capability before proposing migration.
6. Record evidence, rejected options, unresolved risks, and rollback steps. Only then propose issue updates and a separately approved staged implementation.

## 14. Decision log

- v0.1: Separate tool migration, file deployment, secret storage, and delivery decisions. Preserve Stow as baseline. No replacement selected. No GitHub issues edited.
- v0.2: Record plaintext `.envrc` as the current secret source and vault-backed storage as the desired improvement. Prioritize comparing 1Password `op run`, mise/fnox with a 1Password provider, and retained direnv with vault retrieval. Mise SOPS/age remains an encrypted-file alternative, not equivalent to centrally managed vault access. Upstream capabilities were researched; no provider integration has been tested.
- v0.3: Record existing 1Password usage and research HashiCorp Vault as an alternative fnox backend. Backend choice remains open; no Vault instance or integration is assumed to exist.
- v0.4: Consolidate user context, concrete architecture combinations, open research questions, and an ordered research handoff. Explicitly preserve the option to remove both `.envrc` and direnv without changing dotfile deployment.
- v0.5: Add high-level mise/chezmoi/yadm feature parity, explicitly correcting any implication that templating uniquely favors chezmoi. Include optional mise bootstrap and distinguish provisioning from dotfile deployment and runtime secrets.
- v0.6 (2026-10-29): Publish under `docs/specs/` for cross-machine iteration, retain relative links to the architecture spec, record local provider-selection preference, and resolve stale handoff questions. Local planning copies are no longer the shared source of truth. No implementation selected.
- Next iteration: answer source/workflow questions, narrow to two or three architecture combinations, then define exact-version dummy-data pilots.
