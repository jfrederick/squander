# Tasks: add-widget-quick-entry

## 1. Shared store / App Group

- [x] 1.1 Add App Group entitlement (`group.dev.jimfrederick.squander`) to app target; move ModelConfiguration to the group container URL
- [x] 1.2 One-time migration: on launch, if a store exists at the old default location and none in the group container, copy store files (incl. -wal/-shm) before opening — with store-layer test of the copy logic
- [x] 1.3 Extract container construction into a shared `SquanderContainer` helper used by app and extension

## 2. Quick-log presets (SquanderCore)

- [x] 2.1 Implement `QuickLogPresets.compute(expenses:limit:)` — top descriptions by use count (≥2 expenses, recency tie-break) paired with modal amount (recency tie-break) — with unit tests (derived from expense history alone; a separate mappings input proved unnecessary)

## 3. Widget extension

- [x] 3.1 Add `SquanderWidgets` target (WidgetKit) to project.yml with App Group entitlement; regenerate project
- [x] 3.2 TimelineProvider reading today's total + presets from the shared store; entries for day rollover
- [x] 3.3 Small widget: today's total; medium: total + up to 4 preset buttons; Lock Screen circular + rectangular accessories
- [x] 3.4 `LogQuickExpenseIntent` (AppIntent): validates preset, writes via ExpenseStore, reloads timelines — with store-level tests of the write path
- [x] 3.5 Widget tap (non-button areas) opens app to keypad (widgetURL); handle URL in app

## 4. Finalize

- [x] 4.1 Update docs/xcode-cloud.md (extension signing, App Group in App Store Connect)
- [x] 4.2 Full test pass; openspec validate; update README feature list
