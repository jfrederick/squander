# Tasks: add-spending-insights

## 1. Core aggregation (SpendthriftCore)

- [x] 1.1 Implement `TotalsAggregator.periodSeries` (fixed-length windows: last N days/weeks/months including zero periods) — with unit tests incl. time zone and week-start cases
- [x] 1.2 Implement `CategoryBreakdown.compute` (per-category totals, ranked, percentage shares, omit empty) — with unit tests incl. rounding of shares
- [x] 1.3 Implement `MonthComparison.compute` (absolute + percent delta vs previous month, no-prior-data case) — with unit tests

## 2. Totals tab chart header

- [x] 2.1 Build TrendChartView (Swift Charts BarMark) fed by periodSeries; current period highlighted
- [x] 2.2 Wire chart into TotalsView above the list, following the segmented control; @Query keeps it live
- [x] 2.3 UI test: chart present on Totals tab and switches with granularity (authored; runs on Xcode Cloud — not executable locally)

## 3. Insights screen

- [x] 3.1 Build InsightsView: month stepper (no future months), total, MoM comparison line with direction indicator
- [x] 3.2 Build donut chart (SectorMark) + ranked category list with amounts and shares, category colors
- [x] 3.3 Empty-state handling for months with no expenses
- [x] 3.4 Toolbar entry point on Totals tab; UI tests: open insights, step months, breakdown rows visible (tests authored; run on Xcode Cloud)

## 4. Finalize

- [x] 4.1 Accessibility labels for charts (audio graph descriptors optional) and comparison text
- [ ] 4.2 Full test pass; openspec validate; update README feature list (SpendthriftCore suite green locally, validate passing, README updated; app-target build/UI test pass awaits Xcode Cloud)
