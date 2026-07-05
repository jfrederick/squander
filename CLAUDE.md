# squander

A personal iOS spending tracker built for speed: keypad amount → short description → confirm category → done. No budgeting, no accounts, no network — local-only, and the whole point is to make logging an expense faster than the purchase itself.

## Stack

- Swift / SwiftUI, iOS 17+, SwiftData (local persistence, no CloudKit/accounts yet)
- Xcode Cloud for CI/CD (PR build+test, TestFlight from `main`) — not yet configured
- No third-party dependencies

## Spec-first workflow (OpenSpec)

All requirements live under `openspec/`, not in ad hoc planning docs. Use `/opsx:*` skills:

- `openspec/changes/<change-id>/` — proposal.md, design.md, specs/, tasks.md for an in-flight change
- `openspec status --change <id>` / `openspec validate <id> --strict` to check progress
- Once a change is fully implemented and merged, archive it with `/opsx:archive` so `openspec/specs/` reflects shipped capabilities

Do not create standalone spec/planning markdown outside `openspec/` — if you find any, fold the content into an OpenSpec change and delete the stray doc.

## Current state (2026-07-05)

- **No app code exists yet.** Only `openspec/changes/add-spending-tracker-mvp/` (proposal + design + specs + tasks.md) has been merged. `tasks.md` (8 sections, ~30 subtasks) is 0% complete — no Xcode project, no Swift files, no CI.
- Before any "new feature" work makes sense, the MVP itself needs to be built per `openspec/changes/add-spending-tracker-mvp/tasks.md`.

## Recurring routine (autonomous dev-loop)

A scheduled routine runs against this repo to: ideate features → user picks → plan/build/test/review/PR/merge per feature, in parallel via git worktrees, using OpenSpec for all specs. Twice a week it runs a technical-maintenance research pass instead of ideation. See `.claude/ROUTINE_STATE.md` for live status, schedule, and history — read it at the start of every routine run before doing anything else.

## Conventions for routine-generated work

- One git worktree + branch per feature/task, removed after merge.
- Match Claude model/effort to task complexity (e.g. lightweight model for boilerplate scaffolding, stronger model for design/categorization logic, thorough review pass before merge).
- Tests at every applicable level (unit, UI/functional, integration) for anything shipped; no PR without tests for the code it adds.
- Update this file and relevant skills under `.claude/skills/` when a new repeated pattern emerges (e.g. "how we scaffold a new SwiftUI feature module here").
