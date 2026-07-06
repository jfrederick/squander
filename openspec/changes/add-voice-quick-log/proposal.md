# Proposal: add-voice-quick-log

## Why

The widget made habitual expenses one tap, but novel expenses still require the phone in hand and the keypad. Voice is the only capture path that works hands-free (walking, driving, carrying groceries) — "Hey Siri, log six dollar coffee" should record the expense without ever touching the phone.

## What Changes

- A new `LogSpokenExpenseIntent` App Intent takes a single spoken utterance string (e.g. "six dollar coffee", "$14 lunch", "twenty bucks for parking"), parses it into a whole-dollar amount and a description, and logs the expense without opening the app.
- An `AppShortcutsProvider` registers Siri phrases ("Log an expense in Spendthrift", "Log \(spending) in Spendthrift") so the intent is invocable by voice out of the box, with Siri prompting for the utterance when it isn't in the phrase.
- Utterance parsing is pure logic in `SpendthriftCore` (`SpokenExpenseParser`): digit amounts with optional `$`, English number words ("six", "twenty-five", "a hundred"), currency words ("dollar/dollars/bucks"), and connective filler ("for", "on") are recognized; the remaining tokens become the description.
- Category is resolved exactly like other entry paths: remembered `LabelMapping` first, then `CategorySuggester` heuristics, then "Other".
- Siri replies with a confirmation dialog ("Logged $6 for coffee in Food & Drink"); on an unparseable utterance it replies with an error dialog and logs nothing.
- Widget timelines reload after a successful log so today's total stays fresh.

## Capabilities

### New Capabilities

- `voice-quick-log`: Siri/App Shortcuts voice logging — utterance parsing, hands-free expense creation, spoken confirmation.

### Modified Capabilities

<!-- none: additive feature; existing entry, totals, and widget requirements are unchanged -->

## Impact

- New pure parser + tests in `SpendthriftCore` (no new dependencies).
- New `LogSpokenExpenseIntent` and `SpendthriftShortcuts` in the app target (App Intents framework, iOS 17 baseline); reuses `SpendthriftContainer`/`ExpenseStore` write path shared with the widget intent.
- No schema changes, no new targets, no entitlement changes (App Group already in place).
- `project.yml`/Xcode project unchanged unless new files require regeneration (they do — xcodegen run + commit).
