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

    /// Voice descriptions are frequently novel, so unlike the widget's
    /// remembered-preset path this also consults the heuristic suggester
    /// before falling back to "Other".
    static func log(utterance: String, store: ExpenseStore, timestamp: Date = .now) throws -> Outcome {
        guard let spoken = SpokenExpenseParser.parse(utterance) else { return .unparseable }

        let normalized = normalize(spoken.label)
        var category = try store.mapping(forNormalizedLabel: normalized)?.category
        if category == nil,
           let suggested = CategorySuggester.suggest(normalizedLabel: normalized, mappings: try store.mappingPairs()) {
            category = try store.category(named: suggested)
        }
        guard let category = try category ?? store.category(named: CategoryRules.fallbackCategoryName) else {
            return .unparseable
        }

        try store.saveExpense(amountDollars: spoken.amountDollars, label: spoken.label, category: category, timestamp: timestamp)
        return .logged(amountDollars: spoken.amountDollars, label: spoken.label, categoryName: category.name)
    }
}
