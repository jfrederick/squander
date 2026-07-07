import SwiftUI
import SwiftData
import SpendthriftCore

/// Spent tab: Daily/Weekly/Monthly segmented totals over a live @Query of
/// expenses so totals update automatically (design D7).
struct TotalsView: View {
    @Environment(\.expenseStore) private var store

    @Query(sort: \Expense.timestamp, order: .reverse)
    private var expenses: [Expense]

    @State private var granularity: Granularity = .daily

    private enum Granularity: String, CaseIterable, Identifiable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"

        var id: String { rawValue }
    }

    private var calendar: Calendar { .current }

    private var corePeriodGranularity: PeriodGranularity {
        switch granularity {
        case .daily: return .daily
        case .weekly: return .weekly
        case .monthly: return .monthly
        }
    }

    /// Fixed-length window for the trend chart (spec: 14 days / 12 weeks /
    /// 12 months), zero periods included, oldest first.
    private var chartSeries: [PeriodTotal] {
        let pairs = expenses.map { (timestamp: $0.timestamp, amount: $0.amountDollars) }
        let count: Int
        switch granularity {
        case .daily: count = 14
        case .weekly, .monthly: count = 12
        }
        return PeriodSeries.periodSeries(
            of: pairs,
            granularity: corePeriodGranularity,
            count: count,
            endingAt: .now,
            calendar: calendar
        )
    }

    private var periodTotals: [PeriodTotal] {
        let pairs = expenses.map { (timestamp: $0.timestamp, amount: $0.amountDollars) }
        switch granularity {
        case .daily:
            return TotalsAggregator.dailyTotals(of: pairs, calendar: calendar)
        case .weekly:
            return TotalsAggregator.weeklyTotals(of: pairs, calendar: calendar)
        case .monthly:
            return TotalsAggregator.monthlyTotals(of: pairs, calendar: calendar)
        }
    }

    /// Reverse-chronological, most-recent period first.
    private var orderedTotals: [PeriodTotal] {
        periodTotals.sorted { $0.interval.start > $1.interval.start }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Granularity", selection: $granularity) {
                    ForEach(Granularity.allCases) { g in
                        Text(g.rawValue).tag(g)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .accessibilityIdentifier("segmented-granularity")

                TrendChartView(series: chartSeries, granularity: corePeriodGranularity)
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                if orderedTotals.isEmpty {
                    Spacer()
                    Text("No expenses yet")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("totals-empty")
                    Spacer()
                } else {
                    List {
                        ForEach(Array(orderedTotals.enumerated()), id: \.offset) { index, periodTotal in
                            NavigationLink {
                                ExpenseListView(interval: periodTotal.interval, title: title(for: periodTotal, isCurrent: index == 0))
                            } label: {
                                row(for: periodTotal, isCurrent: index == 0)
                            }
                            .accessibilityIdentifier("totals-row-\(index)")
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Spent")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        InsightsView()
                    } label: {
                        Image(systemName: "chart.pie")
                    }
                    .accessibilityIdentifier("insights-button")
                    .accessibilityLabel("Insights")
                }
            }
        }
    }

    @ViewBuilder
    private func row(for periodTotal: PeriodTotal, isCurrent: Bool) -> some View {
        HStack {
            Text(title(for: periodTotal, isCurrent: isCurrent))
                .fontWeight(isCurrent ? .bold : .regular)
            Spacer()
            Text(periodTotal.total.wholeDollars)
                .fontWeight(isCurrent ? .bold : .regular)
        }
        .foregroundStyle(isCurrent ? Color.accentColor : .primary)
    }

    private func title(for periodTotal: PeriodTotal, isCurrent: Bool) -> String {
        switch granularity {
        case .daily:
            return dayTitle(for: periodTotal.interval.start, isCurrent: isCurrent)
        case .weekly:
            return weekTitle(for: periodTotal.interval)
        case .monthly:
            return monthTitle(for: periodTotal.interval.start)
        }
    }

    private func dayTitle(for date: Date, isCurrent: Bool) -> String {
        dayLabel(for: date, calendar: calendar)
    }

    private func weekTitle(for interval: DateInterval) -> String {
        let start = interval.start
        // Interval end is exclusive; show the last inclusive day of the week.
        let end = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
        let startText = start.formatted(.dateTime.month(.abbreviated).day())
        let endText = end.formatted(.dateTime.month(.abbreviated).day())
        return "\(startText) - \(endText)"
    }

    private func monthTitle(for date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }
}

#Preview {
    TotalsView()
}
