# Proposal: update-widget-summary

## Why

The widget is mostly whitespace: one number and (on medium) preset buttons.
It answers "what did I spend today" but not the two next questions — this
month and this year — and it has no visual identity or at-a-glance status.

## What Changes

- The small and medium widgets show three whole-dollar totals: today
  (prominent), this calendar month, and this calendar year.
- A small hand-drawn vector flame mark sits in the corner — brand character
  echoing the burning-money app icon, no rasterized asset.
- The widget is outlined in light green while today's total is $0, and in
  red once anything has been spent today.
- Quick-log presets on the medium family are unchanged; Lock Screen
  accessory families keep their compact today-only layout (vibrant rendering
  ignores color and outlines there).
- Summary aggregation (day/month/year bucketing) lives in SpendthriftCore
  (`SpendSummary`) so it is unit-tested.

## Capabilities

### Modified Capabilities

- `widget-quick-entry`: the Home Screen widget requirement becomes the
  three-total summary with status outline and flame mark.

## Impact

- `SpendthriftCore`: new `SpendSummary` + tests.
- `SpendthriftWidgets`: `SpendthriftWidget.swift` layout, new
  `FlameMark.swift` (requires `xcodegen` regeneration).
- No app-target or model changes; timeline/rollover behavior unchanged.
