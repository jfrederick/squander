# Tasks: add-spending-tracker-mvp

## 1. Project Setup

- [x] 1.1 Create Xcode project "Squander" (SwiftUI app, iOS 17 target, iPhone only) with SquanderTests and SquanderUITests targets
- [x] 1.2 Add folder structure per design (Models/, Services/, Views/) and commit a buildable empty app
- [ ] 1.3 Add `ci_scripts/ci_post_clone.sh` and `docs/xcode-cloud.md`; configure Xcode Cloud PR workflow (build + tests on PRs to main)
- [ ] 1.4 Configure Xcode Cloud release workflow (main → archive → TestFlight internal)

## 2. Data Layer (data-persistence spec)

- [x] 2.1 Define SwiftData `VersionedSchema` v1 with Expense, Category, LabelMapping models (Int dollar amounts, normalized label keys, UTC timestamps)
- [x] 2.2 Implement shared `normalize(_:)` utility (trim, casefold, strip diacritics) with unit tests
- [x] 2.3 Implement first-launch seeding of the 12 default categories with unit test
- [x] 2.4 Enforce category referential integrity (reassignment required before category deletion) with unit tests
- [x] 2.5 Unit-test persistence round-trip with in-memory ModelContainer (save, relaunch simulation, data intact)

## 3. Amount Entry (expense-entry spec)

- [x] 3.1 Build custom numeric keypad component (digits 0–9, delete; no decimal key)
- [x] 3.2 Implement amount state logic: leading-zero rejection, $99,999 cap, delete, disabled Next on zero — with unit tests
- [x] 3.3 Build EntryView amount step as app root; UI test: cold launch shows keypad, first tap registers a digit
- [x] 3.4 Implement background/foreground handling: preserve in-progress entry under 5 minutes, reset after — with tests

## 4. Description + Autocomplete (expense-entry, description-autocomplete specs)

- [x] 4.1 Build description step UI (auto-focused TextField, 40-char limit, back to amount preserves state, disabled save on empty)
- [x] 4.2 Implement AutocompleteProvider service: normalized prefix-then-substring matching, frequency+recency ranking, dedupe, top-5 — with unit tests covering all spec scenarios
- [x] 4.3 Wire suggestion list into description step; tapping a suggestion fills text and fast-tracks the remembered category
- [x] 4.4 Treat exact typed match of a known description as acceptance (skip category prompt) — with test

## 5. Categorization (expense-categorization spec)

- [x] 5.1 Implement LabelMapping lookup: exact normalized hit auto-assigns without prompt — with unit tests
- [x] 5.2 Implement CategorySuggester heuristic (token/prefix similarity, static keyword table, Other fallback) — with unit tests
- [x] 5.3 Build category confirmation UI: inline suggestion chip with one-tap confirm, picker sheet to change
- [x] 5.4 Implement inline category creation in picker with 30-cap and duplicate-name rejection — with tests
- [x] 5.5 Record/update mapping on confirm and on expense category edit (edit updates future mapping, past expenses untouched) — with tests
- [x] 5.6 Implement save flow end-to-end: persist expense, reset to keypad, transient confirmation — UI test for full capture path

## 6. Totals (spending-totals spec)

- [x] 6.1 Implement TotalsAggregator service: daily/weekly/monthly grouping via Calendar.current, locale week start, empty-period omission — with unit tests covering time zone and week-start scenarios
- [x] 6.2 Build Totals tab with segmented Daily/Weekly/Monthly views, reverse-chronological rows, current period highlighted
- [x] 6.3 Add tab bar (Entry + Totals) with Entry as default tab; UI test that totals reflect a newly saved expense

## 7. Expense Management (expense-management spec)

- [x] 7.1 Build drill-in expense list from day/week/month rows, grouped by day with amount/description/category
- [x] 7.2 Build expense edit screen reusing entry validation; timestamp preserved on edit — with tests
- [x] 7.3 Implement swipe-to-delete with transient undo restoring the full record — with tests

## 8. Hardening & Release

- [ ] 8.1 Full UI test pass mapping remaining spec scenarios; fix gaps
- [ ] 8.2 Accessibility pass on entry flow and totals (VoiceOver labels, Dynamic Type)
- [ ] 8.3 App icon, launch screen (must not delay keypad readiness), display name
- [ ] 8.4 Verify both Xcode Cloud workflows green; distribute first TestFlight build
