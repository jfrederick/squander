# spending-insights

## ADDED Requirements

### Requirement: Trend chart on the Totals tab
The Totals tab SHALL display a bar chart above the period list showing recent period totals for the selected granularity: the last 14 days (Daily), last 12 weeks (Weekly), or last 12 months (Monthly), including empty periods as zero bars. The current period's bar SHALL be visually distinguished. The chart SHALL update with the segmented control and reflect data changes immediately.

#### Scenario: Daily chart shows last 14 days
- **WHEN** the user opens the Totals tab with Daily selected
- **THEN** a bar chart of the last 14 calendar days' totals is shown with today's bar highlighted

#### Scenario: Empty periods appear as zero
- **WHEN** no expenses were recorded on a day within the chart window
- **THEN** that day appears in the chart with a zero-height bar (unlike the list, which omits it)

#### Scenario: Chart follows granularity switch
- **WHEN** the user switches the segmented control to Monthly
- **THEN** the chart shows the last 12 months' totals

### Requirement: Month insights screen
The app SHALL provide an Insights screen reachable from a toolbar control on the Totals tab, showing one calendar month at a time (defaulting to the current month) with controls to step to earlier or later months. The screen SHALL show the month's total, a category breakdown donut chart, and a ranked category list.

#### Scenario: Opening insights
- **WHEN** the user taps the insights control on the Totals tab
- **THEN** the Insights screen shows the current month's total, donut chart, and category ranking

#### Scenario: Stepping months
- **WHEN** the user steps back one month from July 2026
- **THEN** the screen shows June 2026's insights
- **AND** stepping forward past the current month is not possible

### Requirement: Category breakdown
For the selected month, the app SHALL compute per-category whole-dollar totals and display each category with its amount and its percentage share of the month total, ranked by amount descending. Categories with no expenses in the month SHALL be omitted. The donut chart segments SHALL use each category's display color.

#### Scenario: Ranked breakdown
- **WHEN** July 2026 contains $300 Food & Drink, $150 Transport, and $50 Health
- **THEN** the list shows Food & Drink $300 (60%), Transport $150 (30%), Health $50 (10%) in that order

#### Scenario: Empty month
- **WHEN** the selected month has no expenses
- **THEN** the screen shows an empty state instead of a chart

### Requirement: Month-over-month comparison
The Insights screen SHALL compare the selected month's total against the previous calendar month: the absolute dollar difference and the percentage change, visually indicating direction. When the previous month has no expenses, the comparison SHALL state that no prior data exists instead of showing a percentage.

#### Scenario: Higher than last month
- **WHEN** July 2026 totals $1,240 and June 2026 totaled $1,000
- **THEN** the comparison shows +$240 (+24%) versus June, marked as an increase

#### Scenario: No prior month data
- **WHEN** the selected month is the first month containing expenses
- **THEN** the comparison area indicates there is no previous month to compare against
