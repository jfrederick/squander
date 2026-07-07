# Proposal: update-tab-names

## Why

The tab labels describe screens, not what the user does or sees there. "Entry"
is developer vocabulary for the keypad where you log an expense; "Totals" is
vaguer than what the screen actually answers — how much have I spent?

## What Changes

- The keypad tab is labeled "Log" (was "Entry").
- The totals tab is labeled "Spent" (was "Totals"), and its navigation title
  matches.
- No behavior changes: tab order, icons, default tab, post-save switch, and
  the `spendthrift://entry` deep link are untouched.

## Capabilities

### Modified Capabilities

- `spending-totals`: the totals tab requirement now names the tab "Spent".
- `expense-entry`: the post-save requirement now says the app switches to the
  Spent tab.

## Impact

- Views only: `RootTabView` (two `Label` titles), `TotalsView` (navigation
  title). No model or SpendthriftCore changes.
- UI tests: every `app.tabBars.buttons["Entry"/"Totals"]` becomes
  `["Log"/"Spent"]`.
