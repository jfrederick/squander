# spending-totals

## MODIFIED Requirements

### Requirement: Totals tab
The app SHALL provide a totals tab labeled "Spent", separate from the entry screen, reachable via a tab bar, with a matching "Spent" navigation title. The tab SHALL offer three views — Daily, Weekly, and Monthly — switchable with a segmented control, defaulting to Daily.

#### Scenario: Navigating to totals
- **WHEN** the user taps the Spent tab
- **THEN** the Daily view is shown with the segmented control on Daily

#### Scenario: Switching granularity
- **WHEN** the user selects Weekly on the segmented control
- **THEN** the list switches to weekly totals without leaving the tab
