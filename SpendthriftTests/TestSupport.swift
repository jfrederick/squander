import Foundation
import SwiftData
@testable import Spendthrift

/// Shared helpers for building a fresh, isolated in-memory SwiftData stack
/// per test, per design D8 ("SwiftData tested against in-memory ModelContainer").
@MainActor
enum TestSupport {
    /// A brand-new in-memory container with the current schema/migration plan.
    static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Schema(versionedSchema: SpendthriftSchemaV1.self),
            migrationPlan: SpendthriftMigrationPlan.self,
            configurations: [config]
        )
    }

    /// A fresh container plus a store already backed by a fresh context.
    static func makeStore() throws -> (container: ModelContainer, store: ExpenseStore) {
        let container = try makeContainer()
        let store = ExpenseStore(context: ModelContext(container))
        return (container, store)
    }

    /// A second, independent store on the *same* container/persistent
    /// storage, simulating a relaunch (new ModelContext, same data).
    static func relaunchedStore(on container: ModelContainer) -> ExpenseStore {
        ExpenseStore(context: ModelContext(container))
    }
}

/// Fixed dates so time-dependent assertions are deterministic.
enum FixedDate {
    /// 2024-01-15 12:00:00 UTC
    static let d1 = Date(timeIntervalSince1970: 1_705_320_000)
    /// 2024-01-16 12:00:00 UTC (one day after d1)
    static let d2 = Date(timeIntervalSince1970: 1_705_406_400)
    /// 2024-01-17 12:00:00 UTC (one day after d2)
    static let d3 = Date(timeIntervalSince1970: 1_705_492_800)
}
