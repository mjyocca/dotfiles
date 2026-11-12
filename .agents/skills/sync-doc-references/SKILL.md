---
name: sync-doc-references
description: Reviews dated upstream references and reconciles dependent workspace guidance. Use when asked to re-sync docs, refresh references, or audit stale sources by topic, path, or date; not as an automatic whole-repository rewrite.
---

# Sync Documentation References

Inputs: topic or repository path, optional maximum age in days, optional review
cutoff date, and audit-only versus update mode. Default to a 90-day maximum age
to bound review effort, not to declare older content wrong. If no topic or repository
path is supplied or clear from the request, ask for one before reviewing sources.
Audit-only requests never change files; ambiguous requests default to audit-only.

1. Read [documentation policy](../../../docs/instructions/documentation.md).
   Confirm today's UTC date and list sources and dependent local files within
   scope. Start from tracked files; include task-authorized new files explicitly.
2. Select sources whose last-synced date is at least the maximum age, or on/before
   the supplied cutoff; if both filters are supplied, use their union. Include
   missing, invalid, or future dates as unreviewed sources. Review requested sources or
   known compatibility conflicts regardless of age. A cutoff selects sources;
   it is not a date to stamp onto them.
3. Fetch official, version-appropriate pages and review the relevant content,
   not merely HTTP status or headers. For OpenCode V2, use V2 docs, not V1.
   Follow only links needed to resolve the selected claims. If access fails or
   content is incomplete/contradictory, report the gap and keep its date unchanged.
4. Compare source claims against dependent instructions/skills and actual tracked
   consumers. Locate consumers within the requested scope by searching the source
   URL and topic.
   Propose minimal corrections or link replacements. Upstream additions are not
   permission to add features, change configuration, or expand repository policy.
5. In update mode, apply only supported corrections. Record `Last synced` as the
   actual UTC review date only after reviewing the source and reconciling all
   listed local consumers; unchanged guidance can still receive a new review date.
   For partial review, do not advance a broader row's date. Add per-source dates
   beside links in the relevant reference page, not throughout `AGENTS.md`.
6. Validate local paths, links, version scope, and `git diff --check`. Summarize
   reviewed/unchanged/updated/blocked sources and unknown dates in the conversation.
   Do not append review histories, fetch logs, or machine status to shared docs.

This is an on-demand workflow, not a scheduler. Do not install tools, deploy
configuration, or commit as part of a reference refresh unless separately authorized.
