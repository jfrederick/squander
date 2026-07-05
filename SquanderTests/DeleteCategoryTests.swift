import Foundation
import SwiftData
import Testing
@testable import Squander

@MainActor
struct DeleteCategoryTests {
    @Test func deleteCategoryReassignsExpensesAndMappingsAndRemovesCategory() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let shopping = try #require(try store.category(named: "Shopping"))
        let other = try #require(try store.category(named: "Other"))

        try store.saveExpense(amountDollars: 20, label: "shoes", category: shopping, timestamp: FixedDate.d1)
        try store.saveExpense(amountDollars: 30, label: "jacket", category: shopping, timestamp: FixedDate.d2)

        try store.deleteCategory(shopping, reassigningTo: other)

        let categories = try store.allCategories()
        #expect(categories.map(\.name).contains("Shopping") == false)
        #expect(categories.count == 11)

        let expenses = try store.allExpenses()
        #expect(expenses.allSatisfy { $0.category?.name == "Other" })

        let shoesMapping = try #require(try store.mapping(forNormalizedLabel: "shoes"))
        #expect(shoesMapping.category?.name == "Other")
        let jacketMapping = try #require(try store.mapping(forNormalizedLabel: "jacket"))
        #expect(jacketMapping.category?.name == "Other")
    }
}
