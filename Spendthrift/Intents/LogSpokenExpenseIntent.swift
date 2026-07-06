import AppIntents
import Foundation
import SwiftData
import WidgetKit
import SpendthriftCore

/// Hands-free logging: Siri passes the dictated utterance ("six dollar
/// coffee"), parsing and the save happen here without opening the app, and
/// the reply dialog echoes what was logged so mistakes are audible.
struct LogSpokenExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Spoken Expense"
    static let description = IntentDescription(
        "Logs an expense from a spoken phrase like \u{201C}six dollar coffee\u{201D} or \u{201C}$14 lunch\u{201D}."
    )
    static let openAppWhenRun = false

    @Parameter(title: "Spending", requestValueDialog: "What did you spend?")
    var utterance: String

    init() {}

    init(utterance: String) {
        self.utterance = utterance
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try SpendthriftContainer.makeContainer()
        let store = ExpenseStore(context: container.mainContext)
        try store.seedIfNeeded()

        switch try SpokenExpenseLogger.log(utterance: utterance, store: store) {
        case let .logged(amountDollars, label, categoryName):
            WidgetCenter.shared.reloadAllTimelines()
            return .result(dialog: "Logged $\(amountDollars) for \(label) in \(categoryName).")
        case .unparseable:
            return .result(dialog: "I couldn\u{2019}t find an amount and description in \u{201C}\(utterance)\u{201D}. Try something like \u{201C}six dollar coffee\u{201D}.")
        }
    }
}

/// Registers the Siri phrases at install time — no user setup needed.
/// Phrases must be static (String parameters can't appear in App Shortcut
/// phrases — only AppEnum/AppEntity can), so Siri always asks the one
/// follow-up question and the utterance carries the variability.
struct SpendthriftShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogSpokenExpenseIntent(),
            phrases: [
                "Log an expense in \(.applicationName)",
                "Add an expense in \(.applicationName)",
                "Log spending in \(.applicationName)",
            ],
            shortTitle: "Log Expense",
            systemImageName: "mic.fill"
        )
    }
}
