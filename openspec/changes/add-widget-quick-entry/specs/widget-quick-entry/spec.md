# widget-quick-entry

## ADDED Requirements

### Requirement: Home Screen widget with today's total
The app SHALL provide Home Screen widgets (small and medium) showing today's whole-dollar spending total, updating when expenses change and at day rollover. Tapping the widget outside any button SHALL open the app directly to the amount keypad.

#### Scenario: Total reflects today's expenses
- **WHEN** today's expenses sum to $47 and the widget refreshes
- **THEN** the widget shows $47 as today's total

#### Scenario: Day rollover resets the displayed total
- **WHEN** a new calendar day begins in the device time zone
- **THEN** the widget shows $0 (or the new day's total) rather than yesterday's

#### Scenario: Tap opens the keypad
- **WHEN** the user taps the widget's total area
- **THEN** the app opens on the entry keypad ready for input

### Requirement: Quick-log presets
The medium widget SHALL offer up to four quick-log buttons derived from usage history: the most frequently used descriptions (by mapping use count, ties broken by recency), each paired with that description's most common expense amount (ties broken by most recent). A description SHALL only qualify once it has at least two saved expenses. With no qualifying descriptions, the widget SHALL show the total and an "open app" affordance only.

#### Scenario: Presets derived from history
- **WHEN** "cafe" has 20 expenses, most commonly $6, and "electrolytes" has 5 expenses, most commonly $4
- **THEN** the widget's first two buttons are "cafe $6" and "electrolytes $4"

#### Scenario: Insufficient history hides presets
- **WHEN** no description has two or more saved expenses
- **THEN** no quick-log buttons are shown

### Requirement: One-tap logging via App Intent
Tapping a quick-log button SHALL save the expense (preset description, preset amount, the description's remembered category, current timestamp) directly from the widget without opening the app, then update the widget's displayed total. The write SHALL use the same validation and mapping rules as in-app entry. If the remembered category no longer exists, the expense SHALL be assigned "Other".

#### Scenario: One tap logs the expense
- **WHEN** the user taps the "cafe $6" button
- **THEN** a $6 "cafe" expense with cafe's remembered category is persisted
- **AND** the widget's today total increases by $6 without the app opening

#### Scenario: Logged expense appears in app
- **WHEN** the user opens the app after logging from the widget
- **THEN** the expense appears in totals and expense lists like any in-app entry

### Requirement: Lock Screen widgets
The app SHALL provide Lock Screen accessory widgets (circular and rectangular) showing today's total, opening the app to the keypad when tapped.

#### Scenario: Rectangular accessory shows total
- **WHEN** the user adds the rectangular Lock Screen widget
- **THEN** it displays today's whole-dollar total and the app name
