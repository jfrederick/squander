# data-persistence

## ADDED Requirements

### Requirement: Local-only storage
The app SHALL persist all data (expenses, categories, description→category mappings) on-device using SwiftData. The app SHALL NOT require an account, login, or network connection for any feature, and SHALL NOT transmit expense data off the device.

#### Scenario: Works in airplane mode
- **WHEN** the device has no network connectivity
- **THEN** entering, categorizing, browsing, and totaling expenses all work normally

#### Scenario: Data survives restart
- **WHEN** the user saves expenses, force-quits the app, and relaunches
- **THEN** all saved expenses, categories, and mappings are intact

### Requirement: Expense record shape
An expense record SHALL store: amount as an integer number of whole dollars, description as saved by the user (original casing preserved), a normalized description key for matching, a reference to its category, and a creation timestamp stored unambiguously (UTC instant) and displayed in the device's current time zone and calendar.

#### Scenario: Amount stored as integer dollars
- **WHEN** an expense of $42 is saved
- **THEN** the stored amount is the integer 42 with no fractional component anywhere in the data model

#### Scenario: Original casing preserved, matching normalized
- **WHEN** the user saves a description "Mexican"
- **THEN** the record displays "Mexican" while matching and autocomplete use its normalized form

### Requirement: Referential integrity for categories
Every expense SHALL reference an existing category at all times. The data layer SHALL prevent deletion of a category that would orphan expenses unless the expenses are reassigned.

#### Scenario: Category with expenses is protected
- **WHEN** a delete is attempted on a category that has expenses
- **THEN** the operation requires choosing a replacement category for those expenses before completing

### Requirement: Schema versioning
The data model SHALL declare a schema version from the first release and use lightweight/staged migration so future model changes preserve user data.

#### Scenario: Upgrade preserves data
- **WHEN** the app is updated to a build with a newer schema version
- **THEN** existing expenses, categories, and mappings are migrated without loss
