# Proposal: update-ui-polish

## Why

Day-to-day use surfaced four friction points: the big Next/Save buttons only register taps on their text label; the inline category confirmation area is a gray box whose only tap target is the small "Change" label; saving an expense leaves you staring at an empty keypad instead of the updated totals; and a drilled-in expense list (day/week/month) can't be narrowed to a single category.

## What Changes

- All entry-flow buttons (Next, Save, keypad keys) register taps anywhere on their visible surface.
- The inline category confirmation area becomes one full-width tap target that opens the category picker, and its background matches the app background (hairline outline instead of a gray fill).
- The entry flow's two steps swap with a horizontal slide: on Next the keypad slides off toward the leading edge and the description/category/save controls slide into its place from the trailing edge (reversed on Back).
- After a successful save, the app switches to the Totals tab (system `TabView`); the transient checkmark confirmation appears over Totals and the entry screen resets behind the navigation.
- The drilled-in expense list gains a toolbar category filter offering the categories present in that period, plus an "All Categories" reset.

## Capabilities

### Modified Capabilities

- `expense-entry`: horizontal slide between the amount and description steps; post-save navigation to Totals; full-surface tap targets.
- `expense-categorization`: category confirmation area is fully tappable and uses the app background.
- `expense-management`: category filter on the period expense list.

## Impact

- Views only: `RootTabView`, `EntryView`, `ExpenseListView` (no model or SpendthriftCore changes).
- UI tests updated for the post-save tab switch; the seeded dataset gains a second today expense (Transport $5) so the filter test is deterministic, shifting today's seeded total from $20 to $25.
