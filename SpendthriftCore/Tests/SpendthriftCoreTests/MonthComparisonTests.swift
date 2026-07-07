import Testing
import Foundation
@testable import SpendthriftCore

@Suite("MonthComparison")
struct MonthComparisonTests {
    @Test("spec example: 1240 vs 1000 is +$240 (+24%), an increase")
    func specIncrease() {
        let comparison = MonthComparison.compute(currentTotal: 1240, previousTotal: 1000)
        #expect(comparison.delta == 240)
        #expect(comparison.percentChange == 24)
        #expect(comparison.direction == .increase)
    }

    @Test("spending less than last month is a decrease with negative delta")
    func decrease() {
        let comparison = MonthComparison.compute(currentTotal: 750, previousTotal: 1000)
        #expect(comparison.delta == -250)
        #expect(comparison.percentChange == -25)
        #expect(comparison.direction == .decrease)
    }

    @Test("equal months are flat with 0%")
    func flat() {
        let comparison = MonthComparison.compute(currentTotal: 500, previousTotal: 500)
        #expect(comparison.delta == 0)
        #expect(comparison.percentChange == 0)
        #expect(comparison.direction == .flat)
    }

    @Test("nil previous month means no prior data: percent is nil")
    func noPriorMonth() {
        let comparison = MonthComparison.compute(currentTotal: 300, previousTotal: nil)
        #expect(comparison.percentChange == nil)
        #expect(comparison.direction == .flat)
    }

    @Test("zero previous month also has no defined percentage")
    func zeroPreviousMonth() {
        let comparison = MonthComparison.compute(currentTotal: 300, previousTotal: 0)
        #expect(comparison.percentChange == nil)
    }

    @Test("percent rounds half away from zero")
    func percentRounding() {
        // +125 on 1000 = +12.5% -> +13.
        #expect(MonthComparison.compute(currentTotal: 1125, previousTotal: 1000).percentChange == 13)
        // -125 on 1000 = -12.5% -> -13.
        #expect(MonthComparison.compute(currentTotal: 875, previousTotal: 1000).percentChange == -13)
        // +124 on 1000 = +12.4% -> +12.
        #expect(MonthComparison.compute(currentTotal: 1124, previousTotal: 1000).percentChange == 12)
    }

    @Test("headline copy for increase, decrease, and no baseline")
    func headlineCopy() {
        let up = MonthComparison.compute(currentTotal: 550, previousTotal: 500)
        #expect(up.headline == "+$50 (+10%) vs last month")
        let down = MonthComparison.compute(currentTotal: 450, previousTotal: 500)
        #expect(down.headline == "-$50 (-10%) vs last month")
        let none = MonthComparison.compute(currentTotal: 450, previousTotal: nil)
        #expect(none.headline == nil)
    }
}
