# spending-totals

## ADDED Requirements

### Requirement: Totals tab
The app SHALL provide a Totals tab, separate from the entry screen, reachable via a tab bar. The tab SHALL offer three views — Daily, Weekly, and Monthly — switchable with a segmented control, defaulting to Daily.

#### Scenario: Navigating to totals
- **WHEN** the user taps the Totals tab
- **THEN** the Daily view is shown with the segmented control on Daily

#### Scenario: Switching granularity
- **WHEN** the user selects Weekly on the segmented control
- **THEN** the list switches to weekly totals without leaving the tab

### Requirement: Daily totals
The Daily view SHALL list calendar days in reverse chronological order, each with the whole-dollar sum of that day's expenses. Days are defined by the device's current calendar and time zone. Today SHALL appear first and be visually distinguished; days with no expenses SHALL be omitted.

#### Scenario: Day sums are whole dollars
- **WHEN** today has expenses of $12, $5, and $30
- **THEN** the Daily view shows today with a total of $47

#### Scenario: Empty days omitted
- **WHEN** no expenses were recorded yesterday
- **THEN** yesterday does not appear in the Daily list

#### Scenario: Day boundaries use device time zone
- **WHEN** an expense is saved at 23:50 local time
- **THEN** it counts toward that local calendar day's total

### Requirement: Weekly totals
The Weekly view SHALL list calendar weeks in reverse chronological order, each with the whole-dollar sum of that week's expenses. Week boundaries SHALL follow the device locale's first day of the week. Each row SHALL show the week's date range; the current week SHALL appear first and be visually distinguished.

#### Scenario: Week sum aggregates its days
- **WHEN** the current week contains daily totals of $47, $10, and $23
- **THEN** the Weekly view shows the current week with a total of $80

#### Scenario: Locale-aware week start
- **WHEN** the device locale starts weeks on Monday
- **THEN** an expense saved on Sunday is counted in the week that began the previous Monday

### Requirement: Monthly totals
The Monthly view SHALL list calendar months in reverse chronological order, each with the whole-dollar sum of that month's expenses, labeled with month and year. The current month SHALL appear first and be visually distinguished.

#### Scenario: Month sum
- **WHEN** July 2026 contains expenses summing to $1,240
- **THEN** the Monthly view shows "July 2026 — $1,240"

### Requirement: Totals reflect data changes immediately
Totals SHALL update to reflect newly saved, edited, or deleted expenses the next time the Totals tab is displayed, with no manual refresh.

#### Scenario: New expense appears in totals
- **WHEN** the user saves a $15 expense and switches to the Totals tab
- **THEN** today's daily total includes the $15

#### Scenario: Deletion updates totals
- **WHEN** the user deletes a $20 expense from today and views the Totals tab
- **THEN** today's total is reduced by $20
