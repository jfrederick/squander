# widget-quick-entry

## MODIFIED Requirements

### Requirement: Home Screen widget with today's total
The app SHALL provide Home Screen widgets (small and medium) showing three whole-dollar spending totals — the calendar day (most prominent), the calendar month, and the calendar year containing the current moment — updating when expenses change (including in-app logging) and at day rollover. The widget SHALL display a small vector flame mark. In the widget's standard full-color rendering, the widget SHALL be outlined in light green when today's total is $0 and in red otherwise (system contexts that strip widget backgrounds — StandBy, tinted Home Screens — omit the outline along with the background). Tapping the widget outside any button SHALL open the app directly to the amount keypad.

#### Scenario: Three totals reflect current periods
- **WHEN** today's expenses sum to $47, this month's to $310, and this year's to $4,200, and the widget refreshes
- **THEN** the widget shows $47 as today's total, $310 for the month, and $4,200 for the year

#### Scenario: No spending today outlines green
- **WHEN** today's total is $0
- **THEN** the widget's outline is light green

#### Scenario: Any spending today outlines red
- **WHEN** today's total is $12
- **THEN** the widget's outline is red

#### Scenario: In-app logging refreshes the widget
- **WHEN** the user logs an expense on the in-app keypad
- **THEN** the widget's totals and outline refresh without waiting for day rollover

#### Scenario: Day rollover resets the displayed totals
- **WHEN** a new calendar day begins in the device time zone
- **THEN** the widget shows $0 (or the new day's total) rather than yesterday's, and month/year totals recompute for the new day

#### Scenario: Tap opens the keypad
- **WHEN** the user taps the widget's summary area
- **THEN** the app opens on the entry keypad ready for input
