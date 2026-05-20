---
date: 2026-05-20
workspace: boston
branch: building-swtch
repo: studiomool-swtch
---

# Session: swtch — PreCompact fix, HTML docs, project retirement

## What we worked on

Continuation from compacted context. Picked up with all swtch views already written and
committed. Session focused on knowledge system maintenance and project closure.

### PreCompact hook wiring

Diagnosed that the PreCompact hook in `~/.claude/settings.local.json` only ran
`mempalace hook run --hook precompact` — a checkpoint that saves a MemPalace snapshot but
does NOT push a session marker to `origin/context` or re-mine conversation files. The
wiki synthesis layer was therefore never triggered before context compression, causing the
first half of the previous session's context to be lost to compaction without being
documented.

**Fix applied:** Added `auto-capture.sh` (15s sync) and `mempalace mine convos` (async)
to the PreCompact hook, mirroring the Stop hook's three-command pipeline. PreCompact now
runs four commands total: precompact checkpoint → auto-capture → mine convos.

### HTML reference docs updated

Two canonical HTML knowledge system docs in `~/Claude/Personal/docs/` updated to reflect
the corrected PreCompact wiring:

- `knowledge-system-flow.html` — Phase 1 prose, PreCompact node detail, two new D3 edges
  (PreCompact → auto-capture.sh, PreCompact → mempalace mine convos), machine-readable
  JSON spec updated.
- `new-repo-setup-brief.html` — "Already global" section updated to describe PreCompact
  as a 3-command hook.

Committed and pushed to `origin/context` on the vt-learn Personal repo.

### Commits and pushes

- swtch `building-swtch`: pushed 15 commits (all swtch app code + graphify AST cache)
- Personal `context`: committed PreCompact-aware HTML docs + Setu design system wiki page

### Project retirement

User confirmed swtch is retired. The feature it was building — Claude usage/rate-limit
monitoring in a macOS menu bar — is now shipped as a native feature in conductor.build.
No further development needed on the `building-swtch` branch.

## Decisions made

1. **PreCompact hook mirrors Stop hook** — The three-command capture pipeline
   (precompact checkpoint, auto-capture.sh, mine convos) now fires both on every response
   AND immediately before context compaction. This closes the gap where context lost to
   compaction was never documented. See `decisions/precompact-hook-expanded.md`.

2. **swtch retired** — Project closed 2026-05-20. conductor.build now provides the same
   feature natively. Branch `building-swtch` is pushed and archived but not merged.
   See `decisions/swtch-retired.md`.

## Code changed

| Location | Change |
|----------|--------|
| `~/.claude/settings.local.json` | Added auto-capture.sh + mine convos to PreCompact hook |
| `~/Claude/Personal/docs/knowledge-system-flow.html` | Updated PreCompact detail, Phase 1 prose, D3 edges, JSON spec |
| `~/Claude/Personal/docs/new-repo-setup-brief.html` | Updated PreCompact description in "Already global" section |

## Problems encountered and fixes

- **Knowledge lost to compaction** — First half of previous session compacted away because
  PreCompact hook only ran mempalace precompact (no auto-capture, no mine). Fixed by
  expanding the hook to mirror the Stop hook pipeline.

- **DS_Store files staged accidentally** — When committing Personal repo untracked
  content, `proposals/.DS_Store` and `raw/.DS_Store` were staged alongside the real wiki
  file. Unstaged with `git restore --staged` before committing.

## Open questions

- Whether swtch's `cf_clearance` + PBKDF2 cookie approach would have worked against the
  live claude.ai API — never tested with Xcode installed. Likely yes but unverified.
</content>
</invoke>