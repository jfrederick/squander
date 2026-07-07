# Tasks: update-tab-names

## 1. Rename

- [x] 1.1 RootTabView: tab labels "Entry" → "Log", "Totals" → "Spent" (icons, tags, order unchanged)
- [x] 1.2 TotalsView: navigation title "Totals" → "Spent"
- [x] 1.3 Update stale comments that reference the old labels

## 2. Tests

- [x] 2.1 UI tests: `app.tabBars.buttons["Entry"/"Totals"]` → `["Log"/"Spent"]`
- [x] 2.2 Full simulator gate passes
