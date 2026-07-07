import Foundation

/// The month-recap card's two derived facts that no existing aggregator
/// provides: the month's biggest spending day and its longest run of
/// no-spend days. Total, category ranking, and the month-over-month
/// comparison come from TotalsAggregator/CategoryBreakdown/MonthComparison —
/// the view composes them (spec: spending-insights, month recap).
public struct MonthRecap: Equatable, Sendable {
    public struct DayTotal: Equatable, Sendable {
        public let day: Date
        public let total: Int

        public init(day: Date, total: Int) {
            self.day = day
            self.total = total
        }
    }

    /// The calendar day with the highest total; ties break to the earliest
    /// day. Nil when the month has no expenses.
    public let biggestDay: DayTotal?
    /// Longest run of consecutive days with no spending, over the month's
    /// elapsed days: the whole month for past months, days 1 through `asOf`'s
    /// day (inclusive) for the month containing `asOf`.
    public let longestNoSpendStreak: Int

    public init(biggestDay: DayTotal?, longestNoSpendStreak: Int) {
        self.biggestDay = biggestDay
        self.longestNoSpendStreak = longestNoSpendStreak
    }

    /// Recap copy, Core-built and unit-tested like WeeklyDigest.body and
    /// SpendingPace.headline — the views never assemble these sentences.
    public var biggestDayLine: String? {
        biggestDay.map {
            "Biggest day: \($0.day.formatted(.dateTime.month(.abbreviated).day())) · \($0.total.wholeDollars)"
        }
    }

    public var streakLine: String {
        "Longest no-spend streak: \(longestNoSpendStreak) \(longestNoSpendStreak == 1 ? "day" : "days")"
    }

    /// Nil when the month has no expenses — nothing to recap (same
    /// convention as SpendingPace.compute and WeeklyDigest: the degenerate
    /// "30-day streak, nothing else" card is unrepresentable).
    public static func compute(
        expenses: [(timestamp: Date, amount: Int)],
        monthContaining month: Date,
        asOf: Date,
        calendar: Calendar
    ) -> MonthRecap? {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let daysInMonth = calendar.range(of: .day, in: .month, for: month)?.count else {
            return nil
        }

        var totalsByDayStart: [Date: Int] = [:]
        for expense in expenses where interval.start <= expense.timestamp && expense.timestamp < interval.end {
            totalsByDayStart[calendar.startOfDay(for: expense.timestamp), default: 0] += expense.amount
        }
        guard !totalsByDayStart.isEmpty else { return nil }

        let biggest = totalsByDayStart
            .max { a, b in
                if a.value != b.value { return a.value < b.value }
                return a.key > b.key
            }
            .map { DayTotal(day: $0.key, total: $0.value) }

        // Elapsed days: cap at asOf's day when asOf falls inside this month,
        // so a current-month recap doesn't count the future as a streak.
        let elapsedDays: Int
        if interval.start <= asOf && asOf < interval.end {
            elapsedDays = calendar.component(.day, from: asOf)
        } else if asOf >= interval.end {
            elapsedDays = daysInMonth
        } else {
            elapsedDays = 0
        }

        var longest = 0
        var run = 0
        for dayOrdinal in 0..<elapsedDays {
            guard let day = calendar.date(byAdding: .day, value: dayOrdinal, to: interval.start) else { continue }
            if totalsByDayStart[calendar.startOfDay(for: day)] == nil {
                run += 1
                longest = max(longest, run)
            } else {
                run = 0
            }
        }

        return MonthRecap(biggestDay: biggest, longestNoSpendStreak: longest)
    }
}
