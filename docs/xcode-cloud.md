# Xcode Cloud setup

Xcode Cloud workflow configuration lives server-side in App Store Connect, not
in this repository (design D9). This document records the intended workflow
settings so they can be recreated (or audited) there. The only in-repo pieces
are `ci_scripts/ci_post_clone.sh` and the committed `.xcodeproj`/schemes that
the workflows build against.

Scheme name: **Squander**

## Workflow 1: Pull Request

- **Start condition:** New pull request, or new commit pushed to a pull
  request, targeting `main`.
- **Environment:** Latest available Xcode release; latest iOS simulator
  runtime.
- **Actions:**
  1. Build the `Squander` scheme (Debug-ish/CI configuration) for iPhone
     simulator (latest iPhone model available in the Xcode Cloud image).
  2. Run tests via the `Squander` scheme's test action:
     - `SquanderTests` (unit tests, SwiftData/model-layer coverage — see
       `SquanderTests/`)
     - `SquanderUITests` (UI tests)
  3. Fail the workflow (block the PR) on any build or test failure.
- **Post-actions:** None required (no TestFlight distribution for PR builds).

## Workflow 2: Release

- **Start condition:** Push to `main` (i.e., a PR merge).
- **Environment:** Latest available Xcode release; latest iOS simulator
  runtime for the test phase, plus a device/archive destination for the
  archive phase.
- **Actions:**
  1. Build + test the `Squander` scheme, same as the PR workflow.
  2. Archive the `Squander` scheme.
  3. Distribute the archive to **TestFlight (Internal Testing)** only — no
     App Store submission from this workflow.

## SquanderCore package tests

`SquanderCore` is a local Swift package with its own `SquanderCoreTests`
target (run today via `swift test` locally). Xcode Cloud only runs the test
plan/targets attached to the `Squander` scheme's Test action — it does not
automatically discover package tests.

**Recommendation:** in Xcode, edit the `Squander` scheme and add
`SquanderCoreTests` as an additional test target under the Test action (Edit
Scheme -> Test -> Info -> "+"). Once added, both workflows above pick it up
automatically with no further Xcode Cloud configuration, since they simply
run "the scheme's tests."

## First-time setup checklist

When creating these workflows in App Store Connect for the first time:

- [ ] Add the repository to App Store Connect / Xcode Cloud and grant it
      access (GitHub App or equivalent).
- [ ] Confirm the `Squander` scheme is marked **Shared** in Xcode (Xcode
      Cloud can only see shared schemes).
- [ ] Set the app's **bundle identifier** in the Xcode Cloud product/app
      record to match the one configured in the Xcode project.
- [ ] Register the **App Group** (`group.dev.jimfrederick.squander`) and the
      **widget extension bundle id** (`dev.jimfrederick.squander.widgets`) in
      the Apple Developer portal / App Store Connect, and confirm both the
      app and `SquanderWidgets` targets are signed with the App Group
      capability. Archive builds will fail until this manual, one-time
      registration is done.
- [ ] Select the **signing team** (Apple Developer Program team) and confirm
      Xcode Cloud is set to automatically manage signing, or provide the
      correct manual provisioning profile if manual signing is used.
- [ ] Add `SquanderCoreTests` to the `Squander` scheme's Test action (see
      above) so package-level tests run in CI too.
- [ ] Create the **PR workflow** per the settings above; run it once against
      an open PR to confirm it triggers and passes.
- [ ] Create the **Release workflow** per the settings above; run it once
      against `main` to confirm archive + TestFlight distribution succeeds.
- [ ] Add TestFlight internal testers (at minimum, the developer's own Apple
      ID) so the first release build is actually installable.

## Pre-release TODO

- **App icon is a placeholder.** `Squander/Assets.xcassets/AppIcon.appiconset`
  currently declares only the `Contents.json` entry (a single 1024x1024
  universal iOS slot) with no image asset behind it. The Release workflow's
  archive step will fail App Store validation without a real icon image in
  place. Add the actual 1024x1024 PNG before the first TestFlight/App Store
  submission.
