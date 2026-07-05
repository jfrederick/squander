# Proposal: add-spending-insights

## Why

Totals answer "how much did I spend?" but not "where did it go?" or "am I spending more than last month?". Logged data should pay the user back with insight, or the logging habit decays.

## What Changes

- The Totals tab gains a trend chart header above the period list: last 14 days (Daily), last 12 weeks (Weekly), or last 12 months (Monthly), rendered with Swift Charts, current period highlighted.
- A new Insights screen, pushed from a chart toolbar button on the Totals tab, shows for a selected month: total with month-over-month comparison (absolute and percent delta vs the previous month), a category breakdown donut chart, and a ranked per-category list with amounts and share of total.
- All aggregation logic (per-category totals, period series, deltas) lives in SpendthriftCore as pure, unit-tested functions; chart views stay thin.

## Capabilities

### New Capabilities

- `spending-insights`: trend chart on Totals, month insights screen with category breakdown and month-over-month comparison.

### Modified Capabilities

- `spending-totals`: the Totals tab layout gains the chart header and the toolbar entry point (no change to existing totals semantics).

## Impact

- New views in `Spendthrift/Views/` (Swift Charts, iOS 17 baseline — no new dependencies).
- New aggregation functions + tests in `SpendthriftCore`.
- No schema changes, no new targets.
