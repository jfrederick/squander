import Testing
import Foundation
@testable import SpendthriftCore

@Suite("PeriodHitTest")
struct PeriodHitTestTests {
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

    /// 3-day daily series around July 2-4, with an expense only on July 4.
    static func dailySeries() -> [PeriodTotal] {
        let cal = calendar()
        let now = date("2026-07-04T14:00:00-04:00")
        let expenses: [(timestamp: Date, amount: Int)] = [
            (date("2026-07-04T09:00:00-04:00"), 25)
        ]
        return PeriodSeries.periodSeries(of: expenses, granularity: .daily, count: 3, endingAt: now, calendar: cal)
    }

    @Test("date inside a period resolves to that period")
    func containedDateResolves() {
        let series = Self.dailySeries()
        let hit = series.period(containing: Self.date("2026-07-03T08:30:00-04:00"))
        #expect(hit?.interval == series[1].interval)
        #expect(hit?.total == 0)
    }

    @Test("current period's date resolves to the last element")
    func currentPeriodResolves() {
        let series = Self.dailySeries()
        let hit = series.period(containing: Self.date("2026-07-04T23:59:59-04:00"))
        #expect(hit?.interval == series[2].interval)
        #expect(hit?.total == 25)
    }

    @Test("a period-boundary instant resolves to the later period, matching expense bucketing")
    func boundaryResolvesToLaterPeriod() {
        let series = Self.dailySeries()
        // Midnight starting July 3 is July 2's exclusive end and July 3's inclusive start.
        let hit = series.period(containing: Self.date("2026-07-03T00:00:00-04:00"))
        #expect(hit?.interval == series[1].interval)
    }

    @Test("dates outside the window resolve to nil")
    func outsideWindowIsNil() {
        let series = Self.dailySeries()
        #expect(series.period(containing: Self.date("2026-07-01T12:00:00-04:00")) == nil)
        #expect(series.period(containing: Self.date("2026-07-05T00:00:00-04:00")) == nil)
    }

    @Test("empty series resolves to nil")
    func emptySeriesIsNil() {
        let series: [PeriodTotal] = []
        #expect(series.period(containing: Self.date("2026-07-03T12:00:00-04:00")) == nil)
    }
}
