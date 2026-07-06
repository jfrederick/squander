import Foundation
import SwiftData
import SpendthriftCore

/// The voice entry write path, factored out of the App Intent so unit tests
/// exercise the real code (parse -> resolve category -> save), not a mirror.
@MainActor
enum SpokenExpenseLogger {
    enum Outcome: Equatable {
        /// Saved. Payload feeds the spoken confirmation.
        case logged(amountDollars: Int, label: String, categoryName: String)
        /// Nothing written: no amount, no description, or out-of-range amount.
        case unparseable
    }

    /// Voice descriptions are frequently novel, so this path consults the
    /// heuristic suggester (consultSuggester: true), unlike the widget's
    /// remembered-preset quick log.
    static func log(utterance: String, store: ExpenseStore, timestamp: Date = .now) throws -> Outcome {
        guard let spoken = SpokenExpenseParser.parse(utterance),
              let label = DescriptionRules.trimmedIfValid(spoken.label),
              let category = try store.resolveCategory(forLabel: label, consultSuggester: true)
        else { return .unparseable }

        try store.saveExpense(amountDollars: spoken.amountDollars, label: label, category: category, timestamp: timestamp)
        return .logged(amountDollars: spoken.amountDollars, label: label, categoryName: category.name)
    }
}
