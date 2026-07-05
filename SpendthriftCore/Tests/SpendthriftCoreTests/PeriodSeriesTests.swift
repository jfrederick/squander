import Testing
import Foundation
@testable import SpendthriftCore

@Suite("PeriodSeries")
struct PeriodSeriesTests {
    static func date(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let d = formatter.date(from: iso) else {
            fatalError("bad date \(iso)")
        }
        return d
    }

    /// A fixed non-UTC calendar (US Eastern) with Sunday as first weekday (US default).
    static func calendarSundayStart() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        cal.firstWeekday = 1 // Sunday
        return cal
    }

    /// Same time zone, but Monday-start week (e.g. many European locales).
    static func calendarMondayStart() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        cal.firstWeekday = 2 // Monday
        return cal
    }

    @Test("daily series has exactly count periods including zero days, oldest first")
    func dailySeriesFixedLengthWithZeros() {
        let cal = Self.calendarSundayStart()
        let now = Self.date("2026-07-04T14:00:00-04:00")
        // Expenses on July 4 (today) and July 1; July 2-3 and earlier are empty.
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-07-04T09:00:00-04:00"), 20),
            (Self.date("2026-07-04T12:00:00-04:00"), 5),
            (Self.date("2026-07-01T12:00:00-04:00"), 10)
        ]
        let series = PeriodSeries.periodSeries(of: expenses, granularity: .daily, count: 14, endingAt: now, calendar: cal)

        #expect(series.count == 14)
        // Oldest -> newest; current day is last.
        #expect(series.last?.interval.start == cal.startOfDay(for: now))
        #expect(series.last?.total == 25)
        // July 1 is third-from-last; July 2 and 3 are zero bars, still present.
        #expect(series[series.count - 4].total == 10) // July 1
        #expect(series[series.count - 3].total == 0)  // July 2
        #expect(series[series.count - 2].total == 0)  // July 3
        // Windows are consecutive calendar days.
        for i in 1..<series.count {
            #expect(series[i].interval.start == series[i - 1].interval.end)
        }
    }

    @Test("expenses outside the window are excluded")
    func expensesOutsideWindowExcluded() {
        let cal = Self.calendarSundayStart()
        let now = Self.date("2026-07-04T14:00:00-04:00")
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-06-01T12:00:00-04:00"), 999), // long before the 14-day window
            (Self.date("2026-07-04T12:00:00-04:00"), 7)
        ]
        let series = PeriodSeries.periodSeries(of: expenses, granularity: .daily, count: 14, endingAt: now, calendar: cal)
        #expect(series.count == 14)
        #expect(series.map { $0.total }.reduce(0, +) == 7)
    }

    @Test("weekly series spans 12 weeks with week-start alignment (Sunday start)")
    func weeklySeriesSundayStart() {
        let cal = Self.calendarSundayStart()
        // Saturday July 4 2026; its Sunday-start week is Jun 28 - Jul 4.
        let now = Self.date("2026-07-04T14:00:00-04:00")
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-06-28T12:00:00-04:00"), 11), // Sunday, same week as `now`
            (Self.date("2026-06-27T12:00:00-04:00"), 40)  // Saturday, previous week
        ]
        let series = PeriodSeries.periodSeries(of: expenses, granularity: .weekly, count: 12, endingAt: now, calendar: cal)

        #expect(series.count == 12)
        let currentWeek = cal.dateInterval(of: .weekOfYear, for: now)!
        #expect(series.last?.interval == currentWeek)
        #expect(series.last?.total == 11)
        #expect(series[series.count - 2].total == 40)
    }

    @Test("Monday-start calendar buckets a Sunday expense into the prior week")
    func weeklySeriesMondayStart() {
        let cal = Self.calendarMondayStart()
        // Monday July 6 2026 is the start of a Monday-start week.
        let now = Self.date("2026-07-06T09:00:00-04:00")
        // Sunday July 5 belongs to the *previous* Monday-start week (Jun 29 - Jul 5).
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-07-05T12:00:00-04:00"), 13)
        ]
        let series = PeriodSeries.periodSeries(of: expenses, granularity: .weekly, count: 12, endingAt: now, calendar: cal)

        #expect(series.count == 12)
        #expect(series.last?.total == 0)                 // week of Jul 6 has nothing
        #expect(series[series.count - 2].total == 13)    // week of Jun 29 has the Sunday expense
    }

    @Test("monthly series spans 12 months including empty ones")
    func monthlySeries() {
        let cal = Self.calendarSundayStart()
        let now = Self.date("2026-07-04T14:00:00-04:00")
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-07-01T12:00:00-04:00"), 1240),
            (Self.date("2026-05-15T12:00:00-04:00"), 300),
            (Self.date("2025-08-20T12:00:00-04:00"), 55) // 11 months back: first in window
        ]
        let series = PeriodSeries.periodSeries(of: expenses, granularity: .monthly, count: 12, endingAt: now, calendar: cal)

        #expect(series.count == 12)
        #expect(series.first?.total == 55)               // Aug 2025
        #expect(series.last?.total == 1240)              // Jul 2026 (current, last)
        #expect(series[series.count - 3].total == 300)   // May 2026
        #expect(series[series.count - 2].total == 0)     // Jun 2026 zero bar
        // Oldest month is exactly 11 months before the current month's start.
        let currentMonthStart = cal.dateInterval(of: .month, for: now)!.start
        let expectedOldest = cal.date(byAdding: .month, value: -11, to: currentMonthStart)!
        #expect(series.first?.interval.start == expectedOldest)
    }

    @Test("day boundary near local midnight stays in the local day")
    func timeZoneBoundary() {
        let cal = Self.calendarSundayStart()
        let now = Self.date("2026-07-04T23:55:00-04:00")
        // 23:50 local on July 3 is 03:50 UTC on July 4 — must bucket to July 3.
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-07-03T23:50:00-04:00"), 8)
        ]
        let series = PeriodSeries.periodSeries(of: expenses, granularity: .daily, count: 14, endingAt: now, calendar: cal)
        #expect(series.last?.total == 0)                 // July 4
        #expect(series[series.count - 2].total == 8)     // July 3
    }

    @Test("no expenses yields all-zero series of the requested length")
    func emptyExpensesAllZero() {
        let cal = Self.calendarSundayStart()
        let now = Self.date("2026-07-04T14:00:00-04:00")
        let series = PeriodSeries.periodSeries(of: [], granularity: .daily, count: 14, endingAt: now, calendar: cal)
        #expect(series.count == 14)
        #expect(series.allSatisfy { $0.total == 0 })
    }

    @Test("non-positive count yields empty series")
    func nonPositiveCount() {
        let cal = Self.calendarSundayStart()
        let now = Self.date("2026-07-04T14:00:00-04:00")
        #expect(PeriodSeries.periodSeries(of: [], granularity: .daily, count: 0, endingAt: now, calendar: cal).isEmpty)
        #expect(PeriodSeries.periodSeries(of: [], granularity: .monthly, count: -3, endingAt: now, calendar: cal).isEmpty)
    }
}
