# swtch — Design Spec

**Date:** 2026-05-19  
**Status:** Approved  
**Scope:** Full app — macOS menu bar, account info, usage display, account switching

---

## Overview

A native macOS menu bar app that shows the currently active Claude Code account and its usage progress. On-demand refresh only. Personal use — no code signing or notarization required.

---

## Constraints

- macOS 13+, Swift + SwiftUI
- Personal use only — no signing, no sandboxing, no App Store
- No credentials stored or entered by the user — all auth via existing Keychain entries written by Claude Code CLI
- No continuous background polling — data fetched on explicit Refresh only

---

## Data Sources

| Data | Source | Notes |
|---|---|---|
| Active account (email, org, plan) | `claude auth status` CLI | JSON output |
| OAuth token | macOS Keychain | Service name TBD via spike |
| Usage count + limit + reset time | claude.ai usage API | Endpoint TBD via spike |
| All stored accounts | Keychain enumeration | Same service, multiple entries |

Two values (keychain service name, API endpoint) must be discovered before implementation. Both are resolved in Phase 1 (spike).

---

## Architecture

```
SwtchApp
└── MenuBarExtra
    └── PopoverView
        ├── AccountHeaderView       ← claude auth status
        ├── UsageView               ← claude.ai API
        ├── AccountSwitcherView     ← Keychain enumeration
        └── RefreshButton
```

**Services (each a standalone class/struct):**

- `AuthService` — shells `claude auth status`, decodes JSON
- `KeychainService` — reads active token, enumerates all stored accounts by service name
- `UsageService` — calls claude.ai usage endpoint with token, returns usage + reset time
- `AccountSwitcher` — updates active account in Keychain/config, triggers re-auth

**State:**

```swift
class AppState: ObservableObject {
    @Published var account: AccountInfo?
    @Published var usage: UsageInfo?
    @Published var accounts: [AccountInfo] = []
    @Published var loadState: LoadState = .idle  // idle | loading | error(String)
}
```

Single shared `AppState` passed through the view hierarchy. No global singletons.

---

## Popover Design

Dark vibrancy surface (`rgba(22,22,26,0.95)` + `backdrop-filter: blur`), 260pt wide, 11pt border radius. Four sections separated by 1px hairline dividers.

**Section 1 — Account header** (11pt padding)  
26pt avatar with blue colour ring, email in 12.5pt medium, org + plan in 11pt secondary.

**Section 2 — Usage** (8pt padding)  
28pt hero percentage as the visual anchor (gradient white), bar label right-aligned. 3pt gradient progress bar (blue → lighter blue) with glowing dot at the fill edge. Footer row: message count left, reset countdown right.

**Section 3 — Switch Account** (8pt padding)  
Section label in 10pt uppercase. Each account as a row: 18pt avatar, email, checkmark on active. Tap to switch.

**Section 4 — Refresh** (full-width, no side padding)  
`↻ Refresh` centred. `scale(0.97)` on `:active`. Triggers `AppState.refresh()`.

---

## Error States

**Usage fetch fails** — replace UsageView content with inline error message + "Retry" button. Account header remains visible.

**Keychain token not found** — show "No token found. Open Claude Code and sign in." in place of UsageView.

**`claude` CLI not found** — show "Claude CLI not found at expected path." with no retry (configuration issue, not transient).

**Account switch fails** — show inline error in AccountSwitcherView, revert selection optimistically.

---

## Account Switching Flow

1. User taps an inactive account row
2. UI optimistically shows checkmark on tapped row
3. `AccountSwitcher.switch(to:)` updates the active Keychain entry
4. `AuthService` re-reads `claude auth status` to confirm
5. `UsageService` fetches usage for the new account
6. On failure: revert checkmark, show inline error

---

## Implementation Phases

**Phase 1 — Discovery spike** (no UI)  
Identify Keychain service name, claude.ai API endpoint and response shape, token refresh behaviour. Output: constants file + documented findings.

**Phase 2 — Core app skeleton**  
`SwtchApp`, `MenuBarExtra`, `AppState`, `AuthService`. Popover opens and shows account info from `claude auth status`.

**Phase 3 — Usage display**  
`KeychainService` token read, `UsageService` API call, `UsageView` with hero number + bar + reset time. Error states.

**Phase 4 — Account switching**  
`KeychainService` enumeration, `AccountSwitcherView`, `AccountSwitcher`. Switch flow + error handling.

**Phase 5 — Polish**  
Animation (popover scale-in from menu bar icon, bar fill ease-out on load), `prefers-reduced-motion` respect, edge cases (zero usage, at-limit bar colour change to amber/red).

---

## Open Questions Resolved at Design Time

| Question | Answer |
|---|---|
| Distribution | Personal use only |
| Error behaviour | Inline error + retry |
| Account switching | Via Keychain, no credentials |
| Polling | None — manual refresh only |
| Reset time source | Same API call as usage |
| Popover style | Aesthetic B (usage hero, gradient bar) |
