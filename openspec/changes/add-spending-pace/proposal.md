# Proposal: add-spending-pace

## Why

The Spent tab shows what you've already spent, but the question mid-month is
"where is this heading?" — currently you have to extrapolate in your head and
remember last month's total to know whether you're running hot.

## What Changes

- The Spent tab header shows a one-line spending pace: the current month's
  projected total (month-to-date extrapolated over the full month by elapsed
  days), with last month's total as the baseline.
- The line is red when the projection exceeds last month, green when under,
  neutral when equal or when last month has no expenses (no baseline).
- The line is hidden while the current month has no expenses.
- Projection math lives in SpendthriftCore (`SpendingPace`), unit-tested.

## Capabilities

### Modified Capabilities

- `spending-insights`: adds the spending-pace requirement.

## Impact

- `SpendthriftCore`: new `SpendingPace` + tests (composes `MonthComparison`'s
  baseline semantics: a zero previous month is "no baseline").
- Views: `TotalsView` header line only.
- UI tests: pace line present with seeded data.
