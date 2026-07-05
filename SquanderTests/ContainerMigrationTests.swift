import Foundation
import Testing
@testable import Squander

/// `SquanderContainer.migrateIfNeeded` — the one-time copy of the legacy
/// default store into the App Group container. Pure file work, exercised
/// against temp directories.
struct ContainerMigrationTests {
    /// A fresh temp dir with fake "old" and "new" store locations.
    private func makeTempStoreURLs() throws -> (root: URL, old: URL, new: URL) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("squander-migration-\(UUID().uuidString)")
        let oldDir = root.appendingPathComponent("old")
        let newDir = root.appendingPathComponent("new")
        try FileManager.default.createDirectory(at: oldDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: newDir, withIntermediateDirectories: true)
        return (
            root,
            oldDir.appendingPathComponent("default.store"),
            newDir.appendingPathComponent("Squander.store")
        )
    }

    private func write(_ content: String, to url: URL) throws {
        try content.data(using: .utf8)!.write(to: url)
    }

    @Test func copiesStoreAndSidecarsToNewLocation() throws {
        let (root, old, new) = try makeTempStoreURLs()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("store", to: old)
        try write("wal", to: URL(fileURLWithPath: old.path + "-wal"))
        try write("shm", to: URL(fileURLWithPath: old.path + "-shm"))

        try SquanderContainer.migrateIfNeeded(from: old, to: new)

        #expect(try String(contentsOf: new, encoding: .utf8) == "store")
        #expect(try String(contentsOf: URL(fileURLWithPath: new.path + "-wal"), encoding: .utf8) == "wal")
        #expect(try String(contentsOf: URL(fileURLWithPath: new.path + "-shm"), encoding: .utf8) == "shm")
        // The old files are left in place (copy, not move).
        #expect(FileManager.default.fileExists(atPath: old.path))
    }

    @Test func missingSidecarsAreIgnored() throws {
        let (root, old, new) = try makeTempStoreURLs()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("store", to: old)

        try SquanderContainer.migrateIfNeeded(from: old, to: new)

        #expect(try String(contentsOf: new, encoding: .utf8) == "store")
        #expect(!FileManager.default.fileExists(atPath: new.path + "-wal"))
        #expect(!FileManager.default.fileExists(atPath: new.path + "-shm"))
    }

    @Test func doesNotOverwriteAnExistingNewStore() throws {
        let (root, old, new) = try makeTempStoreURLs()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("legacy", to: old)
        try write("current", to: new)

        try SquanderContainer.migrateIfNeeded(from: old, to: new)

        // Migration is one-time: an existing group store is never clobbered.
        #expect(try String(contentsOf: new, encoding: .utf8) == "current")
    }

    @Test func noopWhenNoLegacyStoreExists() throws {
        let (root, old, new) = try makeTempStoreURLs()
        defer { try? FileManager.default.removeItem(at: root) }

        try SquanderContainer.migrateIfNeeded(from: old, to: new)

        #expect(!FileManager.default.fileExists(atPath: new.path))
    }
}
