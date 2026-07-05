# Squander — working notes for Claude

Personal iOS spending tracker. One design goal dominates: sub-5-second expense
capture. Read `openspec/` before changing behavior — all requirements live
there (OpenSpec), and no other spec/planning documents may be added to the repo.

## Architecture

- `SquanderCore/` — local Swift package, **pure logic only** (no SwiftData, no
  SwiftUI). Normalization, keypad state, autocomplete ranking, category
  heuristics, totals aggregation, validation rules. This is where logic goes
  by default, because it is the only code testable on machines without Xcode.
- `Squander/Models/` — SwiftData schema (`SquanderSchemaV1`, versioned from v1)
  and `ExpenseStore`, the single write path. All mutations and uniqueness rules
  go through the store.
- `Squander/Views/` — thin SwiftUI. Display logic that can live in
  SquanderCore must live there instead.
- `SquanderTests/` — Swift Testing against in-memory `ModelContainer`.
- `SquanderUITests/` — XCUITest; launch args `-UITestMode` (in-memory store)
  and `-UITestSeedData` (fixed dataset).

## Build & test on this machine (no Xcode.app, CLT only)

- SquanderCore tests work locally but CLT doesn't ship Swift Testing on the
  default search path. Use:
  `cd SquanderCore && swift test -Xswiftc -F -Xswiftc /Library/Developer/CommandLineTools/Library/Developer/Frameworks -Xlinker -F -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks`
  (first run may also need `Testing.framework` and `lib_TestingInterop.dylib`
  copied from that Frameworks dir into `.build/debug/`). Keep this green.
- The app target, SwiftData `@Model` code, and UI tests **cannot compile
  locally** (the CLT toolchain lacks the SwiftData macro plugin and iOS SDK).
  They build on Xcode Cloud (see `docs/xcode-cloud.md`) or a machine with
  Xcode. Write conservative, iOS 17-stable API code there and get it reviewed.
- Project file: edit `project.yml`, run `xcodegen`, commit both it and the
  regenerated `Squander.xcodeproj`.
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
