import Foundation
import SwiftData
import Testing
@testable import Spendthrift

@MainActor
struct QueryTests {
    @Test func labelStatsReflectSavedData() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let foodAndDrink = try #require(try store.category(named: "Food & Drink"))
        let health = try #require(try store.category(named: "Health"))

        try store.saveExpense(amountDollars: 4, label: "cafe", category: foodAndDrink, timestamp: FixedDate.d1)
        try store.saveExpense(amountDollars: 4, label: "Cafe", category: foodAndDrink, timestamp: FixedDate.d2)
        try store.saveExpense(amountDollars: 12, label: "electrolytes", category: health, timestamp: FixedDate.d1)

        let stats = try store.labelStats().sorted { $0.normalizedLabel < $1.normalizedLabel }
        #expect(stats.count == 2)

        let cafeStat = try #require(stats.first { $0.normalizedLabel == "cafe" })
        #expect(cafeStat.useCount == 2)
        #expect(cafeStat.label == "Cafe")
        #expect(cafeStat.lastUsedAt == FixedDate.d2)

        let electrolytesStat = try #require(stats.first { $0.normalizedLabel == "electrolytes" })
        #expect(electrolytesStat.useCount == 1)
        #expect(electrolytesStat.label == "electrolytes")
    }

    @Test func mappingPairsReflectSavedData() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let foodAndDrink = try #require(try store.category(named: "Food & Drink"))
        let health = try #require(try store.category(named: "Health"))

        try store.saveExpense(amountDollars: 4, label: "cafe", category: foodAndDrink, timestamp: FixedDate.d1)
        try store.saveExpense(amountDollars: 12, label: "electrolytes", category: health, timestamp: FixedDate.d1)

        let pairs = try store.mappingPairs().sorted { $0.normalizedLabel < $1.normalizedLabel }
        #expect(pairs.count == 2)
        #expect(pairs[0].normalizedLabel == "cafe")
        #expect(pairs[0].category == "Food & Drink")
        #expect(pairs[1].normalizedLabel == "electrolytes")
        #expect(pairs[1].category == "Health")
    }

    @Test func allExpensesReturnedReverseChronological() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let other = try #require(try store.category(named: "Other"))

        try store.saveExpense(amountDollars: 1, label: "first", category: other, timestamp: FixedDate.d1)
        try store.saveExpense(amountDollars: 2, label: "second", category: other, timestamp: FixedDate.d2)
        try store.saveExpense(amountDollars: 3, label: "third", category: other, timestamp: FixedDate.d3)

        let expenses = try store.allExpenses()
        #expect(expenses.map(\.label) == ["third", "second", "first"])
    }

    @Test func expensesInIntervalRespectsStartInclusiveEndExclusive() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let other = try #require(try store.category(named: "Other"))

        try store.saveExpense(amountDollars: 1, label: "d1 expense", category: other, timestamp: FixedDate.d1)
        try store.saveExpense(amountDollars: 2, label: "d2 expense", category: other, timestamp: FixedDate.d2)
        try store.saveExpense(amountDollars: 3, label: "d3 expense", category: other, timestamp: FixedDate.d3)

        // Interval [d1, d3): d1 included (start inclusive), d3 excluded (end exclusive).
        let interval = DateInterval(start: FixedDate.d1, end: FixedDate.d3)
        let inRange = try store.expenses(in: interval)

        #expect(inRange.map(\.label) == ["d2 expense", "d1 expense"])
    }
}
