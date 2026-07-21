# Spendthrift — working notes for Claude

Personal iOS spending tracker. One design goal dominates: sub-5-second expense
capture. Read `openspec/` before changing behavior — all requirements live
there (OpenSpec), and no other spec/planning documents may be added to the repo.

## Architecture

- `SpendthriftCore/` — local Swift package, **pure logic only** (no SwiftData, no
  SwiftUI). Normalization, keypad state, autocomplete ranking, category
  heuristics, totals aggregation, validation rules. This is where logic goes
  by default, because it is the only code testable on machines without Xcode.
  **All user-facing copy lives here too** (WeeklyDigest, SpendingPace.headline,
  MonthRecap lines) so every sentence is unit-testable — check this before
  writing any new sentence in a view.
- `Spendthrift/Models/` — SwiftData schema (`SpendthriftSchemaV1`, versioned from v1)
  and `ExpenseStore`, the single write path. All mutations and uniqueness rules
  go through the store. `ExpenseStore.onExpensesMutated` is the single
  post-mutation hook (digest rescheduling and widget timeline reload hang off
  it): every new write path must fire it, and every new mutation side effect
  subscribes there — never in views.
- `Spendthrift/Views/` — thin SwiftUI. Display logic that can live in
  SpendthriftCore must live there instead.
- `SpendthriftTests/` — Swift Testing against in-memory `ModelContainer`.
- `SpendthriftUITests/` — XCUITest; launch args `-UITestMode` (in-memory store)
  and `-UITestSeedData` (fixed dataset).

## Build & test on this machine

Xcode.app is installed but `xcode-select` points at CommandLineTools, so
prefix toolchain commands with
`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

- Gate before any push — full suite on the simulator:
  `xcodebuild -project Spendthrift.xcodeproj -scheme Spendthrift -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/spendthrift-dd CODE_SIGNING_ALLOWED=NO test`
- Fast loop: `cd SpendthriftCore && swift test` (needs the DEVELOPER_DIR prefix).
- Never use legacy `xcodebuild -target` builds: they can't resolve the
  SpendthriftCore package and drop a stray `build/` dir.
- XCUITest gotchas that have bitten here: identifiers on List rows /
  NavigationLinks don't surface as `app.cells[...]` (use a type-agnostic
  descendants query); tap tab bars by visible label
  (`app.tabBars.buttons["Log"/"Spent"]`); keep identifiers/labels unique across
  screens anyway (the edit keypad uses the `edit-keypad-*` prefix and the
  keypad delete key is labeled "Delete digit"); `waitForExpectations`
  is not Swift 6-safe (use `waitForNonExistence(timeout:)`); keypaths inside
  `#expect` may need explicit closures.
- Project file: edit `project.yml`, run `xcodegen`, commit both it and the
  regenerated `Spendthrift.xcodeproj`. Never hand-edit the pbxproj — xcodegen
  regeneration silently drops hand edits (`DEVELOPMENT_TEAM` is pinned in
  project.yml for exactly this reason).
- The first `xcodebuild test` right after `xcodegen` regenerates the project
  (or in a fresh worktree) can fail transiently on stale incremental state —
  re-run once before debugging a red gate.
- OpenSpec CLI: `~/.hermes/node/bin/openspec` (`openspec validate <change> --strict`).

## Domain rules that bite

- Amounts are `Int` whole dollars everywhere — never Decimal, never cents.
- All matching goes through `normalize(_:)` (trim → casefold → strip
  diacritics). Never compare labels or category names any other way.
- Categories: 10–30 bounded set, 12 seeded defaults, "Other" is the fallback
  and must always exist.
- `LabelMapping` is independent of `Expense`: deleting expenses never erases
  learned description→category memory; editing an expense's category updates
  the mapping for future expenses only.
- Timestamps: stored as UTC instants, all grouping/display via the device's
  `Calendar.current` (locale-aware week start).
