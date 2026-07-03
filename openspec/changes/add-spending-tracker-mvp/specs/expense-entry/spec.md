# expense-entry

## ADDED Requirements

### Requirement: Launch directly into amount entry
The app SHALL present the expense entry screen with a numeric keypad visible and active immediately on launch, with no splash screen, login, or intermediate navigation. The user SHALL be able to begin typing an amount with their first tap.

#### Scenario: Cold launch lands on keypad
- **WHEN** the user opens the app from a terminated state
- **THEN** the entry screen is displayed with the numeric keypad ready for input
- **AND** the amount display shows an empty/zero state

#### Scenario: Return from background resets to keypad when idle
- **WHEN** the user returns to the app after it has been in the background for more than 5 minutes with a partially entered expense
- **THEN** the entry screen is shown reset to an empty amount

#### Scenario: Quick return from background preserves in-progress entry
- **WHEN** the user returns to the app within 5 minutes of backgrounding it mid-entry
- **THEN** the partially entered amount and/or description are preserved

### Requirement: Whole-dollar amount entry
The app SHALL accept expense amounts as whole dollars only. The keypad SHALL contain the digits 0–9 and a delete key, and SHALL NOT offer a decimal separator. Amounts SHALL be between $1 and $99,999 inclusive.

#### Scenario: Digits build the amount
- **WHEN** the user taps 4, then 2 on the keypad
- **THEN** the amount display shows $42

#### Scenario: No decimal entry possible
- **WHEN** the user views the keypad
- **THEN** no decimal separator key is present and the displayed amount never shows cents

#### Scenario: Leading zeros are ignored
- **WHEN** the user taps 0 as the first digit
- **THEN** the amount remains in its empty/zero state

#### Scenario: Delete removes the last digit
- **WHEN** the amount shows $42 and the user taps delete
- **THEN** the amount shows $4

#### Scenario: Amount capped at maximum
- **WHEN** the amount shows $99,999 and the user taps another digit
- **THEN** the additional digit is rejected and the amount remains $99,999

#### Scenario: Zero amount cannot proceed
- **WHEN** no digits have been entered (amount is empty/zero)
- **THEN** the control to proceed to description entry is disabled

### Requirement: Description entry follows amount entry
After confirming an amount, the app SHALL prompt for a short free-text description of the expense with the text keyboard already focused. Descriptions SHALL be 1–40 characters after trimming leading/trailing whitespace.

#### Scenario: Proceeding to description
- **WHEN** the user has entered a non-zero amount and taps Next
- **THEN** a description field appears with the keyboard focused and the amount still visible

#### Scenario: Empty description cannot be saved
- **WHEN** the description field is empty or contains only whitespace
- **THEN** the save control is disabled

#### Scenario: Overlong description is truncated at input
- **WHEN** the user has typed 40 characters in the description field
- **THEN** further characters are not accepted

#### Scenario: Backing out to amount
- **WHEN** the user is on the description step and taps Back
- **THEN** the amount entry step is shown again with the previously entered amount intact

### Requirement: Saving an expense
The app SHALL create an expense record containing the amount, trimmed description, assigned category, and the current date and time when the user completes the entry flow. After saving, the app SHALL return to an empty amount entry state ready for the next expense and SHALL show a brief non-blocking confirmation.

#### Scenario: Successful save resets the flow
- **WHEN** the user saves an expense of $12 described "cafe"
- **THEN** an expense record is persisted with amount $12, description "cafe", the confirmed category, and the current timestamp
- **AND** the entry screen resets to an empty amount with the keypad ready

#### Scenario: Save confirmation is non-blocking
- **WHEN** an expense is saved
- **THEN** a transient confirmation (e.g., toast/checkmark) is shown without requiring any tap to dismiss
