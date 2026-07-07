import Testing
import Foundation
@testable import SpendthriftCore

@Suite("SpendSummary")
struct SpendSummaryTests {
    static func date(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let d = formatter.date(from: iso) else {
            fatalError("bad date \(iso)")
        }
        return d
    }

    static func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        cal.firstWeekday = 1
        return cal
    }

    // Reference instant: July 7, 2026, mid-afternoon Eastern.
    static let now = date("2026-07-07T14:00:00-04:00")

    @Test("buckets expenses into day, month, and year totals")
    func bucketsAcrossPeriods() {
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-07-07T09:00:00-04:00"), 25),  // today
            (Self.date("2026-07-06T12:00:00-04:00"), 10),  // yesterday: month + year
            (Self.date("2026-06-15T12:00:00-04:00"), 30),  // last month: year only
            (Self.date("2025-12-31T12:00:00-05:00"), 99)   // last year: none
        ]
        let summary = SpendSummary.compute(expenses: expenses, asOf: Self.now, calendar: Self.calendar())
        #expect(summary.today == 25)
        #expect(summary.thisMonth == 35)
        #expect(summary.thisYear == 65)
    }

    @Test("no expenses yields zeros")
    func emptyIsZero() {
        let summary = SpendSummary.compute(expenses: [], asOf: Self.now, calendar: Self.calendar())
        #expect(summary == .zero)
    }

    @Test("status threshold: any spending today flips hasSpentToday")
    func hasSpentTodayThreshold() {
        #expect(!SpendSummary.zero.hasSpentToday)
        // Spending earlier this month/year but not today stays green.
        #expect(!SpendSummary(today: 0, thisMonth: 310, thisYear: 4200).hasSpentToday)
        #expect(SpendSummary(today: 1, thisMonth: 311, thisYear: 4201).hasSpentToday)
    }

    @Test("period boundaries are half-open in the calendar's time zone")
    func boundariesAreHalfOpen() {
        let expenses: [(timestamp: Date, amount: Int)] = [
            // 2026-01-01T00:00 Eastern: first instant of the year — inside.
            (Self.date("2026-01-01T00:00:00-05:00"), 7),
            // One second before New Year Eastern — last year, outside.
            (Self.date("2025-12-31T23:59:59-05:00"), 5),
            // Last instant of July 7 Eastern — today.
            (Self.date("2026-07-07T23:59:59-04:00"), 3),
            // Midnight starting July 8 Eastern — tomorrow, outside today/month? (inside month + year)
            (Self.date("2026-07-08T00:00:00-04:00"), 2)
        ]
        let summary = SpendSummary.compute(expenses: expenses, asOf: Self.now, calendar: Self.calendar())
        #expect(summary.today == 3)
        #expect(summary.thisMonth == 5)  // 3 today + 2 on July 8
        #expect(summary.thisYear == 12)  // 7 + 3 + 2
    }

    @Test("a UTC-midnight instant buckets by the calendar's zone, not UTC")
    func timeZoneMattersNotUTC() {
        // 2026-07-08T00:30Z is still 8:30pm July 7 Eastern → today.
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-07-08T00:30:00Z"), 11)
        ]
        let summary = SpendSummary.compute(expenses: expenses, asOf: Self.now, calendar: Self.calendar())
        #expect(summary.today == 11)
        #expect(summary.thisMonth == 11)
        #expect(summary.thisYear == 11)
    }
}
