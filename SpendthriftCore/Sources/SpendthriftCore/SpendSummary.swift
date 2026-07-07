import Foundation

/// Whole-dollar spending totals for the calendar day, month, and year
/// containing a reference date — the widget's three headline numbers.
public struct SpendSummary: Equatable, Sendable {
    public let today: Int
    public let thisMonth: Int
    public let thisYear: Int

    public init(today: Int, thisMonth: Int, thisYear: Int) {
        self.today = today
        self.thisMonth = thisMonth
        self.thisYear = thisYear
    }

    /// Placeholder / store-unavailable fallback.
    public static let zero = SpendSummary(today: 0, thisMonth: 0, thisYear: 0)

    /// The widget's status threshold: red once anything has been spent
    /// today, light green otherwise (spec: widget-quick-entry). Kept here so
    /// the policy is unit-tested; the widget only maps it to colors.
    public var hasSpentToday: Bool { today > 0 }

    /// Sums expenses into the day/month/year periods containing `date`,
    /// using the given calendar's period boundaries (half-open intervals,
    /// matching every other aggregation in the app).
    public static func compute(
        expenses: [(timestamp: Date, amount: Int)],
        asOf date: Date,
        calendar: Calendar
    ) -> SpendSummary {
        func total(of component: Calendar.Component) -> Int {
            guard let interval = calendar.dateInterval(of: component, for: date) else { return 0 }
            return expenses
                .filter { interval.start <= $0.timestamp && $0.timestamp < interval.end }
                .reduce(0) { $0 + $1.amount }
        }
        return SpendSummary(
            today: total(of: .day),
            thisMonth: total(of: .month),
            thisYear: total(of: .year)
        )
    }
}
