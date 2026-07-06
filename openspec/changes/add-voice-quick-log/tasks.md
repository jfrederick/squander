# Tasks: add-voice-quick-log

## 1. Core parser (SpendthriftCore, TDD)

- [x] 1.1 Write failing unit tests for `SpokenExpenseParser` covering all spec scenarios: digit/word amounts, either order, currency words, connectives, command filler, compounds ("twenty-five", "a hundred and ten"), no-amount, no-description, out-of-range, number-words-in-description edge cases
- [x] 1.2 Implement `SpokenExpense` + `SpokenExpenseParser.parse(_:)` in SpendthriftCore until all tests pass (`swift test`)

## 2. App Intent + App Shortcuts

- [x] 2.1 Add `LogSpokenExpenseIntent` in the app target: dictated utterance parameter with request-value dialog, parse via `SpokenExpenseParser`, category resolution mapping → suggester → "Other", save via `ExpenseStore`, reload widget timelines, success/failure `IntentDialog` results
- [x] 2.2 Add `SpendthriftShortcuts: AppShortcutsProvider` with stable phrases including a `\(\.$utterance)` parameterized phrase
- [ ] 2.3 Update `project.yml` if needed, run `xcodegen`, commit regenerated project

## 3. Store-level tests

- [x] 3.1 Swift Testing tests (in-memory container) for the intent's write path: success writes expense with mapped category, suggester fallback, "Other" fallback, parse failure writes nothing

## 4. Gate & ship

- [x] 4.1 Run full simulator suite (`xcodebuild ... test`) and fix anything that breaks
- [x] 4.2 `openspec validate add-voice-quick-log --strict` passes
- [ ] 4.3 Branch, PR, code review, merge, clean up branch/worktree
