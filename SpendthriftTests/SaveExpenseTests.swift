import Foundation
import SwiftData
import Testing
import SpendthriftCore
@testable import Spendthrift

@MainActor
struct SaveExpenseTests {
    @Test func saveExpensePersistsFieldsAndCreatesMapping() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let foodAndDrink = try #require(try store.category(named: "Food & Drink"))

        let expense = try store.saveExpense(
            amountDollars: 42,
            label: "Mexican",
            category: foodAndDrink,
            timestamp: FixedDate.d1
        )

        #expect(expense.amountDollars == 42)
        #expect(expense.label == "Mexican")
        #expect(expense.normalizedLabel == normalize("Mexican"))
        #expect(expense.normalizedLabel == "mexican")
        #expect(expense.timestamp == FixedDate.d1)
        #expect(expense.category?.name == "Food & Drink")

        let mapping = try #require(try store.mapping(forNormalizedLabel: "mexican"))
        #expect(mapping.useCount == 1)
        #expect(mapping.displayLabel == "Mexican")
        #expect(mapping.category?.name == "Food & Drink")
        #expect(mapping.lastUsedAt == FixedDate.d1)
    }

    @Test func saveExpenseTrimsWhitespaceFromLabel() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let other = try #require(try store.category(named: "Other"))

        let expense = try store.saveExpense(
            amountDollars: 10,
            label: "  Coffee  ",
            category: other,
            timestamp: FixedDate.d1
        )

        #expect(expense.label == "Coffee")
        #expect(expense.normalizedLabel == "coffee")
    }
}
