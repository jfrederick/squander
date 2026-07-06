# expense-entry

## MODIFIED Requirements

### Requirement: Description entry follows amount entry
After confirming an amount, the app SHALL prompt for a short free-text description of the expense with the text keyboard already focused. Descriptions SHALL be 1–40 characters after trimming leading/trailing whitespace. The switch between the amount and description steps SHALL animate as a horizontal slide: the keypad slides off toward the leading edge while the description, category, and save controls slide into its place from the trailing edge, reversed when backing out.

#### Scenario: Proceeding to description
- **WHEN** the user has entered a non-zero amount and taps Next
- **THEN** a description field appears with the keyboard focused and the amount still visible

#### Scenario: Steps swap with a horizontal slide
- **WHEN** the user taps Next on a valid amount
- **THEN** the keypad slides off the screen toward the leading edge and the description step slides into its place from the trailing edge

#### Scenario: Empty description cannot be saved
- **WHEN** the description field is empty or contains only whitespace
- **THEN** the save control is disabled

#### Scenario: Overlong description is truncated at input
- **WHEN** the user has typed 40 characters in the description field
- **THEN** further characters are not accepted

#### Scenario: Backing out to amount
- **WHEN** the user is on the description step and taps Back
- **THEN** the amount entry step slides back in from the leading edge with the previously entered amount intact

### Requirement: Saving an expense
The app SHALL create an expense record containing the amount, trimmed description, assigned category, and the current date and time when the user completes the entry flow. When the save completes, the app SHALL switch to the Totals tab and SHALL show a brief non-blocking confirmation. The entry screen SHALL reset to an empty amount entry state, ready for the next expense when the user returns to it.

#### Scenario: Successful save lands on Totals
- **WHEN** the user saves an expense of $12 described "cafe"
- **THEN** an expense record is persisted with amount $12, description "cafe", the confirmed category, and the current timestamp
- **AND** the app switches to the Totals tab, which reflects the new expense

#### Scenario: Save confirmation is non-blocking
- **WHEN** an expense is saved
- **THEN** a transient confirmation (e.g., toast/checkmark) is shown without requiring any tap to dismiss

#### Scenario: Entry resets behind the navigation
- **WHEN** the user returns to the Entry screen after a save
- **THEN** the entry screen shows an empty amount with the keypad ready

## ADDED Requirements

### Requirement: Full-surface tap targets
Buttons in the entry flow (keypad keys, Next, Save) SHALL register a tap anywhere within their visible bounds, not only on the text or glyph inside them.

#### Scenario: Tap at the edge of a primary button
- **WHEN** the user taps inside the Next or Save button's visible rounded rectangle but away from its centered text
- **THEN** the tap registers exactly as a tap on the text would
