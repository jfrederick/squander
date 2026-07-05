# spendthrift

A personal iOS spending tracker built for speed: open the app, punch in a whole-dollar amount on the keypad, type a short description ("cafe", "electrolytes"), confirm a category, done. The app learns — descriptions autocomplete from past expenses, and known descriptions are categorized automatically. A Totals tab shows daily, weekly, and monthly spending.

## Status

MVP implemented; awaiting first Xcode Cloud build + TestFlight distribution (manual App Store Connect setup — see `docs/xcode-cloud.md`).

Functionality is defined with [OpenSpec](https://github.com/Fission-AI/OpenSpec) before implementation:

- `openspec/changes/add-spending-tracker-mvp/` — the MVP change: proposal, design, capability specs, and implementation task list
- Capabilities: expense entry, description autocomplete, categorization, spending totals, expense management, data persistence

## Layout

- `SpendthriftCore/` — pure-logic Swift package (keypad state, autocomplete ranking, category heuristics, totals aggregation); unit-tested with Swift Testing
- `Spendthrift/` — SwiftUI app target: SwiftData models (`Models/`), views (`Views/`)
- `SpendthriftTests/` — SwiftData store tests against in-memory containers
- `SpendthriftUITests/` — XCUITest flows (launch-to-keypad, full capture, totals, edit/delete)
- `project.yml` — [XcodeGen](https://github.com/yonaskolb/XcodeGen) definition; regenerate `Spendthrift.xcodeproj` with `xcodegen` after adding files

## Stack

- Swift / SwiftUI, iOS 17+, SwiftData (local-only, no accounts or network)
- Xcode Cloud for CI/CD (PR build+test, TestFlight from `main`)

## Working with the specs

```sh
npm install -g @fission-ai/openspec@latest
openspec status --change add-spending-tracker-mvp   # artifact progress
openspec validate add-spending-tracker-mvp --strict # validate specs
```

Implementation follows the checklist in `openspec/changes/add-spending-tracker-mvp/tasks.md` (start with `/opsx:apply` in Claude Code).
