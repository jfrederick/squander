# spending-insights

## MODIFIED Requirements

### Requirement: Trend chart on the Totals tab
The Spent tab SHALL display a bar chart above the period list showing recent period totals for the selected granularity: the last 14 days (Daily), last 12 weeks (Weekly), or last 12 months (Monthly), including empty periods as zero bars. The current period's bar SHALL be visually distinguished. The chart SHALL update with the segmented control and reflect data changes immediately. Tapping a bar for a period with at least one expense SHALL open the drill-in expense list for that period, titled the same way as the corresponding period row; tapping a period with no expenses SHALL do nothing.

#### Scenario: Daily chart shows last 14 days
- **WHEN** the user opens the Spent tab with Daily selected
- **THEN** a bar chart of the last 14 calendar days' totals is shown with today's bar highlighted

#### Scenario: Empty periods appear as zero
- **WHEN** no expenses were recorded on a day within the chart window
- **THEN** that day appears in the chart with a zero-height bar (unlike the list, which omits it)

#### Scenario: Chart follows granularity switch
- **WHEN** the user switches the segmented control to Monthly
- **THEN** the chart shows the last 12 months' totals

#### Scenario: Tapping a bar opens that period's expenses
- **WHEN** today's expenses total $25 and the user taps today's bar on the Daily chart
- **THEN** the drill-in expense list opens titled "Today" showing today's expenses

#### Scenario: Tapping an empty period does nothing
- **WHEN** the user taps the chart where a day with no expenses renders its zero bar
- **THEN** no navigation occurs and the Spent screen stays in place

#### Scenario: Taps outside the plot area are ignored
- **WHEN** the user taps the chart's axis labels outside the plot area
- **THEN** no navigation occurs, even if the tap is horizontally aligned with a non-empty bar
