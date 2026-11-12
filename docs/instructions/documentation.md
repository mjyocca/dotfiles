# Documentation and Skill Policy

Read before editing or auditing documentation, agent instructions, or skills.
This file owns repository-specific audience, placement, and verification policy.
`sync-doc-references` owns date-based upstream review here. Do not install missing
skills as part of a documentation edit.

## Content Ownership

| Content | Canonical location |
|---|---|
| Human orientation, supported starting path, risks, and navigation | `README.md` |
| Lifecycle commands, previews, deployment, and environment migration procedures | `docs/commands.md` |
| Human task guides, including project secrets setup | Existing topic guide, such as `docs/secrets.md` |
| Repository-specific structure, boundaries, and rationale | `docs/architecture/` |
| Daily utility reference and categorized upstream links with source-review dates | `docs/reference/` |
| Essential repository-wide constraints and task routing | `AGENTS.md` |
| Topic-specific repository rules and safe verification | `docs/instructions/` |
| Workspace-specific reusable task procedures | `.agents/skills/<id>/SKILL.md` |
| Machine state, task progress, and one-off investigation records | Active task/session records, not persistent guidance |

README and human guides form the shared knowledge base for people and agents.
`docs/instructions/` holds agent-facing constraints, not general task guides.

## Admission and Editing

- Before editing, inventory relevant tracked guidance with `git ls-files` and
  inspect the working diff. Include task-authorized new files explicitly; ignored
  plans, scratch files, and generated dependencies are not policy inputs.
- Keep portable authoring workflows in the shared skills project, not a local
  same-ID copy. Keep this workspace's rules here; do not require a global skill
  to be installed for the policy to remain usable.
- Configuration owns declared values; command definitions establish implemented
  behavior. Explain their meaning without copying inventories or upstream manuals.
  Label examples and proposed behavior; report contradictions with policy or accepted
  intent rather than silently choosing a new truth.
- Keep one canonical owner for each fact, procedure, or rule. Amend or link it before
  adding another page. Shared policy can have one human-readable owner; skills and
  agent instructions link to it. Repeat critical warnings beside affected actions
  when needed, not entire procedures. Do not duplicate `AGENTS.md` for compatibility.
- Keep `AGENTS.md` a short entrypoint with task-based routes to topic guidance.
  If required guidance is unavailable, report the gap before the affected action.
- Preserve safety rules and durable migration procedures; keep machine progress
  and task plans out of persistent guidance.

## Skills and Sources

- Explicitly reference and route to skills maintained in this repository when
  relevant, such as `package-management` and `sync-doc-references`.
- References to tool-provided skills must say "if available" and provide a fallback
  to installed help or version-matched documentation. Do not assume a tool will keep
  shipping a skill, install a missing one, or create a local copy to replace it.
- Do not name or route to other external/global skills not included in this project.
  Available skills describe their own applicability; repository documentation must
  remain usable independently of a user's installed skill collection.
- For host discovery or configuration changes, consult installed help and relevant
  [host documentation](../reference/tools.md#agent-tooling). Upstream material does
  not override local policy or authorize execution.
- Keep per-source `Last synced` dates beside references. They attest to content
  review and reconciliation with local consumers, not upstream publication dates
  or live-machine verification. Do not use HTTP `Last-Modified` as that evidence.

## Verification

Check affected paths, command consumers, links and anchors (including inbound
links after moves), skill metadata/discovery, and `git diff --check`; check new
files explicitly. Do not run provisioning to validate documentation.

Walk through a relevant and an unrelated task when changing agent routing. Check
that human readers can find operational guidance without going through `AGENTS.md`,
and that required safety conditions survive partial reads. Report static checks
separately from runtime or live skill tests. Reading guidance does not authorize
executing its commands or deploying changes.
