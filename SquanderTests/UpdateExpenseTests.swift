import Foundation
import SwiftData
import Testing
@testable import Squander

@MainActor
struct UpdateExpenseTests {
    @Test func updateExpensePreservesTimestampAndUpdatesFields() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let foodAndDrink = try #require(try store.category(named: "Food & Drink"))
        let shopping = try #require(try store.category(named: "Shopping"))

        let expense = try store.saveExpense(amountDollars: 10, label: "cafe", category: foodAndDrink, timestamp: FixedDate.d1)

        try store.updateExpense(expense, amountDollars: 15, label: "Cafe Latte", category: shopping)

        #expect(expense.timestamp == FixedDate.d1)
        #expect(expense.amountDollars == 15)
        #expect(expense.label == "Cafe Latte")
        #expect(expense.normalizedLabel == "cafe latte")
        #expect(expense.category?.name == "Shopping")
    }

    /// Spec: "Memory updates on correction" — editing "cafe" from Food & Drink
    /// to Entertainment updates the mapping for future expenses, but past
    /// "cafe" expenses already saved keep their existing category.
    @Test func updateExpenseMemoryUpdatesOnCorrectionPastExpensesUnaffected() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let foodAndDrink = try #require(try store.category(named: "Food & Drink"))
        let entertainment = try #require(try store.category(named: "Entertainment"))

        // Two separate past "cafe" expenses, both auto-categorized Food & Drink.
        let firstCafeExpense = try store.saveExpense(amountDollars: 4, label: "cafe", category: foodAndDrink, timestamp: FixedDate.d1)
        let secondCafeExpense = try store.saveExpense(amountDollars: 5, label: "cafe", category: foodAndDrink, timestamp: FixedDate.d2)

        // User edits the second expense, correcting its category.
        try store.updateExpense(secondCafeExpense, amountDollars: 5, label: "cafe", category: entertainment)

        // The mapping now points to Entertainment for future "cafe" expenses.
        let mapping = try #require(try store.mapping(forNormalizedLabel: "cafe"))
        #expect(mapping.category?.name == "Entertainment")

        // The edited expense reflects the new category.
        #expect(secondCafeExpense.category?.name == "Entertainment")

        // The earlier, untouched "cafe" expense keeps its original category.
        #expect(firstCafeExpense.category?.name == "Food & Drink")

        // A brand-new "cafe" expense saved afterward picks up the corrected mapping.
        let thirdCafeExpense = try store.saveExpense(amountDollars: 6, label: "cafe", category: entertainment, timestamp: FixedDate.d3)
        #expect(thirdCafeExpense.category?.name == "Entertainment")
    }

    @Test func amountOnlyEditDoesNotBumpMappingRanking() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let food = try #require(try store.category(named: "Food & Drink"))
        let expense = try store.saveExpense(amountDollars: 12, label: "cafe", category: food, timestamp: FixedDate.d1)
        let before = try #require(try store.mapping(forNormalizedLabel: "cafe"))
        #expect(before.useCount == 1)
        let beforeUsedAt = before.lastUsedAt

        try store.updateExpense(expense, amountDollars: 21, label: "cafe", category: food)

        let after = try #require(try store.mapping(forNormalizedLabel: "cafe"))
        #expect(after.useCount == 1)
        #expect(after.lastUsedAt == beforeUsedAt)
        #expect(expense.amountDollars == 21)
    }
}
