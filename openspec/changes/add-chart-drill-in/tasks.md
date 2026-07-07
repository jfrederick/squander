# Tasks: add-chart-drill-in

## 1. Core

- [ ] 1.1 `period(containing:)` helper on `[PeriodTotal]` (half-open interval containment)
- [ ] 1.2 Unit tests: containment, boundary between periods, before/after the window, empty series

## 2. Views

- [ ] 2.1 TrendChartView: tap gesture over the plot area mapping the tapped x to a period, `onSelectPeriod` callback (non-zero periods only)
- [ ] 2.2 TotalsView: navigation destination pushing ExpenseListView for the tapped period, title matching the period rows

## 3. Tests

- [ ] 3.1 UI test: tapping today's bar (seeded $25) opens the "Today" drill-in list
- [ ] 3.2 UI test: tapping an empty band does not navigate
- [ ] 3.3 Full simulator gate passes
