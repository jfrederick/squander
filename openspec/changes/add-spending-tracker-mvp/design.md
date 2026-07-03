# Design: add-spending-tracker-mvp

## Context

Greenfield repo. Single developer, single-user personal app. The dominant design force is entry speed: launch → amount → description → (implicit or one-tap) category → saved, ideally under five seconds. CI/CD runs on Xcode Cloud, so the project layout and test targets must be Xcode Cloud–friendly from the first commit.

## Goals / Non-Goals

**Goals:**
- Sub-five-second expense capture as the default path
- All learning (autocomplete, categorization) fully on-device
- A project structure where every spec scenario maps to an automatable test
- Xcode Cloud workflows usable from the first buildable commit

**Non-Goals:**
- Sync, backup, multi-device, accounts (explicitly excluded)
- Budgets, recurring expenses, receipts, currencies other than USD
- ML-model-based categorization (heuristics only for MVP)
- iPad/watchOS/widgets (iPhone portrait only for MVP)

## Decisions

### D1: SwiftUI + SwiftData, iOS 17+
SwiftUI for UI and SwiftData for persistence keep the stack single-vendor and testable with Swift Testing. Alternative: Core Data (more boilerplate) or GRDB/SQLite (extra dependency) — rejected because the model is tiny (3 entities) and SwiftData's `@Query` gives the "totals update automatically" behavior nearly for free.

### D2: Three-entity model
- `Expense` — `amountDollars: Int`, `label: String` (original casing), `normalizedLabel: String`, `timestamp: Date` (UTC instant), relationship → `Category`
- `Category` — `name: String` (unique), `colorName: String`, `iconName: String`, `isSeeded: Bool`
- `LabelMapping` — `normalizedLabel: String` (unique), relationship → `Category`, `useCount: Int`, `lastUsedAt: Date`

`LabelMapping` is separate from `Expense` (rather than derived by querying past expenses) so the description→category memory survives expense edits/deletions independently and gives autocomplete a pre-deduplicated, pre-ranked table. Editing an expense's category updates its `LabelMapping`; deleting expenses does not erase learned mappings.

### D3: Amounts as `Int` dollars end to end
No `Decimal`, no cents field, no floating point anywhere. Formatting via `NumberFormatter`/`FormatStyle` currency style with fraction digits forced to 0.

### D4: Entry flow as a two-step single screen
One `EntryView` with an internal step state (amount → description+category), custom keypad (SwiftUI buttons, not `UITextField` with a system keypad) for the amount step so there is no keyboard-focus latency at launch. Description step uses a real `TextField` with `.focused` set on appear. Category confirmation renders inline on the description step (suggestion chip + "change" opens picker sheet), so known descriptions save with a single tap.

### D5: Categorization heuristic (no ML)
Order of resolution for a normalized label:
1. Exact `LabelMapping` hit → auto-assign, no prompt.
2. Token-overlap / prefix similarity against existing mappings (e.g., "cafe latte" vs "cafe") → best category as preselected suggestion.
3. Static keyword table shipped with the app (e.g., "taco|burrito|mexican" → Food & Drink) → suggestion.
4. Fallback: "Other" preselected.
Rationale: deterministic, testable with plain unit tests, zero dependencies. A CoreML/NL-embedding approach was considered and rejected for MVP complexity.

### D6: Normalization function is a single shared utility
`normalize(_:) = trim → casefold → strip diacritics`. Used by autocomplete matching, mapping lookup, and duplicate-category checks, and unit-tested once. Prevents subtle mismatches between features.

### D7: Totals computed by grouping in the view model
Fetch expenses in a date window and group with `Calendar.current` (`startOfDay`, `dateInterval(of: .weekOfYear/.month)`). No denormalized totals tables — data volume (personal spending, thousands of rows at most) makes on-the-fly aggregation trivial. Locale-aware week start comes from `Calendar.current.firstWeekday` for free.

### D8: Project layout and testing
- `Squander/` app target: `Models/`, `Services/` (CategorySuggester, AutocompleteProvider, TotalsAggregator — all pure logic, no UI), `Views/`
- `SquanderTests/` unit tests: every spec scenario for services/model becomes a test; SwiftData tested against in-memory `ModelContainer`
- `SquanderUITests/`: launch-to-keypad, full entry flow, tab navigation
Pure-logic services exist precisely so spec scenarios are testable without UI automation.

### D9: Xcode Cloud
Two workflows, configured in App Store Connect (Xcode Cloud stores workflow config server-side; only `ci_scripts/` lives in the repo):
- **PR workflow**: build + run unit and UI tests on every pull request against `main`
- **Release workflow**: on push to `main`, build, test, archive, and distribute to TestFlight internal testing
`ci_scripts/ci_post_clone.sh` kept minimal (no dependencies to install). No third-party CI config files.

## Risks / Trade-offs

- [SwiftData maturity: query performance and migration edge cases] → model kept to 3 entities with lightweight migrations only; schema is versioned (`VersionedSchema`) from v1.
- [Heuristic suggestions may feel dumb for ambiguous labels] → the confirm step is always shown for new labels, so a wrong suggestion costs one tap; mappings self-correct via the edit-updates-mapping rule.
- [Custom keypad must match system keyboard ergonomics] → mirror system keypad layout/sizing; UI test asserts first-tap readiness.
- [Xcode Cloud workflow config is not in-repo] → document workflow settings in `docs/xcode-cloud.md` so they can be recreated.
- [5-minute in-progress-entry expiry (spec) needs backgrounding time tracking] → store `backgroundedAt` on scene phase change; trivial but easy to forget — covered by a scenario.

## Open Questions

- Seed category icon/color palette — pick during implementation (pure cosmetics, not spec-relevant).
- Whether drill-in expense lists live on the Totals tab via navigation push (current design) or a third tab; design says navigation push to keep the tab bar at two tabs.
