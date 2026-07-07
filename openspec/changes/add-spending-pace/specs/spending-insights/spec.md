# spending-insights

## ADDED Requirements

### Requirement: Spending pace on the Spent tab
The Spent tab SHALL display a one-line spending pace above the trend chart whenever the current calendar month has at least one expense: the month's projected whole-dollar total, computed by extrapolating the month-to-date total over the full month by elapsed days (day of month, inclusive of today). When the previous calendar month has expenses, the line SHALL include that total as a baseline and SHALL be colored red when the projection exceeds it, green when below it, and neutral when equal; with no previous-month expenses the line SHALL be neutral. When the current month has no expenses the line SHALL be hidden.

#### Scenario: Mid-month projection
- **WHEN** the user has spent $40 by the 10th of a 30-day month
- **THEN** the pace line shows a projected total of $120 for the month

#### Scenario: Running hotter than last month
- **WHEN** the projection is $150 and last month's total was $100
- **THEN** the pace line is red and shows the $100 baseline

#### Scenario: Running cooler than last month
- **WHEN** the projection is $80 and last month's total was $100
- **THEN** the pace line is green and shows the $100 baseline

#### Scenario: No baseline month
- **WHEN** the previous calendar month has no expenses
- **THEN** the pace line shows the projection in a neutral color without a baseline

#### Scenario: Empty month hides the pace
- **WHEN** the current calendar month has no expenses
- **THEN** no pace line is shown
