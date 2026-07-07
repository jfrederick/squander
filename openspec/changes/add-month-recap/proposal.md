# Proposal: add-month-recap

## Why

Insights shows the month's total and category ranking, but the memorable
facts — the biggest day, how long the no-spend streaks ran — aren't surfaced
anywhere, and there's no way to share a month's story out of the app.

## What Changes

- Insights gains a recap section for the displayed month: total, top three
  categories, biggest spending day, longest no-spend streak (elapsed days
  only for the current month), and the month-over-month comparison.
- A share control exports the recap as an image via the system share sheet.
- The two genuinely new computations (biggest day, longest no-spend streak)
  live in SpendthriftCore (`MonthRecap`); total, ranking, and comparison
  reuse `CategoryBreakdown`/`MonthComparison`, composed by the view.
- No recap when the displayed month has no expenses.

## Capabilities

### Modified Capabilities

- `spending-insights`: adds the month-recap requirement.

## Impact

- `SpendthriftCore`: new `MonthRecap` + tests.
- Views: `InsightsView` (recap section + ShareLink of an ImageRenderer
  image), new `RecapCardView`.
- UI tests: recap section and share control present with seeded data.
- `xcodegen` regeneration for the new view file.
