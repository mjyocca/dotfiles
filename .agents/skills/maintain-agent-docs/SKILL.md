---
name: maintain-agent-docs
description: Maintains concise workspace AGENTS.md, documentation, and skills. Use when creating, editing, or auditing shared guidance, removing duplication, or deciding whether session findings belong in docs; not for ordinary configuration changes alone.
---

# Maintain Agent Documentation

1. Read [documentation policy](../../../docs/instructions/documentation.md).
   Inventory the relevant tracked guidance with `git ls-files` and inspect the
   working diff before editing. Include new files explicitly within the task.
2. Identify the behavior the proposed text changes and its canonical owner.
   Check whether it is durable, repository-specific, actionable, and already
   documented. Keep machine observations and session progress out of shared docs.
3. Choose the smallest appropriate destination using the policy. Amend or link
   existing guidance rather than append another explanation; preserve unrelated
   changes and safety constraints. Do not broaden a focused edit into a full audit.
4. For agent behavior or skill-format claims, consult only relevant sources in
   [agent guidance references](../../../docs/reference/agent-guidance.md).
   Preserve vendor/version differences; do not assume discovery, precedence, or
   instruction syntax is identical across tools. Use `sync-doc-references` when
   source review is due; do not load every linked manual for an editorial change.
5. Keep skills focused on one workflow with a specific trigger description,
   explicit inputs/results, and direct links to optional supporting material.
   Keep policy in its canonical document, not duplicated in each skill.
6. Verify paths, actual command consumers, links, skill metadata, duplicate IDs,
   and `git diff --check`. For skill changes, manually walk through at least
   three representative prompts, including a negative trigger or failure case.
   Report walkthroughs separately from actual fresh-session/model evaluations.

Return a concise summary of changes, intentional omissions, validation, and any
unresolved claims. Documentation work does not authorize provisioning, deployment,
external skill installation, or commits.
