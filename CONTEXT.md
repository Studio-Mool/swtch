# swtch — Context Document

## What We're Building

A native macOS menu bar app that shows which Claude Code account is currently logged in and displays that account's usage limit as a progress bar. On-demand refresh (not continuous polling).

## User Setup

- **Mac user profile**: 2 Claude Code accounts, switched via `claude auth logout` → `claude auth login`
- **Account switching**: Only one account is active at a time in this profile
- **Scope**: This profile only (a separate Mac user profile with a third account is out of scope)

## App Design

**Form factor**: macOS menu bar app (MenuBarExtra, SwiftUI, macOS 13+)

**Behavior**:
- Sits in the menu bar as an icon
- Click to open a popover showing:
  - Currently logged-in account (email, org, subscription type)
  - Usage progress bar (tokens/messages used vs. limit)
  - A "Refresh" button to fetch latest data on demand
- No continuous background polling — data is only fetched when the user clicks Refresh

## Technical Approach (Option A)

**Account info source**: `claude auth status` CLI command
- Returns JSON: `loggedIn`, `authMethod`, `email`, `orgId`, `orgName`, `subscriptionType`

**Usage data source**: claude.ai usage API
- The Claude desktop app stores an OAuth token (accessible via macOS Keychain under the Claude Code CLI's keychain service)
- We reuse this token to call the claude.ai usage endpoint and get actual usage + limit numbers
- This gives a real progress bar rather than a heuristic approximation

**Tech stack**: Swift + SwiftUI
- `MenuBarExtra` for the menu bar presence
- `Process` / `Shell` to invoke `claude auth status`
- `URLSession` for the claude.ai API call
- Buildable with Xcode

## Key Data Sources Found

| Source | Location | What it provides |
|--------|----------|-----------------|
| `claude auth status` | CLI | email, orgId, orgName, subscriptionType |
| macOS Keychain | Claude Code service entry | OAuth token for claude.ai |
| claude.ai usage API | HTTPS | actual usage count + limit |
| `buddy-tokens.json` | `~/Library/Application Support/Claude/` | tokens-today (fallback) |

## Repo

- **GitHub**: https://github.com/Studio-Mool/swtch
- **Local**: `~/Claude/StudioMool/swtch`

## Open Questions (to resolve during implementation)

1. What is the exact claude.ai endpoint for usage data? (needs discovery via network inspection or docs)
2. What keychain service name does Claude Code use to store the OAuth token?
3. Does the token need to be refreshed, or is it long-lived?
