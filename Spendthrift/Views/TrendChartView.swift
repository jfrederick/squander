import SwiftUI
import Charts
import SpendthriftCore

/// Bar chart of recent period totals for the Spent tab header. Empty
/// periods render as zero-height bars; the current period (the series'
/// last element) is highlighted.
struct TrendChartView: View {
    let series: [PeriodTotal]
    let granularity: PeriodGranularity

    private var currentPeriodStart: Date? { series.last?.interval.start }

    private var calendarUnit: Calendar.Component {
        switch granularity {
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .monthly: return .month
        }
    }

    private var axisLabelFormat: Date.FormatStyle {
        switch granularity {
        case .daily, .weekly:
            return .dateTime.month(.abbreviated).day()
        case .monthly:
            return .dateTime.month(.abbreviated)
        }
    }

    var body: some View {
        Chart(series, id: \.interval.start) { period in
            BarMark(
                x: .value("Period", period.interval.start, unit: calendarUnit),
                y: .value("Total", period.total)
            )
            .foregroundStyle(
                period.interval.start == currentPeriodStart
                    ? Color.accentColor
                    : Color.accentColor.opacity(0.35)
            )
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                AxisValueLabel(format: axisLabelFormat)
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                AxisGridLine()
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .frame(height: 120)
        .accessibilityIdentifier("trend-chart")
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        let periodName: String
        switch granularity {
        case .daily: periodName = "days"
        case .weekly: periodName = "weeks"
        case .monthly: periodName = "months"
        }
        let currentTotal = series.last?.total ?? 0
        return "Spending trend for the last \(series.count) \(periodName). Current period total \(currentTotal.wholeDollars)."
    }
}
