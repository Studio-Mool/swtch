---
date: 2026-05-19
workspace: boston
branch: building-swtch
repo: studiomool-swtch
---

# Session: swtch — Full Implementation

## What we worked on

Completed the full implementation of **swtch**, a native macOS menu bar app that shows the active Claude Code account, usage progress, reset time, and account switching. All 13 tasks from the plan executed across two session segments (context compaction mid-session).

### Services completed

- **ChromeCookieService** — AES-128-CBC decryption of Cloudflare `cf_clearance` cookie from the Claude desktop Chromium SQLite database. Key derived via PBKDF2-SHA1("saltysalt", 1003 iter, 16 bytes). Fixed a `sqlite3_bind_text` lifetime hazard (SQLITE_STATIC → SQLITE_TRANSIENT) and gated `testEncrypt` with `#if DEBUG`.
- **UsageService** — Fetches `https://claude.ai/api/rate_limit_status` with Bearer token + cf_clearance cookie. Parses `resets_at`, `messages_remaining`, `messages_limit`. Derives `messagesUsed = limit - remaining`.
- **AppState** — `@MainActor` ObservableObject. Runs `authService.fetchAccount()` on a detached task (subprocess blocks I/O), awaits `usageService.fetchUsage()` concurrently.
- **Views** — PopoverView, AccountHeaderView, UsageView (with animated bar fill + reduced motion support), AccountSwitcherView, RefreshButton (PressScaleStyle: scale 0.97 on press).

## Decisions made

1. **Account switching via Chrome profiles** — replaced original Keychain-overwrite approach. When the user taps an account row, opens the matching Google Chrome profile (`open -a "Google Chrome" --args --profile-directory=<id>`). User manually authorises in Chrome. No credential storage in-app.

2. **KeychainService retained** — still needed to read the Bearer access token from `"Claude Code-credentials"` Keychain entry for API authentication. Not for writing/switching accounts.

3. **No Xcode build verification** — Xcode.app not installed; only Command Line Tools. All code written without compile-time verification. User will build in Xcode after installation.

4. **Deployment approach** — personal-use only, no hosting, no distribution. Build `.app` from Xcode → copy to `/Applications` → add to Login Items. First launch: `xattr -dr com.apple.quarantine /Applications/swtch.app`.

## Code changed

All on branch `building-swtch` (10 commits):

| Commit | Content |
|--------|---------|
| `3ae1d23` | Fix ShellRunner UTF-8 decode and AuthService error wrapping |
| `536c079` | KeychainService — credential read and JSON parsing |
| `8e0ccc5` | ChromeProfileService — enumerate Chrome profiles and open on switch |
| `fb9b650` | Fix KeychainService: wrap decode errors |
| `5b6da9b` | ChromeCookieService for Cloudflare bypass |
| `6d513dc` | Fix ChromeCookieService: SQLITE_TRANSIENT bind, gate testEncrypt with DEBUG |
| `dc158e6` | UsageService — rate limit API fetch + parse tests |
| `84f2806` | AppState and app entry point |
| `1ce5a54` | PopoverView and AccountHeaderView |
| `85026d1` | UsageView, AccountSwitcherView, RefreshButton — full popover UI |

## Problems encountered and fixes

- **sqlite3_bind_text lifetime hazard** — `nil` destructor (SQLITE_STATIC) on a temporary NSString pointer is a latent UAF/corruption bug. Fixed with `unsafeBitCast(-1, to: sqlite3_destructor_type.self)` (SQLITE_TRANSIENT).
- **UsageService subagent hit rate limit** — wrote `UsageService.swift` but couldn't write tests or commit before limit hit. Fixed inline by writing `UsageServiceTests.swift` and committing both.
- **`testEncrypt` shipped in release binary** — gated with `#if DEBUG`.
- **onChange(of:) two-parameter form** — macOS 14+ only; used single-parameter form for macOS 13 compatibility.
- **animatedPercent state placement** — must be at View struct level, not inside a nested function; `@State` only works on stored properties.

## Open questions

- Whether the actual API field names (`resets_at`, `messages_remaining`, `messages_limit`) match what the live claude.ai endpoint returns — can only be verified once Xcode is installed and the app runs for real.
- Whether `cf_clearance` is always present in the Claude desktop cookie store (depends on whether Claude desktop has made a recent Cloudflare-protected request).
