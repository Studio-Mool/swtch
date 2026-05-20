---
date: 2026-05-20
status: active
tags: [knowledge-system, precompact, hooks, mempalace]
---

# Decision: PreCompact hook expanded to mirror Stop hook pipeline

## Decision

The PreCompact hook in `~/.claude/settings.local.json` now runs three commands in
sequence before context compaction:

1. `mempalace hook run --hook precompact` (30s sync) — the existing checkpoint
2. `bash auto-capture.sh` (15s sync) — commits a session marker to `origin/context`
3. `mempalace mine convos` (async) — re-indexes conversation files into the sessions wing

This matches the Stop hook's three-command capture pipeline.

## Why

Context compaction was silently destroying session knowledge. The PreCompact hook fired
but only ran the MemPalace precompact checkpoint — which saves a snapshot to MemPalace
but does NOT push a session marker to `origin/context` or mine conversation files. The
wiki synthesis layer (Layer 4 of `/knowledge-sync`) was never triggered, so the first
half of a long session's context could be compacted away without any durable record
beyond MemPalace drawers.

The fix: mirror the Stop hook so that whatever fires after every response also fires
immediately before compaction. The last few turns are now captured durably before the
window shrinks.

## How to Find / Apply

Config lives in `~/.claude/settings.local.json` under the `PreCompact` key. The HTML
reference docs at `~/Claude/Personal/docs/knowledge-system-flow.html` and
`new-repo-setup-brief.html` are updated to reflect this. The flow graph now shows two
additional edges: PreCompact → auto-capture.sh and PreCompact → mempalace mine convos.

## Context

- Diagnosed 2026-05-20 after the first half of the swtch build session was lost to
  compaction
- Fix committed directly to `~/.claude/settings.local.json` (global, not repo-specific)
- HTML docs committed and pushed to `origin/context` on vt-learn Personal repo
</content>
</invoke>