---
confidence: high
sources: [2026-05-19-swtch-boston]
last_updated: 2026-05-19
---

# swtch — Architecture

[[decisions/account-switching-chrome-profiles]]

## What it is

Native macOS menu bar app (SwiftUI `MenuBarExtra`, macOS 13+, no App Sandbox) that shows:
- Active Claude Code account (email, org, plan)
- Usage progress bar with hero % and reset countdown
- Account switcher (opens Chrome profiles)
- Refresh button

No hosting, no server, no subscription cost. Entirely local.

## Stack

Swift 5.9+, SwiftUI, XCTest, Security framework, CommonCrypto, SQLite3, URLSession, Process.
No third-party dependencies.

## Service layer

| Service | Purpose |
|---------|---------|
| `AuthService` | Runs `claude auth status --json` via `Process`, parses `AccountInfo` |
| `KeychainService` | Reads Bearer token from `"Claude Code-credentials"` Keychain entry (written by Claude Code CLI) |
| `ChromeCookieService` | Decrypts `cf_clearance` from Claude desktop's Chromium SQLite cookie store |
| `UsageService` | Calls `https://claude.ai/api/rate_limit_status` with Bearer + cf_clearance |
| `ChromeProfileService` | Enumerates Chrome profiles from `~/Library/Application Support/Google/Chrome/<Profile>/Preferences` |

## Cloudflare bypass

Claude.ai API blocks raw URLSession requests. Bypass:
1. Read `"Claude Safe Storage"` Keychain entry (service=`"Claude Safe Storage"`, account=`"Claude"`)
2. PBKDF2-SHA1(password, salt=`"saltysalt"`, 1003 iter, 16-byte key)
3. Open `~/Library/Application Support/Claude/Cookies` (Chromium SQLite) — copy to tmp first (WAL lock)
4. `SELECT encrypted_value FROM cookies WHERE name = ? AND host_key LIKE '%claude.ai%' LIMIT 1`
5. Strip 3-byte `v10` prefix → AES-128-CBC decrypt (IV = 16×`0x20`)

## AppState data flow

```
@main SwtchApp
  └─ MenuBarExtra(.window)
       └─ PopoverView.environmentObject(appState)
            ├─ AccountHeaderView   ← appState.account
            ├─ UsageView           ← appState.usage + appState.loadState
            ├─ AccountSwitcherView ← appState.chromeProfiles
            └─ RefreshButton       ← appState.loadState
```

`AppState.refresh()` is `@MainActor async`:
- Runs `authService.fetchAccount()` on a detached task (subprocess blocks I/O — must not block main thread)
- Awaits `usageService.fetchUsage()` (already async)
- Sets `account`, `usage`, `chromeProfiles`, `loadState` on main actor

## Local deployment

1. Build from Xcode (`Cmd+B` or `Cmd+R`)
2. Copy `.app` from DerivedData to `/Applications`
3. `xattr -dr com.apple.quarantine /Applications/swtch.app` (Gatekeeper bypass, first launch)
4. System Settings → General → Login Items → add `swtch.app`

## Key constants

```swift
Constants.Keychain.credentialsService = "Claude Code-credentials"
Constants.Keychain.safeStorageService = "Claude Safe Storage"
Constants.Keychain.safeStorageAccount = "Claude"
Constants.Cookies.dbPath = "~/Library/Application Support/Claude/Cookies"
Constants.Cookies.pbkdf2Salt = "saltysalt"
Constants.Cookies.pbkdf2Iterations = 1003
Constants.API.rateLimitStatus = "https://claude.ai/api/rate_limit_status"
Constants.CLI.claudePath = "/Users/VrushankPersonal/.local/bin/claude"
```
