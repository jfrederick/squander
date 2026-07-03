# description-autocomplete

## ADDED Requirements

### Requirement: Suggestions from past descriptions
While the user types a description, the app SHALL display autocomplete suggestions drawn from the descriptions of previously saved expenses. Matching SHALL be case-insensitive and diacritic-insensitive, and SHALL match on prefix first, then substring.

#### Scenario: Prefix match suggests past description
- **WHEN** past expenses include "cafe" and the user types "ca"
- **THEN** "cafe" appears in the suggestion list

#### Scenario: Case-insensitive matching
- **WHEN** past expenses include "Mexican" and the user types "mex"
- **THEN** "Mexican" appears in the suggestion list

#### Scenario: Substring match ranks below prefix match
- **WHEN** past expenses include "electrolytes" and "espresso" and the user types "e"
- **THEN** both appear, with prefix matches ordered before substring-only matches

#### Scenario: No matches shows no suggestion UI
- **WHEN** the typed text matches no past description
- **THEN** no suggestion list is shown and typing continues unobstructed

### Requirement: Suggestion ranking and limit
The app SHALL show at most 5 suggestions, ranked by a combination of use frequency and recency (more frequent and more recently used descriptions rank higher). Duplicate descriptions SHALL be collapsed into a single suggestion.

#### Scenario: Frequent description ranks first
- **WHEN** "cafe" has been used 20 times and "carwash" twice, and the user types "ca"
- **THEN** "cafe" is listed before "carwash"

#### Scenario: At most five suggestions
- **WHEN** more than 5 past descriptions match the typed text
- **THEN** only the top 5 ranked suggestions are displayed

#### Scenario: Duplicates collapsed
- **WHEN** "cafe" has been used many times and the user types "caf"
- **THEN** "cafe" appears exactly once in the suggestion list

### Requirement: Accepting a suggestion
Tapping a suggestion SHALL fill the description field with the suggested text exactly as originally saved and SHALL immediately apply that description's remembered category, skipping the category confirmation step.

#### Scenario: Tap fills and fast-tracks category
- **WHEN** the user types "ca" and taps the suggestion "cafe", which is mapped to category "Food & Drink"
- **THEN** the description field shows "cafe"
- **AND** the expense is assigned "Food & Drink" without a category confirmation prompt

#### Scenario: Typed text matching a past description exactly behaves like acceptance
- **WHEN** the user types "cafe" in full (matching a past description exactly, ignoring case) and proceeds
- **THEN** the remembered category is applied without a confirmation prompt
