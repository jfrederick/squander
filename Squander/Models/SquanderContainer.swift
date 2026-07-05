import Foundation
import SwiftData

/// Builds the ModelContainer shared by the app and the widget extension.
///
/// The store lives in the App Group container so the widget's timeline
/// provider and `LogQuickExpenseIntent` can read/write the same data. This
/// file is compiled into both targets.
enum SquanderContainer {
    static let appGroupID = "group.dev.jimfrederick.squander"
    static let storeFileName = "Squander.store"

    /// The pre-App-Group store location (SwiftData's default), used only to
    /// migrate existing data on first launch of the updated app.
    static var legacyStoreURL: URL {
        URL.applicationSupportDirectory.appending(path: "default.store")
    }

    /// Creates the shared container. Pass `inMemory: true` for UI-test mode.
    ///
    /// If the App Group container is unavailable (missing entitlement, e.g.
    /// plain unit-test hosts), falls back to the default store location
    /// rather than crashing.
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SquanderSchemaV1.self)

        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        } else if let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            let storeURL = groupURL.appendingPathComponent(storeFileName)
            try migrateIfNeeded(from: legacyStoreURL, to: storeURL)
            configuration = ModelConfiguration(url: storeURL)
        } else {
            configuration = ModelConfiguration()
        }

        return try ModelContainer(
            for: schema,
            migrationPlan: SquanderMigrationPlan.self,
            configurations: [configuration]
        )
    }

    /// One-time store migration: if no store exists at `newStoreURL` but one
    /// exists at `oldStoreURL`, copies the store file plus its `-wal`/`-shm`
    /// siblings (individually optional) before the container is created.
    ///
    /// Pure file work, parameterized on URLs and FileManager so tests can
    /// exercise it against temp directories.
    static func migrateIfNeeded(
        from oldStoreURL: URL,
        to newStoreURL: URL,
        fileManager: FileManager = .default
    ) throws {
        guard !fileManager.fileExists(atPath: newStoreURL.path),
              fileManager.fileExists(atPath: oldStoreURL.path) else {
            return
        }
        try fileManager.copyItem(at: oldStoreURL, to: newStoreURL)
        for suffix in ["-wal", "-shm"] {
            let oldSidecar = URL(fileURLWithPath: oldStoreURL.path + suffix)
            let newSidecar = URL(fileURLWithPath: newStoreURL.path + suffix)
            if fileManager.fileExists(atPath: oldSidecar.path),
               !fileManager.fileExists(atPath: newSidecar.path) {
                try fileManager.copyItem(at: oldSidecar, to: newSidecar)
            }
        }
    }
}
