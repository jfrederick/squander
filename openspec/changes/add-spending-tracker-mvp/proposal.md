# Proposal: add-spending-tracker-mvp

## Why

Logging an expense in existing tracker apps takes too many taps, so expenses go unlogged and totals become meaningless. Spendthrift needs a first version whose whole design is speed: open the app, type a dollar amount, type a short description, confirm a category, done — with the app learning from past entries to make each subsequent entry faster.

## What Changes

- New iOS app (SwiftUI, iOS 17+) with local-only persistence (SwiftData).
- Capture flow: app launches directly into a numeric keypad for whole-dollar amount entry, followed by a short free-text description with autocomplete from past expense descriptions.
- Auto-categorization: exact description matches reuse the previously confirmed category; new descriptions get a suggested category (from a bounded set of 10–30) that the user confirms or changes.
- Totals: a second tab showing daily, weekly, and monthly spending totals.
- Expense management: view recent expenses, edit or delete an entry.
- CI/CD via Xcode Cloud: build + test on PRs, TestFlight distribution from main.

## Capabilities

### New Capabilities

- `expense-entry`: launch-to-keypad capture flow — whole-dollar amount entry, description entry, save; the core speed path.
- `description-autocomplete`: suggest description completions from past expenses while the user types.
- `expense-categorization`: bounded category set (10–30), exact description→category memory, suggestion + confirm/change flow for new descriptions.
- `spending-totals`: totals tab with daily, weekly, and monthly aggregates.
- `expense-management`: browse recent expenses; edit amount/description/category; delete.
- `data-persistence`: local on-device storage model for expenses and categories; no accounts, no network.

### Modified Capabilities

_None — greenfield project._

## Impact

- New Xcode project (app target + unit/UI test targets) at repo root.
- New Xcode Cloud workflow configuration (CI scripts under `ci_scripts/` when implementation starts).
- No external services, APIs, or third-party dependencies.
