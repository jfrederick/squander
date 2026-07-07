# spending-insights

## ADDED Requirements

### Requirement: Month recap card
The Insights screen SHALL show a recap section for the displayed month whenever that month has at least one expense: the month total, up to three top categories with totals, the biggest spending day (ties to the earliest day), the longest run of consecutive no-spend days over the month's elapsed days (whole month for past months, through today for the current month), and the month-over-month comparison. The recap SHALL offer a share control that exports the recap as an image via the system share sheet. With no expenses in the displayed month, no recap is shown.

#### Scenario: Recap summarizes the month
- **WHEN** June has $500 across Food & Drink $300 and Transport $200, with $85 on June 14 as the biggest day
- **THEN** the June recap shows $500, the two categories ranked, "biggest day June 14 · $85", and the longest no-spend streak

#### Scenario: Current month counts only elapsed days
- **WHEN** today is the 10th and the last expense was on the 3rd
- **THEN** the recap's longest no-spend streak is 7, not extended by future days

#### Scenario: Sharing the recap
- **WHEN** the user taps the recap's share control
- **THEN** the system share sheet offers the recap as an image

#### Scenario: Empty month has no recap
- **WHEN** the displayed month has no expenses
- **THEN** no recap section is shown
