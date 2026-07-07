import Testing
import Foundation
@testable import SpendthriftCore

@Suite("MonthRecap")
struct MonthRecapTests {
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

    // A completed month: June 2026 (30 days), viewed from July.
    static let asOfJuly = date("2026-07-07T12:00:00-04:00")
    static let june = date("2026-06-15T12:00:00-04:00")

    @Test("biggest day is the day with the highest total")
    func biggestDayWins() {
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-06-03T09:00:00-04:00"), 20),
            (Self.date("2026-06-03T18:00:00-04:00"), 30),   // June 3: 50
            (Self.date("2026-06-20T09:00:00-04:00"), 45)    // June 20: 45
        ]
        let recap = MonthRecap.compute(expenses: expenses, monthContaining: Self.june, asOf: Self.asOfJuly, calendar: Self.calendar())
        #expect(recap.biggestDay?.total == 50)
        #expect(recap.biggestDay?.day == Self.calendar().startOfDay(for: Self.date("2026-06-03T09:00:00-04:00")))
    }

    @Test("biggest-day ties break to the earliest day")
    func biggestDayTieBreaksEarlier() {
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-06-10T09:00:00-04:00"), 40),
            (Self.date("2026-06-25T09:00:00-04:00"), 40)
        ]
        let recap = MonthRecap.compute(expenses: expenses, monthContaining: Self.june, asOf: Self.asOfJuly, calendar: Self.calendar())
        #expect(recap.biggestDay?.day == Self.calendar().startOfDay(for: Self.date("2026-06-10T09:00:00-04:00")))
    }

    @Test("streak spans the whole month for a completed month")
    func completedMonthStreak() {
        // Only expense on June 5: streaks are 4 (days 1-4) and 25 (days 6-30).
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-06-05T09:00:00-04:00"), 10)
        ]
        let recap = MonthRecap.compute(expenses: expenses, monthContaining: Self.june, asOf: Self.asOfJuly, calendar: Self.calendar())
        #expect(recap.longestNoSpendStreak == 25)
    }

    @Test("current month's streak only counts elapsed days")
    func currentMonthStreakCapped() {
        // asOf July 10; spend on July 3 -> considered days 1-10, longest 7 (days 4-10).
        let asOf = Self.date("2026-07-10T12:00:00-04:00")
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-07-03T09:00:00-04:00"), 10)
        ]
        let recap = MonthRecap.compute(expenses: expenses, monthContaining: asOf, asOf: asOf, calendar: Self.calendar())
        #expect(recap.longestNoSpendStreak == 7)
    }

    @Test("empty month: no biggest day, streak covers all elapsed days")
    func emptyMonth() {
        let recap = MonthRecap.compute(expenses: [], monthContaining: Self.june, asOf: Self.asOfJuly, calendar: Self.calendar())
        #expect(recap.biggestDay == nil)
        #expect(recap.longestNoSpendStreak == 30)
    }

    @Test("expenses outside the month are ignored")
    func outsideMonthIgnored() {
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-05-31T23:00:00-04:00"), 99),
            (Self.date("2026-07-01T01:00:00-04:00"), 99),
            (Self.date("2026-06-12T09:00:00-04:00"), 7)
        ]
        let recap = MonthRecap.compute(expenses: expenses, monthContaining: Self.june, asOf: Self.asOfJuly, calendar: Self.calendar())
        #expect(recap.biggestDay?.total == 7)
    }

    @Test("a future month has a zero-day window")
    func futureMonthHasNoElapsedDays() {
        let recap = MonthRecap.compute(expenses: [], monthContaining: Self.date("2026-08-15T12:00:00-04:00"), asOf: Self.asOfJuly, calendar: Self.calendar())
        #expect(recap.longestNoSpendStreak == 0)
    }
}
