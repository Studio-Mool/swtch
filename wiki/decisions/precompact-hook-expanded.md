---
date: 2026-05-20
status: active
tags: [swtch, project-status, conductor]
---

# Decision: swtch project retired — feature now native in conductor.build

## Decision

The swtch macOS menu bar app project is retired as of 2026-05-20. No further development.
Branch `building-swtch` is pushed to `origin` and preserved for reference but not merged
to main.

## Why

conductor.build shipped the same feature — Claude usage and rate-limit monitoring in a
native interface — making the standalone swtch app unnecessary. The user confirmed this
directly.

## How to Find / Apply

If asked about swtch or the menu bar app: it is retired. The implementation patterns
(Cloudflare cf_clearance decryption, PBKDF2 key derivation, SQLite cookie reading,
SwiftUI MenuBarExtra) are preserved on the `building-swtch` branch and documented in
`wiki/architecture/swtch.md` for future reference.

The swtch knowledge system wing (`studiomool-swtch`) remains active — MemPalace and the
graphify graph are still wired and functioning.

## Context

- Branch: `building-swtch` (pushed to Studio-Mool/swtch, not merged)
- Replacement: conductor.build native feature
- Memory record: saved in project memory at conversation level
</content>
</invoke>