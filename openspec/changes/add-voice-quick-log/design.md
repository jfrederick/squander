# Design: add-voice-quick-log

## Context

The app already has two entry paths sharing one write pipeline: the in-app keypad and the widget's `LogQuickExpenseIntent` (App Intent running in the extension process against the App Group SwiftData store via `SpendthriftContainer` + `ExpenseStore`). Voice adds a third path. The hard part is not the write — it's turning a free-form dictated utterance into `(amountDollars: Int, label: String)` reliably, on-device, with no ML dependency.

## Goals / Non-Goals

**Goals:**
- Hands-free logging via Siri with no app launch, end-to-end in one utterance when possible.
- Deterministic, unit-testable utterance parsing in `SpendthriftCore`.
- Identical category resolution and validation to existing entry paths.

**Non-Goals:**
- Custom speech recognition (Siri's transcription is the input; we parse text).
- Multi-expense utterances ("coffee 6 and lunch 14") — first match wins is out of scope; unparseable → error.
- Cents, currencies other than dollars, or locale-specific number-word parsing (English only, matching Siri phrase locale support we ship).

## Decisions

- **D1: Single dictated-string parameter, parsed by us — not separate Siri-resolved amount/description parameters.** Separate parameters force a multi-turn Siri dialog ("What amount?" … "What description?") which is slower than the keypad. One utterance parameter (`requestValueDialog: "What did you spend?"`) keeps it to a single exchange. Alternatives rejected: `@Parameter` per field with Siri disambiguation (worse capture speed); embedding the utterance in the App Shortcut phrase (App Intents only permits AppEnum/AppEntity parameters inside phrases, not free-form String).
- **D2: Parser lives in `SpendthriftCore` as `SpokenExpenseParser.parse(_:) -> SpokenExpense?`.** Pure function over the normalized token stream; testable via `swift test` without Xcode. Grammar: optional leading filler ("log", "add", "spent"), amount as digits (`$6`, `6`) or English number words ("six", "twenty five", "one hundred", "a hundred"), optional currency word ("dollar(s)", "buck(s)"), optional connective ("for", "on", "of"), remaining tokens → description. Amount and description may appear in either order ("coffee six dollars" and "six dollar coffee" both parse). Number-word vocabulary covers 1–9999 (units, teens, tens, "hundred", "thousand", compounds with optional hyphens/"and"), clamped to the keypad's validity range.
- **D3: Intent runs in the app process (`openAppWhenRun = false`), registered via `AppShortcutsProvider`.** App Shortcuts make the phrases available immediately after install with no user setup. The write path is byte-for-byte the widget intent's: `SpendthriftContainer.makeContainer()` → `ExpenseStore` → `seedIfNeeded()` → mapping/suggester/Other → `saveExpense` → `WidgetCenter.reloadAllTimelines()`. Alternative rejected: putting the intent in the widget extension — App Shortcuts phrases belong with the app target and gain nothing from extension residency.
- **D4: Category resolution order: `LabelMapping` → `CategorySuggester.suggest` → "Other".** This is one step more than the widget intent (which skips the suggester because its labels are by definition remembered); voice utterances are frequently novel, so the suggester earns its keep here. Uses `normalize(_:)` for the mapping lookup like every other path.
- **D5: Failure is a spoken sentence, not silence.** Unparseable utterance or out-of-range amount returns `.result(dialog:)` with a corrective message ("I couldn't find an amount…"); nothing is written. Success dialog echoes amount, description, and resolved category so mistakes are audible immediately.

## Risks / Trade-offs

- [Siri transcribes "$6" variably ("6 dollars", "six dollars", "$6")] → parser accepts all digit and word forms with/without currency words; test matrix covers the transcription variants observed in practice.
- [Description contains number words ("7 eleven", "5 guys")] → amount binds to the token group adjacent to a currency word when present; bare-number heuristic prefers the first standalone number, so "five guys twelve dollars" logs $12 "five guys". Documented limitation: "seven eleven" with no other number parses as $7 "eleven" — acceptable for v1, mitigated by the audible confirmation.
- [App Shortcuts phrase changes require an app update] → keep phrases few and stable; the open-ended utterance parameter carries the variability instead.

## Open Questions

None blocking; English-only parsing is accepted for v1.
