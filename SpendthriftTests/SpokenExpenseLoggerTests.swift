import Foundation
import SwiftData
import Testing
import SpendthriftCore
@testable import Spendthrift

/// Store-level coverage of the voice write path. Unlike the widget's
/// quick-log tests this calls the real `SpokenExpenseLogger.log` — the same
/// function `LogSpokenExpenseIntent.perform()` runs.
@MainActor
struct SpokenExpenseLoggerTests {
    @Test func rememberedMappingWins() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let travel = try #require(try store.category(named: "Travel"))
        try store.saveExpense(amountDollars: 9, label: "coffee", category: travel, timestamp: FixedDate.d1)

        let outcome = try SpokenExpenseLogger.log(utterance: "six dollar coffee", store: store, timestamp: FixedDate.d2)

        #expect(outcome == .logged(amountDollars: 6, label: "coffee", categoryName: "Travel"))
        let expenses = try store.allExpenses()
        #expect(expenses.count == 2)
        #expect(expenses.first?.amountDollars == 6)
        #expect(expenses.first?.category?.name == "Travel")
    }

    @Test func novelDescriptionUsesSuggester() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()

        let outcome = try SpokenExpenseLogger.log(utterance: "spent 12 on parking", store: store, timestamp: FixedDate.d1)

        #expect(outcome == .logged(amountDollars: 12, label: "parking", categoryName: "Transport"))
        #expect(try store.allExpenses().first?.category?.name == "Transport")
    }

    @Test func unknownDescriptionFallsBackToOther() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()

        let outcome = try SpokenExpenseLogger.log(utterance: "$8 zzyzx", store: store, timestamp: FixedDate.d1)

        #expect(outcome == .logged(amountDollars: 8, label: "zzyzx", categoryName: "Other"))
    }

    @Test func voiceLogRecordsMappingForFutureEntries() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()

        _ = try SpokenExpenseLogger.log(utterance: "12 dollars parking", store: store, timestamp: FixedDate.d1)

        let mapping = try store.mapping(forNormalizedLabel: "parking")
        #expect(mapping?.category?.name == "Transport")
    }

    @Test func unparseableWritesNothing() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()

        let outcome = try SpokenExpenseLogger.log(utterance: "coffee at the corner shop", store: store, timestamp: FixedDate.d1)

        #expect(outcome == .unparseable)
        #expect(try store.allExpenses().isEmpty)
    }

    @Test func outOfRangeAmountWritesNothing() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()

        let outcome = try SpokenExpenseLogger.log(utterance: "$100000 car", store: store, timestamp: FixedDate.d1)

        #expect(outcome == .unparseable)
        #expect(try store.allExpenses().isEmpty)
    }
}
