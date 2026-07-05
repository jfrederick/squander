import Foundation
import SwiftData
import Testing
import SpendthriftCore
@testable import Spendthrift

@MainActor
struct SeedingTests {
    @Test func seedIfNeededCreatesExactlyTwelveCategories() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()

        let categories = try store.allCategories()
        #expect(categories.count == 12)

        let names = categories.map(\.name)
        let expectedNames = CategoryRules.seededCategories.map(\.name)
        #expect(names == expectedNames)
        #expect(names.first == "Food & Drink")
        #expect(names.last == "Other")
        #expect(categories.allSatisfy { $0.isSeeded })
    }

    @Test func seedIfNeededIsIdempotent() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        try store.seedIfNeeded()

        let categories = try store.allCategories()
        #expect(categories.count == 12)
    }
}
