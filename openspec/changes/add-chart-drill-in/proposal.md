# Proposal: add-chart-drill-in

## Why

The trend chart on the Spent tab is display-only. The bars invite tapping —
"what did I spend that week on?" — but answering that today means visually
matching the bar to a row in the list below and tapping the row instead.

## What Changes

- Tapping a bar on the trend chart opens the existing drill-in expense list
  for that bar's period, titled the same way as the corresponding list row.
- Taps on periods with no expenses do nothing — the rest of the app never
  offers an empty-period drill-in (the totals list omits empty periods), and
  a zero-height bar shows nothing to tap.
- Period hit-testing (tapped date → containing period) lives in
  SpendthriftCore so it is unit-tested.

## Capabilities

### Modified Capabilities

- `spending-insights`: the trend chart requirement gains tap-to-drill-in
  behavior (and its wording follows the tab's rename to "Spent").

## Impact

- `SpendthriftCore`: new `period(containing:)` hit-test helper on
  `[PeriodTotal]` + tests.
- Views: `TrendChartView` (tap gesture over the plot area, selection
  callback), `TotalsView` (navigation destination for a tapped period).
- UI tests: tapping the current-day bar with seeded data opens "Today";
  tapping an empty band does not navigate.
