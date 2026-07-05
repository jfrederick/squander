import SwiftUI
import SwiftData

@main
struct SpendthriftApp: App {
    let modelContainer: ModelContainer
    let store: ExpenseStore

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let isUITestMode = arguments.contains("-UITestMode")
        let shouldSeedUITestData = arguments.contains("-UITestSeedData")

        let schema = Schema(versionedSchema: SpendthriftSchemaV1.self)
        let configuration = ModelConfiguration(isStoredInMemoryOnly: isUITestMode)

        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: schema,
                migrationPlan: SpendthriftMigrationPlan.self,
                configurations: [configuration]
            )
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

        self.store = store
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.expenseStore, store)
        }
        .modelContainer(modelContainer)
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
