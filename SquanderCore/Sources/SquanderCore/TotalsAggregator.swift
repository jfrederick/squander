import Foundation

/// A whole-dollar total for a single calendar period (day/week/month).
public struct PeriodTotal: Equatable, Sendable {
    public let interval: DateInterval
    public let total: Int

    public init(interval: DateInterval, total: Int) {
        self.interval = interval
        self.total = total
    }
}

/// Aggregates expense amounts into daily, weekly, and monthly totals.
public enum TotalsAggregator {
    /// Groups expenses by calendar day, in reverse chronological order.
    /// Days with no expenses are absent.
    public static func dailyTotals(of expenses: [(timestamp: Date, amount: Int)], calendar: Calendar) -> [PeriodTotal] {
        aggregate(expenses: expenses, calendar: calendar, component: .day)
    }

    /// Groups expenses by calendar week (locale-aware start day), in reverse
    /// chronological order. Weeks with no expenses are absent.
    public static func weeklyTotals(of expenses: [(timestamp: Date, amount: Int)], calendar: Calendar) -> [PeriodTotal] {
        aggregate(expenses: expenses, calendar: calendar, component: .weekOfYear)
    }

    /// Groups expenses by calendar month, in reverse chronological order.
    /// Months with no expenses are absent.
    public static func monthlyTotals(of expenses: [(timestamp: Date, amount: Int)], calendar: Calendar) -> [PeriodTotal] {
        aggregate(expenses: expenses, calendar: calendar, component: .month)
    }

    private static func aggregate(
        expenses: [(timestamp: Date, amount: Int)],
        calendar: Calendar,
        component: Calendar.Component
    ) -> [PeriodTotal] {
        var totalsByIntervalStart: [Date: (interval: DateInterval, total: Int)] = [:]

        for expense in expenses {
            guard let interval = calendar.dateInterval(of: component, for: expense.timestamp) else { continue }
            let key = interval.start
            if var existing = totalsByIntervalStart[key] {
                existing.total += expense.amount
                totalsByIntervalStart[key] = existing
            } else {
                totalsByIntervalStart[key] = (interval, expense.amount)
            }
        }

        return totalsByIntervalStart.values
            .sorted { $0.interval.start > $1.interval.start }
            .map { PeriodTotal(interval: $0.interval, total: $0.total) }
    }
}
