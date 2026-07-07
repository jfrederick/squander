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
        // The <= 0 guard defends direct construction: compute() never emits
        // a zero baseline, but the memberwise init is public.
        guard let previousMonthTotal, previousMonthTotal > 0 else { return .noBaseline }
        if projectedTotal > previousMonthTotal { return .over }
        if projectedTotal < previousMonthTotal { return .under }
        return .even
    }

    /// The Spent tab's header sentence. Copy lives in Core — like
    /// WeeklyDigest.body(for:) — so the wording and the baseline-inclusion
    /// rule are unit-tested, not just substring-checked by a UI test.
    public var headline: String {
        var line = "On pace for \(projectedTotal.wholeDollars) this month"
        if let previousMonthTotal {
            line += " · last month \(previousMonthTotal.wholeDollars)"
        }
        return line
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

        // Month-to-date means through the end of asOf's day — a future-dated
        // expense later in the month is not elapsed spending and must not be
        // extrapolated (it would count once as spent and again as projected).
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
        let toDateInterval = DateInterval(start: monthInterval.start, end: min(dayEnd, monthInterval.end))
        let hasExpensesToDate = expenses.contains {
            toDateInterval.start <= $0.timestamp && $0.timestamp < toDateInterval.end
        }
        // Spec: the line shows when the month has at least one expense (not
        // "a positive total" — same thing today, but encode the spec's rule).
        guard hasExpensesToDate else { return nil }
        let monthToDate = total(in: toDateInterval)

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
