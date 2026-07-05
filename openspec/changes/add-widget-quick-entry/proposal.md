# Proposal: add-widget-quick-entry

## Why

The fastest capture path still requires launching the app. For a user's handful of habitual expenses ("cafe $6", "electrolytes $4"), a Home Screen widget can log the whole expense in one tap without opening the app — and the widget doubles as an always-visible today's-total display.

## What Changes

- New WidgetKit extension target (`SquanderWidgets`) with an interactive Home Screen widget (small and medium) showing today's total and up to four one-tap quick-log buttons, plus Lock Screen accessory widgets showing today's total.
- Quick-log buttons are derived from usage: the most frequently used descriptions paired with each one's most common amount. Tapping logs the expense immediately via an App Intent (no app launch), using the remembered category.
- New `LogQuickExpenseIntent` App Intent that performs the write in the extension process and reloads widget timelines.
- The SwiftData store moves to an App Group container (shared between app and widget), with a one-time migration copying the existing store file on first launch of the updated app.
- Tapping the widget's total (or any non-button area) opens the app directly to the keypad.

## Capabilities

### New Capabilities

- `widget-quick-entry`: Home/Lock Screen widgets, quick-log presets, one-tap logging via App Intent.

### Modified Capabilities

- `data-persistence`: storage location moves to the App Group container with a one-time file migration; local-only guarantees unchanged.

## Impact

- New target `SquanderWidgets` (WidgetKit + App Intents), shared model code compiled into both targets.
- App Group entitlement (`group.dev.jimfrederick.squander`) on app and extension — requires signing configuration in App Store Connect/Xcode Cloud.
- `project.yml`/Xcode project regenerated; Xcode Cloud docs updated.
- New pure logic in `SquanderCore` (quick-log preset derivation) with unit tests; store-layer tests for the shared-container setup and intent write path.
