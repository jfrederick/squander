# Tasks: add-spending-pace

## 1. Core

- [x] 1.1 `SpendingPace.compute(expenses:asOf:calendar:)`: month-to-date, day-based projection (half-up integer rounding), previous-month baseline, standing
- [x] 1.2 Unit tests: exact projection, rounding, day 1, month boundary (January vs December), no baseline, empty month

## 2. View

- [x] 2.1 TotalsView: pace line above the chart, colored by standing, hidden when the month is empty

## 3. Tests

- [x] 3.1 UI test: pace line present with seeded data
- [x] 3.2 Full simulator gate passes
