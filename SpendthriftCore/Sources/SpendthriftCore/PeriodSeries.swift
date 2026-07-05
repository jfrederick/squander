import Foundation

/// Granularity for a fixed-length period series (trend chart).
public enum PeriodGranularity: Sendable {
    case daily
    case weekly
    case monthly

    /// The calendar component used to bucket a timestamp into a period.
    var component: Calendar.Component {
        switch self {
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .monthly: return .month
        }
    }
}

/// Builds fixed-length windows of period totals (unlike `TotalsAggregator`'s
/// list-oriented functions, which omit periods with no expenses) so charts
/// can render zero-height bars for empty periods.
public enum PeriodSeries {
    /// Returns exactly `count` periods of the given granularity, ending with
    /// the period containing `endingAt`, ordered oldest-to-newest (the
    /// current period is last) — the order a bar chart wants to draw in.
    /// Periods with no matching expenses get a zero total.
    public static func periodSeries(
        of expenses: [(timestamp: Date, amount: Int)],
        granularity: PeriodGranularity,
        count: Int,
        endingAt: Date,
        calendar: Calendar
    ) -> [PeriodTotal] {
        guard count > 0, let currentInterval = calendar.dateInterval(of: granularity.component, for: endingAt) else {
            return []
        }

        // Walk backward from the current period to build the window's start
        // dates, then reverse into oldest-first order.
        var intervals: [DateInterval] = []
        intervals.reserveCapacity(count)
        var cursor = currentInterval
        intervals.append(cursor)
        for _ in 1..<count {
            guard let previousStart = calendar.date(byAdding: granularity.component, value: -1, to: cursor.start),
                  let previousInterval = calendar.dateInterval(of: granularity.component, for: previousStart) else {
                break
            }
            intervals.append(previousInterval)
            cursor = previousInterval
        }
        intervals.reverse()

        var totalsByStart: [Date: Int] = [:]
        for expense in expenses {
            guard let interval = calendar.dateInterval(of: granularity.component, for: expense.timestamp) else { continue }
            totalsByStart[interval.start, default: 0] += expense.amount
        }

        return intervals.map { interval in
            PeriodTotal(interval: interval, total: totalsByStart[interval.start] ?? 0)
        }
    }
}
