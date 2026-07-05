import Foundation
import SwiftData
import Testing
import SpendthriftCore
@testable import Spendthrift

@MainActor
struct DeleteRestoreExpenseTests {
    @Test func deleteExpenseReturnsAccurateSnapshot() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let health = try #require(try store.category(named: "Health"))

        let expense = try store.saveExpense(amountDollars: 12, label: "electrolytes", category: health, timestamp: FixedDate.d1)
        let snapshot = try store.deleteExpense(expense)

        #expect(snapshot.amountDollars == 12)
        #expect(snapshot.label == "electrolytes")
        #expect(snapshot.categoryName == "Health")
        #expect(snapshot.timestamp == FixedDate.d1)

        let remaining = try store.allExpenses()
        #expect(remaining.isEmpty)
    }

    @Test func restoreExpenseRestoresExactFields() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let health = try #require(try store.category(named: "Health"))

        let expense = try store.saveExpense(amountDollars: 12, label: "electrolytes", category: health, timestamp: FixedDate.d1)
        let snapshot = try store.deleteExpense(expense)

        let restored = try store.restoreExpense(snapshot)

        #expect(restored.amountDollars == 12)
        #expect(restored.label == "electrolytes")
        #expect(restored.normalizedLabel == "electrolytes")
        #expect(restored.category?.name == "Health")
        #expect(restored.timestamp == FixedDate.d1)

        let all = try store.allExpenses()
        #expect(all.count == 1)
    }

    @Test func restoreExpenseFallsBackToOtherWhenOriginalCategoryDeleted() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let travel = try #require(try store.category(named: "Travel"))
        let other = try #require(try store.category(named: "Other"))

        let expense = try store.saveExpense(amountDollars: 200, label: "flight", category: travel, timestamp: FixedDate.d1)
        let snapshot = try store.deleteExpense(expense)

        // The category itself disappears in the meantime (reassigned away, then deleted).
        try store.deleteCategory(travel, reassigningTo: other)

        let restored = try store.restoreExpense(snapshot)

        #expect(restored.category?.name == CategoryRules.fallbackCategoryName)
        #expect(restored.amountDollars == 200)
        #expect(restored.label == "flight")
        #expect(restored.timestamp == FixedDate.d1)
    }
}
