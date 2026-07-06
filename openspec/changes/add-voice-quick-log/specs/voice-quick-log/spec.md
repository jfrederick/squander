# voice-quick-log

## ADDED Requirements

### Requirement: Spoken utterance parsing
The system SHALL provide a pure parser in SpendthriftCore that converts a transcribed utterance into a whole-dollar amount and a description, recognizing digit amounts with optional dollar sign, English number words from one through nine thousand nine hundred ninety-nine (including "a hundred"/"a thousand" forms and hyphenated compounds), optional currency words ("dollar", "dollars", "buck", "bucks"), optional connectives ("for", "on", "of"), and optional leading command filler ("log", "add", "spent"). Amount and description MUST parse in either order. Parsing MUST use the shared normalize(_:) treatment for matching and MUST reject amounts outside the keypad validity range (1 through the keypad maximum).

#### Scenario: Amount-first digit form
- **WHEN** the utterance is "$6 coffee" or "6 coffee"
- **THEN** the parser returns amount 6 and description "coffee"

#### Scenario: Amount-first word form with currency word
- **WHEN** the utterance is "six dollar coffee" or "six bucks for coffee"
- **THEN** the parser returns amount 6 and description "coffee"

#### Scenario: Description-first form
- **WHEN** the utterance is "coffee six dollars" or "coffee $6"
- **THEN** the parser returns amount 6 and description "coffee"

#### Scenario: Compound number words
- **WHEN** the utterance is "twenty-five dollars parking" or "a hundred and ten groceries"
- **THEN** the parser returns amounts 25 and 110 respectively with the correct descriptions

#### Scenario: Leading command filler stripped
- **WHEN** the utterance is "log six dollar coffee" or "spent 14 on lunch"
- **THEN** the parser returns amount 6/"coffee" and amount 14/"lunch" respectively

#### Scenario: No amount present
- **WHEN** the utterance contains no recognizable amount (e.g. "coffee at the corner shop")
- **THEN** the parser returns nil

#### Scenario: No description present
- **WHEN** the utterance contains an amount but no description tokens (e.g. "six dollars")
- **THEN** the parser returns nil

#### Scenario: Out-of-range amount
- **WHEN** the parsed amount is 0 or exceeds the keypad maximum
- **THEN** the parser returns nil

### Requirement: Hands-free expense creation via Siri
The system SHALL expose a Log Spoken Expense App Intent, registered through an AppShortcutsProvider with stable static invocation phrases (App Shortcut phrases cannot embed free-form String parameters), that obtains the dictated utterance through a single Siri follow-up prompt ("What did you spend?"), parses it, and saves the expense through the shared ExpenseStore write path without opening the app. A successful save MUST reload widget timelines.

#### Scenario: Prompted utterance logging
- **WHEN** the user says a registered phrase (e.g. "Log an expense in Spendthrift") and answers the follow-up with "six dollar coffee"
- **THEN** an expense of $6 with description "coffee" is saved without the app opening, and widget timelines are reloaded

### Requirement: Voice category resolution
The system SHALL resolve the category for a voice-logged expense in this order: the remembered LabelMapping for the normalized description; otherwise the CategorySuggester heuristic; otherwise the "Other" fallback category. The resolution MUST match in-app behavior for the same description.

#### Scenario: Remembered description
- **WHEN** the spoken description has an existing LabelMapping to "Food & Drink"
- **THEN** the expense is saved in "Food & Drink"

#### Scenario: Novel description with keyword match
- **WHEN** the spoken description has no mapping but matches a suggester keyword (e.g. "parking")
- **THEN** the expense is saved in the suggested category (e.g. "Transport")

#### Scenario: Unknown description
- **WHEN** the spoken description has no mapping and no suggestion
- **THEN** the expense is saved in "Other"

### Requirement: Spoken confirmation and failure dialogs
The system SHALL respond to every voice invocation with a spoken dialog: on success it MUST state the amount, description, and resolved category; on parse failure or out-of-range amount it MUST state that nothing was logged and why, and MUST NOT write any expense.

#### Scenario: Success confirmation
- **WHEN** "$6 coffee" is logged into "Food & Drink"
- **THEN** Siri speaks a confirmation containing "$6", "coffee", and "Food & Drink"

#### Scenario: Failure leaves no trace
- **WHEN** the utterance cannot be parsed
- **THEN** Siri speaks a corrective error message and the expense count is unchanged
