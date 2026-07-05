import Testing
import Foundation
@testable import SpendthriftCore

@Suite("TotalsAggregator")
struct TotalsAggregatorTests {
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

    @Test("day sums are whole dollars")
    func daySums() {
        let cal = Self.calendarSundayStart()
        // All on the same local day: 2026-07-04 in America/New_York (EDT, UTC-4)
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-07-04T14:00:00-04:00"), 12),
            (Self.date("2026-07-04T15:00:00-04:00"), 5),
            (Self.date("2026-07-04T20:00:00-04:00"), 30)
        ]
        let totals = TotalsAggregator.dailyTotals(of: expenses, calendar: cal)
        #expect(totals.count == 1)
        #expect(totals.first?.total == 47)
    }

    @Test("empty periods are omitted")
    func emptyPeriodsOmitted() {
        let cal = Self.calendarSundayStart()
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-07-04T14:00:00-04:00"), 12)
        ]
        let totals = TotalsAggregator.dailyTotals(of: expenses, calendar: cal)
        // Only one day present; "yesterday" (07-03) must not appear.
        #expect(totals.count == 1)
        let dayStart = cal.startOfDay(for: Self.date("2026-07-04T14:00:00-04:00"))
        #expect(totals.first?.interval.start == dayStart)
    }

    @Test("day boundary at 23:50 local counts toward that local day")
    func dayBoundaryAt2350Local() {
        let cal = Self.calendarSundayStart()
        // 23:50 local time on July 4 in America/New_York (EDT, UTC-4) is 2026-07-05T03:50:00Z
        let lateExpense = Self.date("2026-07-04T23:50:00-04:00")
        let expenses: [(timestamp: Date, amount: Int)] = [(lateExpense, 9)]
        let totals = TotalsAggregator.dailyTotals(of: expenses, calendar: cal)
        #expect(totals.count == 1)
        let expectedDayStart = cal.startOfDay(for: lateExpense)
        #expect(totals.first?.interval.start == expectedDayStart)

        // Confirm it does NOT fall into July 5th's bucket.
        let july5Start = cal.startOfDay(for: Self.date("2026-07-05T12:00:00-04:00"))
        #expect(totals.first?.interval.start != july5Start)
    }

    @Test("daily totals are in reverse chronological order")
    func dailyReverseChronological() {
        let cal = Self.calendarSundayStart()
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-07-01T12:00:00-04:00"), 10),
            (Self.date("2026-07-03T12:00:00-04:00"), 20),
            (Self.date("2026-07-02T12:00:00-04:00"), 15)
        ]
        let totals = TotalsAggregator.dailyTotals(of: expenses, calendar: cal)
        #expect(totals.map { $0.total } == [20, 15, 10])
    }

    @Test("weekly totals aggregate multiple days in the same week")
    func weeklyAggregatesDays() {
        let cal = Self.calendarSundayStart()
        // Sunday July 5, Monday July 6, Tuesday July 7 2026 - all in the same Sun-start week.
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-07-05T12:00:00-04:00"), 47),
            (Self.date("2026-07-06T12:00:00-04:00"), 10),
            (Self.date("2026-07-07T12:00:00-04:00"), 23)
        ]
        let totals = TotalsAggregator.weeklyTotals(of: expenses, calendar: cal)
        #expect(totals.count == 1)
        #expect(totals.first?.total == 80)
    }

    @Test("Monday-start week counts Sunday expense into the prior Monday's week")
    func mondayStartWeekCountsSundayIntoPriorWeek() {
        let cal = Self.calendarMondayStart()
        // Monday 2026-06-29 through Sunday 2026-07-05 is one Monday-start week.
        let mondayExpense = Self.date("2026-06-29T09:00:00-04:00")
        let sundayExpense = Self.date("2026-07-05T09:00:00-04:00") // Sunday, end of that same week
        let nextMondayExpense = Self.date("2026-07-06T09:00:00-04:00") // start of the *next* week

        let expenses: [(timestamp: Date, amount: Int)] = [
            (mondayExpense, 5),
            (sundayExpense, 7),
            (nextMondayExpense, 100)
        ]
        let totals = TotalsAggregator.weeklyTotals(of: expenses, calendar: cal)
        #expect(totals.count == 2)

        let mondayWeekInterval = cal.dateInterval(of: Calendar.Component.weekOfYear, for: mondayExpense)!
        let nextWeekInterval = cal.dateInterval(of: Calendar.Component.weekOfYear, for: nextMondayExpense)!

        let mondayWeekTotal = totals.first { $0.interval == mondayWeekInterval }
        let nextWeekTotal = totals.first { $0.interval == nextWeekInterval }

        #expect(mondayWeekTotal?.total == 12) // 5 (Monday) + 7 (Sunday) grouped into the same week
        #expect(nextWeekTotal?.total == 100)
    }

    @Test("monthly totals aggregate a whole month")
    func monthlyAggregatesMonth() {
        let cal = Self.calendarSundayStart()
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-07-01T12:00:00-04:00"), 1000),
            (Self.date("2026-07-15T12:00:00-04:00"), 200),
            (Self.date("2026-07-31T12:00:00-04:00"), 40)
        ]
        let totals = TotalsAggregator.monthlyTotals(of: expenses, calendar: cal)
        #expect(totals.count == 1)
        #expect(totals.first?.total == 1240)
    }

    @Test("monthly totals across different months are separate and reverse-chronological")
    func monthlySeparateMonths() {
        let cal = Self.calendarSundayStart()
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-06-15T12:00:00-04:00"), 300),
            (Self.date("2026-07-15T12:00:00-04:00"), 1240)
        ]
        let totals = TotalsAggregator.monthlyTotals(of: expenses, calendar: cal)
        #expect(totals.count == 2)
        #expect(totals.map { $0.total } == [1240, 300])
    }

    @Test("no expenses yields no totals")
    func noExpensesYieldsNoTotals() {
        let cal = Self.calendarSundayStart()
        let totals = TotalsAggregator.dailyTotals(of: [], calendar: cal)
        #expect(totals.isEmpty)
    }
}
