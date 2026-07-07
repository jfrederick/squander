import Testing
import Foundation
@testable import SpendthriftCore

@Suite("SpendingPace")
struct SpendingPaceTests {
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

    @Test("projects month-to-date over the full month by elapsed days")
    func projectsByElapsedDays() {
        // June 10 (30-day month), $40 spent -> 40 * 30/10 = $120.
        let asOf = Self.date("2026-06-10T12:00:00-04:00")
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-06-03T09:00:00-04:00"), 15),
            (Self.date("2026-06-09T09:00:00-04:00"), 25)
        ]
        let pace = SpendingPace.compute(expenses: expenses, asOf: asOf, calendar: Self.calendar())
        #expect(pace?.monthToDate == 40)
        #expect(pace?.projectedTotal == 120)
        #expect(pace?.standing == .noBaseline)
    }

    @Test("projection rounds half up")
    func projectionRoundsHalfUp() {
        // July 3 (31-day month), $7 spent -> 7 * 31 / 3 = 72.33 -> 72;
        // and $9 -> 9 * 31 / 3 = 93 exact. Check a true .5: day 2 of a
        // 31-day month with $1 -> 31/2 = 15.5 -> 16.
        let cal = Self.calendar()
        let july3 = Self.date("2026-07-03T12:00:00-04:00")
        let sevenSpent: [(timestamp: Date, amount: Int)] = [(Self.date("2026-07-01T12:00:00-04:00"), 7)]
        #expect(SpendingPace.compute(expenses: sevenSpent, asOf: july3, calendar: cal)?.projectedTotal == 72)

        let july2 = Self.date("2026-07-02T12:00:00-04:00")
        let oneSpent: [(timestamp: Date, amount: Int)] = [(Self.date("2026-07-01T12:00:00-04:00"), 1)]
        #expect(SpendingPace.compute(expenses: oneSpent, asOf: july2, calendar: cal)?.projectedTotal == 16)
    }

    @Test("day one projects a full month of the first expense")
    func dayOneProjection() {
        let asOf = Self.date("2026-07-01T08:00:00-04:00")
        let expenses: [(timestamp: Date, amount: Int)] = [(Self.date("2026-07-01T07:30:00-04:00"), 6)]
        let pace = SpendingPace.compute(expenses: expenses, asOf: asOf, calendar: Self.calendar())
        #expect(pace?.projectedTotal == 6 * 31)
    }

    @Test("standing compares the projection against last month")
    func standingAgainstBaseline() {
        let asOf = Self.date("2026-07-10T12:00:00-04:00")
        // $50 by July 10 -> projects 50 * 31/10 = $155.
        let base: [(timestamp: Date, amount: Int)] = [(Self.date("2026-07-05T12:00:00-04:00"), 50)]

        let hot = base + [(Self.date("2026-06-15T12:00:00-04:00"), 100)]
        #expect(SpendingPace.compute(expenses: hot, asOf: asOf, calendar: Self.calendar())?.standing == .over)

        let cool = base + [(Self.date("2026-06-15T12:00:00-04:00"), 400)]
        let coolPace = SpendingPace.compute(expenses: cool, asOf: asOf, calendar: Self.calendar())
        #expect(coolPace?.standing == .under)
        #expect(coolPace?.previousMonthTotal == 400)

        let even = base + [(Self.date("2026-06-15T12:00:00-04:00"), 155)]
        #expect(SpendingPace.compute(expenses: even, asOf: asOf, calendar: Self.calendar())?.standing == .even)
    }

    @Test("January's baseline is December of the previous year")
    func baselineCrossesYearBoundary() {
        let asOf = Self.date("2026-01-10T12:00:00-05:00")
        let expenses: [(timestamp: Date, amount: Int)] = [
            (Self.date("2026-01-04T12:00:00-05:00"), 20),
            (Self.date("2025-12-20T12:00:00-05:00"), 300)
        ]
        let pace = SpendingPace.compute(expenses: expenses, asOf: asOf, calendar: Self.calendar())
        #expect(pace?.previousMonthTotal == 300)
        // 20 * 31/10 = 62 -> under 300.
        #expect(pace?.standing == .under)
    }

    @Test("an empty current month yields nil")
    func emptyMonthIsNil() {
        let asOf = Self.date("2026-07-10T12:00:00-04:00")
        let expenses: [(timestamp: Date, amount: Int)] = [(Self.date("2026-06-15T12:00:00-04:00"), 100)]
        #expect(SpendingPace.compute(expenses: expenses, asOf: asOf, calendar: Self.calendar()) == nil)
    }

    @Test("a zero-expense previous month is no baseline, not $0")
    func zeroPreviousMonthIsNoBaseline() {
        let asOf = Self.date("2026-07-10T12:00:00-04:00")
        let expenses: [(timestamp: Date, amount: Int)] = [(Self.date("2026-07-05T12:00:00-04:00"), 50)]
        let pace = SpendingPace.compute(expenses: expenses, asOf: asOf, calendar: Self.calendar())
        #expect(pace?.previousMonthTotal == nil)
        #expect(pace?.standing == .noBaseline)
    }
}
