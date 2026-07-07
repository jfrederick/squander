# expense-entry

## MODIFIED Requirements

### Requirement: Saving an expense
The app SHALL create an expense record containing the amount, trimmed description, assigned category, and the current date and time when the user completes the entry flow. When the save completes, the app SHALL switch to the Spent tab (the totals tab) and SHALL show a brief non-blocking confirmation. The entry screen SHALL reset to an empty amount entry state, ready for the next expense when the user returns to it.

#### Scenario: Successful save lands on Spent
- **WHEN** the user saves an expense of $12 described "cafe"
- **THEN** an expense record is persisted with amount $12, description "cafe", the confirmed category, and the current timestamp
- **AND** the app switches to the Spent tab, which reflects the new expense

#### Scenario: Save confirmation is non-blocking
- **WHEN** an expense is saved
- **THEN** a transient confirmation (e.g., toast/checkmark) is shown without requiring any tap to dismiss

#### Scenario: Entry resets behind the navigation
- **WHEN** the user returns to the Log tab after a save
- **THEN** the keypad shows an empty amount ready for a new expense
