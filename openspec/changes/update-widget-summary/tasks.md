# Tasks: update-widget-summary

## 1. Core

- [x] 1.1 `SpendSummary` (today / this month / this year whole-dollar totals, half-open calendar bucketing)
- [x] 1.2 Unit tests: cross-period bucketing, empty, boundary instants, time-zone-vs-UTC bucketing

## 2. Widget

- [x] 2.1 Entry/provider carry the three-total summary instead of a lone today total
- [x] 2.2 Small + medium layouts: today prominent, month/year beneath, flame mark in the corner
- [x] 2.3 Status outline via containerBackground: light green when today is $0, red otherwise
- [x] 2.4 `FlameMark` vector (no rasterized asset); xcodegen regeneration for the new file

## 3. Verification

- [x] 3.1 Core `swift test` green
- [x] 3.2 Full simulator gate passes
