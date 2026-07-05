import Foundation
import SwiftData
import Testing
@testable import Spendthrift

/// Covers "data-persistence" spec: "Data survives restart" — save, then
/// reopen with a brand-new ModelContext on the same container to simulate
/// a force-quit + relaunch.
@MainActor
struct PersistenceRoundTripTests {
    @Test func dataSurvivesRelaunch() throws {
        let container = try TestSupport.makeContainer()
        let store = ExpenseStore(context: ModelContext(container))
        try store.seedIfNeeded()
        let groceries = try #require(try store.category(named: "Groceries"))
        try store.saveExpense(amountDollars: 87, label: "Weekly shop", category: groceries, timestamp: FixedDate.d1)

        // Simulate relaunch: fresh ModelContext, same container/storage.
        let relaunched = TestSupport.relaunchedStore(on: container)

        let categories = try relaunched.allCategories()
        #expect(categories.count == 12)

        let expenses = try relaunched.allExpenses()
        #expect(expenses.count == 1)
        let expense = try #require(expenses.first)
        #expect(expense.amountDollars == 87)
        #expect(expense.label == "Weekly shop")
        #expect(expense.normalizedLabel == "weekly shop")
        #expect(expense.timestamp == FixedDate.d1)
        #expect(expense.category?.name == "Groceries")

        let mapping = try #require(try relaunched.mapping(forNormalizedLabel: "weekly shop"))
        #expect(mapping.useCount == 1)
        #expect(mapping.category?.name == "Groceries")
    }
}
