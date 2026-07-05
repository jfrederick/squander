# data-persistence

## MODIFIED Requirements

### Requirement: Local-only storage
The app SHALL persist all data (expenses, categories, description→category mappings) on-device using SwiftData, stored in the app's App Group container so the widget extension can read and write the same store. The app SHALL NOT require an account, login, or network connection for any feature, and SHALL NOT transmit expense data off the device.

#### Scenario: Works in airplane mode
- **WHEN** the device has no network connectivity
- **THEN** entering, categorizing, browsing, and totaling expenses all work normally, including widget quick-log

#### Scenario: Data survives restart
- **WHEN** the user saves expenses, force-quits the app, and relaunches
- **THEN** all saved expenses, categories, and mappings are intact

#### Scenario: Existing data migrates to the shared container
- **WHEN** a user with data stored at the previous default location updates and launches the app
- **THEN** all expenses, categories, and mappings are available from the App Group store with nothing lost
