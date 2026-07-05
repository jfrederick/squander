import Foundation
import SwiftData
import Testing
import SquanderCore
@testable import Squander

/// Store-level coverage of the write path `LogQuickExpenseIntent` performs
/// in the widget extension: look up the label's remembered category (falling
/// back to "Other"), then save through `ExpenseStore.saveExpense`. The
/// intent itself can't run under unit tests, so this exercises the exact
/// store calls it makes.
@MainActor
struct QuickLogWritePathTests {
    /// Mirrors LogQuickExpenseIntent.perform()'s category resolution.
    private func quickLog(_ store: ExpenseStore, label: String, amount: Int, at date: Date) throws -> Expense? {
        let category = try store.mapping(forNormalizedLabel: normalize(label))?.category
            ?? store.category(named: CategoryRules.fallbackCategoryName)
        guard let category else { return nil }
        return try store.saveExpense(amountDollars: amount, label: label, category: category, timestamp: date)
    }

    @Test func usesRememberedCategoryAndBumpsMapping() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let food = try #require(try store.category(named: "Food & Drink"))
        try store.saveExpense(amountDollars: 6, label: "cafe", category: food, timestamp: FixedDate.d1)

        let expense = try #require(try quickLog(store, label: "cafe", amount: 6, at: FixedDate.d2))

        #expect(expense.category?.name == "Food & Drink")
        #expect(expense.amountDollars == 6)
        let mapping = try #require(try store.mapping(forNormalizedLabel: "cafe"))
        #expect(mapping.useCount == 2)
        #expect(mapping.lastUsedAt == FixedDate.d2)
    }

    @Test func fallsBackToOtherWhenNoMappingExists() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()

        let expense = try #require(try quickLog(store, label: "mystery", amount: 9, at: FixedDate.d1))

        #expect(expense.category?.name == CategoryRules.fallbackCategoryName)
    }

    @Test func fallsBackToOtherWhenRememberedCategoryWasDeleted() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let shopping = try #require(try store.category(named: "Shopping"))
        let other = try #require(try store.category(named: "Other"))
        try store.saveExpense(amountDollars: 20, label: "shoes", category: shopping, timestamp: FixedDate.d1)

        // Deleting the category reassigns the mapping to the replacement,
        // so the quick log lands there — never on a dangling category.
        try store.deleteCategory(shopping, reassigningTo: other)

        let expense = try #require(try quickLog(store, label: "shoes", amount: 20, at: FixedDate.d2))
        #expect(expense.category?.name == "Other")
    }
}
