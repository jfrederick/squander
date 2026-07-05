import Foundation
import SwiftData

/// Schema v1 per design D2: three entities, Int whole-dollar amounts,
/// normalized label keys, UTC-instant timestamps.
enum SpendthriftSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Expense.self, Category.self, LabelMapping.self]
    }

    @Model
    final class Expense {
        var amountDollars: Int
        /// Description exactly as the user saved it (original casing).
        var label: String
        /// normalize(label) — the matching key. Kept in sync by ExpenseStore.
        var normalizedLabel: String
        /// UTC instant; displayed in the device's current calendar/time zone.
        var timestamp: Date
        var category: Category?

        init(amountDollars: Int, label: String, normalizedLabel: String, timestamp: Date, category: Category) {
            self.amountDollars = amountDollars
            self.label = label
            self.normalizedLabel = normalizedLabel
            self.timestamp = timestamp
            self.category = category
        }
    }

    @Model
    final class Category {
        @Attribute(.unique) var name: String
        var colorName: String
        var iconName: String
        var isSeeded: Bool
        @Relationship(deleteRule: .deny, inverse: \Expense.category)
        var expenses: [Expense]? = []
        @Relationship(deleteRule: .cascade, inverse: \LabelMapping.category)
        var mappings: [LabelMapping]? = []

        init(name: String, colorName: String, iconName: String, isSeeded: Bool = false) {
            self.name = name
            self.colorName = colorName
            self.iconName = iconName
            self.isSeeded = isSeeded
        }
    }

    @Model
    final class LabelMapping {
        @Attribute(.unique) var normalizedLabel: String
        /// Most recently saved original casing, so autocomplete can fill
        /// the field "exactly as originally saved".
        var displayLabel: String
        var useCount: Int
        var lastUsedAt: Date
        var category: Category?

        init(normalizedLabel: String, displayLabel: String, category: Category, useCount: Int = 1, lastUsedAt: Date) {
            self.normalizedLabel = normalizedLabel
            self.displayLabel = displayLabel
            self.category = category
            self.useCount = useCount
            self.lastUsedAt = lastUsedAt
        }
    }
}

typealias Expense = SpendthriftSchemaV1.Expense
typealias Category = SpendthriftSchemaV1.Category
typealias LabelMapping = SpendthriftSchemaV1.LabelMapping

enum SpendthriftMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SpendthriftSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
