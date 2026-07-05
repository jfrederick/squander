import SwiftUI
import SwiftData
import Charts
import SpendthriftCore

/// Month insights: total with month-over-month comparison, category
/// breakdown donut, and ranked category list. One calendar month at a time,
/// stepping back through history (never past the current month). All
/// aggregation math lives in SpendthriftCore; this view only formats it.
struct InsightsView: View {
    @Query(sort: \Expense.timestamp, order: .reverse)
    private var expenses: [Expense]

    @Query
    private var categories: [Category]

    /// Start of the month being shown.
    @State private var monthStart: Date

    init() {
        let start = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
        _monthStart = State(initialValue: start)
    }

    private var calendar: Calendar { .current }

    // MARK: - Derived data

    private var currentMonthStart: Date {
        calendar.dateInterval(of: .month, for: .now)?.start ?? .now
    }

    private var isCurrentMonth: Bool {
        monthStart == currentMonthStart
    }

    private func total(forMonthContaining date: Date) -> Int? {
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return nil }
        let amounts = expenses
            .filter { $0.timestamp >= interval.start && $0.timestamp < interval.end }
            .map { $0.amountDollars }
        return amounts.isEmpty ? nil : amounts.reduce(0, +)
    }

    private var monthExpenses: [Expense] {
        guard let interval = calendar.dateInterval(of: .month, for: monthStart) else { return [] }
        return expenses.filter { $0.timestamp >= interval.start && $0.timestamp < interval.end }
    }

    private var monthTotal: Int {
        monthExpenses.map { $0.amountDollars }.reduce(0, +)
    }

    private var breakdown: [CategoryShare] {
        CategoryBreakdown.compute(expenses: monthExpenses.map {
            (amount: $0.amountDollars, category: $0.category?.name ?? "Other")
        })
    }

    private var comparison: MonthComparison {
        let previousTotal = calendar.date(byAdding: .month, value: -1, to: monthStart)
            .flatMap { total(forMonthContaining: $0) }
        return MonthComparison.compute(currentTotal: monthTotal, previousTotal: previousTotal)
    }

    private var colorNamesByCategory: [String: String] {
        Dictionary(categories.map { ($0.name, $0.colorName) }, uniquingKeysWith: { first, _ in first })
    }

    private func color(for categoryName: String) -> Color {
        CategoryColor.color(named: colorNamesByCategory[categoryName] ?? "gray")
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            monthStepper

            if monthExpenses.isEmpty {
                Spacer()
                Text("No expenses this month")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("insights-empty")
                Spacer()
            } else {
                List {
                    Section {
                        VStack(alignment: .center, spacing: 12) {
                            Text(monthTotal.wholeDollars)
                                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                                .accessibilityIdentifier("insights-total")
                            comparisonLine
                            donutChart
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .listRowSeparator(.hidden)

                    Section("Categories") {
                        ForEach(Array(breakdown.enumerated()), id: \.offset) { index, share in
                            categoryRow(share)
                                .accessibilityElement(children: .combine)
                                .accessibilityIdentifier("insights-category-row-\(index)")
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pieces

    private var monthStepper: some View {
        HStack {
            Button {
                step(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .accessibilityIdentifier("insights-prev-month")
            .accessibilityLabel("Previous month")

            Spacer()

            Text(monthStart.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
                .accessibilityIdentifier("insights-month-title")

            Spacer()

            Button {
                step(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(isCurrentMonth)
            .accessibilityIdentifier("insights-next-month")
            .accessibilityLabel("Next month")
        }
        .padding()
    }

    private func step(by months: Int) {
        guard let next = calendar.date(byAdding: .month, value: months, to: monthStart) else { return }
        // Never step past the current month.
        guard next <= currentMonthStart else { return }
        monthStart = next
    }

    @ViewBuilder
    private var comparisonLine: some View {
        Group {
            if let percent = comparison.percentChange {
                HStack(spacing: 4) {
                    Image(systemName: comparisonSymbol)
                    Text("\(signedDollars(comparison.delta)) (\(signedPercent(percent))) vs last month")
                }
                .font(.subheadline)
                .foregroundStyle(comparisonColor)
            } else {
                Text("No previous month to compare")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("insights-comparison")
    }

    private var comparisonSymbol: String {
        switch comparison.direction {
        case .increase: return "arrow.up.right"
        case .decrease: return "arrow.down.right"
        case .flat: return "equal"
        }
    }

    private var comparisonColor: Color {
        switch comparison.direction {
        case .increase: return .red
        case .decrease: return .green
        case .flat: return .secondary
        }
    }

    private func signedDollars(_ delta: Int) -> String {
        delta < 0 ? "-\(abs(delta).wholeDollars)" : "+\(delta.wholeDollars)"
    }

    private func signedPercent(_ percent: Int) -> String {
        percent < 0 ? "\(percent)%" : "+\(percent)%"
    }

    private var donutChart: some View {
        Chart(breakdown, id: \.category) { share in
            SectorMark(
                angle: .value("Total", share.total),
                innerRadius: .ratio(0.6)
            )
            .foregroundStyle(color(for: share.category))
        }
        .frame(height: 180)
        .accessibilityIdentifier("insights-donut")
        .accessibilityLabel("Category breakdown donut chart")
    }

    @ViewBuilder
    private func categoryRow(_ share: CategoryShare) -> some View {
        HStack {
            Circle()
                .fill(color(for: share.category))
                .frame(width: 10, height: 10)
            Text(share.category)
            Spacer()
            Text(share.total.wholeDollars)
                .fontWeight(.medium)
            Text("\(share.share)%")
                .foregroundStyle(.secondary)
                .frame(minWidth: 44, alignment: .trailing)
        }
    }
}

#Preview {
    NavigationStack {
        InsightsView()
    }
}
