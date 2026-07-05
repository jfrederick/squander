import Testing
import Foundation
@testable import SpendthriftCore

@Suite("CategoryBreakdown")
struct CategoryBreakdownTests {
    @Test("spec example: 300/150/50 ranks descending with 60/30/10 shares")
    func specExample() {
        let shares = CategoryBreakdown.compute(expenses: [
            (amount: 150, category: "Transport"),
            (amount: 100, category: "Food & Drink"),
            (amount: 50, category: "Health"),
            (amount: 200, category: "Food & Drink")
        ])
        #expect(shares == [
            CategoryShare(category: "Food & Drink", total: 300, share: 60),
            CategoryShare(category: "Transport", total: 150, share: 30),
            CategoryShare(category: "Health", total: 50, share: 10)
        ])
    }

    @Test("shares round half up to whole percents")
    func roundingHalfUp() {
        // 1/3 splits: 33.33% -> 33, 66.67% -> 67.
        let thirds = CategoryBreakdown.compute(expenses: [
            (amount: 2, category: "A"),
            (amount: 1, category: "B")
        ])
        #expect(thirds.map { $0.share } == [67, 33])

        // Exact half: 12.5% rounds up to 13.
        let eighths = CategoryBreakdown.compute(expenses: [
            (amount: 7, category: "A"),
            (amount: 1, category: "B")
        ])
        #expect(eighths.map { $0.share } == [88, 13])
    }

    @Test("empty input yields empty breakdown")
    func emptyInput() {
        #expect(CategoryBreakdown.compute(expenses: []).isEmpty)
    }

    @Test("zero-total categories are omitted")
    func zeroTotalsOmitted() {
        let shares = CategoryBreakdown.compute(expenses: [
            (amount: 0, category: "Nothing"),
            (amount: 25, category: "Food & Drink")
        ])
        #expect(shares == [CategoryShare(category: "Food & Drink", total: 25, share: 100)])
    }

    @Test("ties in total break alphabetically for a stable ranking")
    func tieBreaking() {
        let shares = CategoryBreakdown.compute(expenses: [
            (amount: 10, category: "Transport"),
            (amount: 10, category: "Food & Drink")
        ])
        #expect(shares.map { $0.category } == ["Food & Drink", "Transport"])
        #expect(shares.map { $0.share } == [50, 50])
    }

    @Test("single category takes 100%")
    func singleCategory() {
        let shares = CategoryBreakdown.compute(expenses: [(amount: 42, category: "Other")])
        #expect(shares == [CategoryShare(category: "Other", total: 42, share: 100)])
    }
}
