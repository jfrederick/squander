# Tasks: add-month-recap

## 1. Core

- [x] 1.1 `MonthRecap.compute`: biggest day (ties to earliest) and longest no-spend streak over elapsed days
- [x] 1.2 Unit tests: biggest day, tie-break, completed-month streak, current-month cap, empty month, out-of-month exclusion, future month

## 2. View

- [x] 2.1 `RecapCardView`: total, comparison, top three categories, biggest day, streak — renderable standalone for image export
- [x] 2.2 InsightsView: recap section for the displayed month + ShareLink exporting the card via ImageRenderer
- [x] 2.3 xcodegen regeneration for the new view file

## 3. Tests

- [x] 3.1 UI test: recap section and share control present with seeded data
- [x] 3.2 Full simulator gate passes
