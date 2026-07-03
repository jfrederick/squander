# expense-management

## ADDED Requirements

### Requirement: Recent expenses list
The app SHALL provide a browsable list of saved expenses in reverse chronological order, grouped by calendar day, showing each expense's amount, description, and category. The list SHALL be reachable from the Totals tab by tapping a day, week, or month row, which shows the expenses of that period.

#### Scenario: Drill into a day
- **WHEN** the user taps today's row in the Daily view
- **THEN** a list of today's expenses is shown with amount, description, and category for each

#### Scenario: Drill into a month
- **WHEN** the user taps "July 2026" in the Monthly view
- **THEN** all July 2026 expenses are listed grouped by day

### Requirement: Editing an expense
The app SHALL allow editing an existing expense's amount, description, and category, applying the same validation rules as entry (whole dollars $1–$99,999; description 1–40 characters; category from the existing set).

#### Scenario: Edit amount
- **WHEN** the user edits a $12 expense and changes the amount to $21
- **THEN** the expense is updated and all affected totals reflect $21

#### Scenario: Edit validation matches entry
- **WHEN** the user clears the description while editing
- **THEN** the save control is disabled until a non-empty description is entered

#### Scenario: Edited timestamp is preserved
- **WHEN** the user edits an expense's amount
- **THEN** the expense's original date and time remain unchanged

### Requirement: Deleting an expense
The app SHALL allow deleting an expense via swipe-to-delete with a brief undo affordance. Deletion SHALL remove the expense from all lists and totals.

#### Scenario: Swipe to delete with undo
- **WHEN** the user swipes an expense row and taps Delete
- **THEN** the expense is removed and a transient Undo affordance appears

#### Scenario: Undo restores
- **WHEN** the user taps Undo within the affordance window
- **THEN** the expense is restored with its original amount, description, category, and timestamp
