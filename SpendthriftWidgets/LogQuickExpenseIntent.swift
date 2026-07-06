import AppIntents
import Foundation
import SwiftData
import WidgetKit
import SpendthriftCore

/// One-tap quick log from the widget: saves the preset expense directly in
/// the extension process (no app launch) using the same ExpenseStore write
/// path as in-app entry, then refreshes widget timelines.
struct LogQuickExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Expense"
    static let description = IntentDescription("Logs an expense with a remembered description and amount.")
    static let openAppWhenRun = false

    @Parameter(title: "Description")
    var label: String

    @Parameter(title: "Amount")
    var amount: Int

    init() {}

    init(label: String, amount: Int) {
        self.label = label
        self.amount = amount
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // Same whole-dollar validity range as in-app keypad entry.
        guard amount >= 1, amount <= AmountEntryState.maxAmount else {
            return .result()
        }

        let container = try SpendthriftContainer.makeContainer()
        let store = ExpenseStore(context: container.mainContext)
        try store.seedIfNeeded()

        // The description's remembered category; "Other" if it's gone.
        // Presets are remembered by construction, so no suggester here.
        guard let category = try store.resolveCategory(forLabel: label, consultSuggester: false) else {
            return .result()
        }

        try store.saveExpense(amountDollars: amount, label: label, category: category)

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
