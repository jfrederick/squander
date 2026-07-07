import SwiftUI
import SwiftData
import WidgetKit

@main
struct SpendthriftApp: App {
    @Environment(\.scenePhase) private var scenePhase

    let modelContainer: ModelContainer
    let store: ExpenseStore

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let isUITestMode = arguments.contains("-UITestMode")
        let shouldSeedUITestData = arguments.contains("-UITestSeedData")

        let container: ModelContainer
        do {
            container = try SpendthriftContainer.makeContainer(inMemory: isUITestMode)
        } catch {
            fatalError("Spendthrift failed to create its ModelContainer: \(error)")
        }

        self.modelContainer = container
        let context = container.mainContext
        let store = ExpenseStore(context: context)

        do {
            try store.seedIfNeeded()
        } catch {
            fatalError("Spendthrift failed to seed default categories: \(error)")
        }

        if shouldSeedUITestData {
            do {
                try Self.seedUITestData(into: store)
            } catch {
                fatalError("Spendthrift failed to seed UI test data: \(error)")
            }
        }

        store.onExpensesMutated = { store in
            DigestScheduler.refresh(store: store)
            // The widget shows live day/month/year totals plus a green/red
            // spent-today outline; without this, in-app logging leaves the
            // widget asserting "no spending today" until midnight (the
            // widget/Siri intents reload from their own processes).
            WidgetCenter.shared.reloadAllTimelines()
        }
        self.store = store
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.expenseStore, store)
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, phase in
            // Foreground is a "fresh data" moment: widget-extension writes
            // since the last launch get folded into the pending digest here.
            if phase == .active {
                DigestScheduler.refresh(store: store)
            }
        }
    }

    /// Inserts a small, fixed dataset (today/yesterday/last month) so UI
    /// tests can make deterministic assertions about totals.
    private static func seedUITestData(into store: ExpenseStore) throws {
        guard let foodCategory = try store.category(named: "Food & Drink"),
              let transportCategory = try store.category(named: "Transport") else {
            return
        }

        let calendar = Calendar.current
        let now = Date.now
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now

        try store.saveExpense(amountDollars: 20, label: "seed today", category: foodCategory, timestamp: now)
        // A second today category so the list's category filter is testable;
        // slightly earlier keeps "seed today" the newest, clamped to the
        // start of day so a just-after-midnight launch stays "today".
        let earlierToday = max(now.addingTimeInterval(-1), calendar.startOfDay(for: now))
        try store.saveExpense(amountDollars: 5, label: "seed today transport", category: transportCategory, timestamp: earlierToday)
        try store.saveExpense(amountDollars: 10, label: "seed yesterday", category: transportCategory, timestamp: yesterday)
        try store.saveExpense(amountDollars: 30, label: "seed last month", category: foodCategory, timestamp: lastMonth)
    }
}

/// Injects the shared ExpenseStore through the SwiftUI environment.
private struct ExpenseStoreKey: EnvironmentKey {
    static let defaultValue: ExpenseStore? = nil
}

extension EnvironmentValues {
    var expenseStore: ExpenseStore? {
        get { self[ExpenseStoreKey.self] }
        set { self[ExpenseStoreKey.self] = newValue }
    }
}
