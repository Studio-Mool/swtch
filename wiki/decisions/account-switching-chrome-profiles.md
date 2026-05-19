---
date: 2026-05-19
status: active
tags: [swtch, account-switching, chrome, ux]
---

# Decision: Account Switching via Chrome Profiles

## Decision

When the user taps an account row in the AccountSwitcherView, open the matching Google Chrome profile using `open -a "Google Chrome" --args --profile-directory=<id>`. The user manually authorises Claude in the browser. The app does not store, overwrite, or manage credentials.

## Why

The original plan was to overwrite the `"Claude Code-credentials"` Keychain entry with the target account's credentials — enabling seamless switching without user interaction. This was replaced because:

1. User has authenticated Claude Code CLI using Google OAuth (Gmail). Overwriting Keychain entries would require storing credentials we don't have at hand-off time.
2. The browser-based OAuth flow is more reliable and future-proof than credential storage.
3. Simpler implementation: `ChromeProfileService.open(_:)` is 5 lines of code with zero security surface.

## How to Find / Apply

- `ChromeProfileService.swift` — `enumerate()` reads `~/Library/Application Support/Google/Chrome/<Profile>/Preferences` JSON, `open(_:)` launches Chrome with `--profile-directory=<id>`.
- `AccountSwitcherView.swift` — calls `appState.openChromeProfile(for: profile.email)` on tap.
- `AppState.openChromeProfile(for:)` — looks up profile by email, delegates to `ChromeProfileService.open(_:)`.

## Context

Decision made mid-session on 2026-05-19. Branch: `building-swtch`. Commit `8e0ccc5` implements ChromeProfileService.
