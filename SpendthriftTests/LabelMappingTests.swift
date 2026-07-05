import Foundation
import SwiftData
import Testing
import SpendthriftCore
@testable import Spendthrift

@MainActor
struct LabelMappingTests {
    @Test func recordMappingUpsertBumpsUseCountAndUpdatesRecencyAndCasing() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let foodAndDrink = try #require(try store.category(named: "Food & Drink"))
        let shopping = try #require(try store.category(named: "Shopping"))

        try store.saveExpense(amountDollars: 5, label: "cafe", category: foodAndDrink, timestamp: FixedDate.d1)
        try store.saveExpense(amountDollars: 6, label: "Cafe", category: shopping, timestamp: FixedDate.d2)

        let mapping = try #require(try store.mapping(forNormalizedLabel: "cafe"))
        #expect(mapping.useCount == 2)
        #expect(mapping.lastUsedAt == FixedDate.d2)
        #expect(mapping.displayLabel == "Cafe")
        #expect(mapping.category?.name == "Shopping")
    }

    @Test func mappingLookupHitsAfterSave() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let health = try #require(try store.category(named: "Health"))

        try store.saveExpense(amountDollars: 12, label: "electrolytes", category: health, timestamp: FixedDate.d1)

        let mapping = try #require(try store.mapping(forNormalizedLabel: "electrolytes"))
        #expect(mapping.category?.name == "Health")
    }

    @Test func normalizationAppliesToMappingLookup() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let foodAndDrink = try #require(try store.category(named: "Food & Drink"))

        try store.saveExpense(amountDollars: 4, label: "Cafe", category: foodAndDrink, timestamp: FixedDate.d1)

        // "cafe " (trailing space, different case) should normalize to the same key.
        let mapping = try #require(try store.mapping(forNormalizedLabel: normalize("cafe ")))
        #expect(mapping.category?.name == "Food & Drink")
    }

    @Test func mappingMissForUnknownLabel() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()

        let mapping = try store.mapping(forNormalizedLabel: "never seen before")
        #expect(mapping == nil)
    }
}
