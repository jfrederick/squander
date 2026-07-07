import Foundation

/// The current month's spending trajectory: month-to-date extrapolated over
/// the full month, judged against last month's total (spec:
/// spending-insights, spending pace).
public struct SpendingPace: Equatable, Sendable {
    /// How the projection stands against the previous month's baseline.
    public enum Standing: Equatable, Sendable {
        case over
        case under
        case even
        /// Previous month has no expenses — nothing meaningful to compare
        /// against (mirrors MonthComparison's nil-percent semantics).
        case noBaseline
    }

    public let monthToDate: Int
    /// Whole-dollar projection: monthToDate scaled by daysInMonth/dayOfMonth
    /// (today counts as elapsed), rounded half up.
    public let projectedTotal: Int
    /// Previous calendar month's total; nil when that month has no expenses.
    public let previousMonthTotal: Int?

    public var standing: Standing {
        guard let previousMonthTotal else { return .noBaseline }
        if projectedTotal > previousMonthTotal { return .over }
        if projectedTotal < previousMonthTotal { return .under }
        return .even
    }

    public init(monthToDate: Int, projectedTotal: Int, previousMonthTotal: Int?) {
        self.monthToDate = monthToDate
        self.projectedTotal = projectedTotal
        self.previousMonthTotal = previousMonthTotal
    }

    /// Computes the pace as of `date`. Returns nil when the calendar month
    /// containing `date` has no expenses — the view hides the line then.
    public static func compute(
        expenses: [(timestamp: Date, amount: Int)],
        asOf date: Date,
        calendar: Calendar
    ) -> SpendingPace? {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count else {
            return nil
        }

        func total(in interval: DateInterval) -> Int {
            expenses
                .filter { interval.start <= $0.timestamp && $0.timestamp < interval.end }
                .reduce(0) { $0 + $1.amount }
        }

        let monthToDate = total(in: monthInterval)
        guard monthToDate > 0 else { return nil }

        // Today counts as a full elapsed day so day 1 projects 31x a first
        // coffee rather than dividing by zero.
        let dayOfMonth = calendar.component(.day, from: date)
        // Integer half-up rounding: (m*D*2 + d) / (2*d).
        let projected = (monthToDate * daysInMonth * 2 + dayOfMonth) / (2 * dayOfMonth)

        var previousMonthTotal: Int?
        if let previousStart = calendar.date(byAdding: .month, value: -1, to: monthInterval.start),
           let previousInterval = calendar.dateInterval(of: .month, for: previousStart) {
            let previous = total(in: previousInterval)
            previousMonthTotal = previous > 0 ? previous : nil
        }

        return SpendingPace(
            monthToDate: monthToDate,
            projectedTotal: projected,
            previousMonthTotal: previousMonthTotal
        )
    }
}
