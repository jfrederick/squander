# spendthrift

A personal iOS spending tracker built for speed: open the app, punch in a whole-dollar amount on the keypad, type a short description ("cafe", "electrolytes"), confirm a category, done. The app learns — descriptions autocomplete from past expenses, and known descriptions are categorized automatically. A Totals tab shows daily, weekly, and monthly spending.

## Status

Spec-first: functionality is defined with [OpenSpec](https://github.com/Fission-AI/OpenSpec) before implementation.

- `openspec/changes/add-spending-tracker-mvp/` — the MVP change: proposal, design, capability specs, and implementation task list
- Capabilities specced: expense entry, description autocomplete, categorization, spending totals, expense management, data persistence

## Stack (planned)

- Swift / SwiftUI, iOS 17+, SwiftData (local-only, no accounts or network)
- Xcode Cloud for CI/CD (PR build+test, TestFlight from `main`)

## Working with the specs

```sh
npm install -g @fission-ai/openspec@latest
openspec status --change add-spending-tracker-mvp   # artifact progress
openspec validate add-spending-tracker-mvp --strict # validate specs
```

Implementation follows the checklist in `openspec/changes/add-spending-tracker-mvp/tasks.md` (start with `/opsx:apply` in Claude Code).
