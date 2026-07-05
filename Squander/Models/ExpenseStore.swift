import Foundation
import SwiftData
import SquanderCore

/// The single write path to the model layer. All mutations, uniqueness
/// checks, and mapping upkeep go through here so the rules live in one
/// place (design D2/D6).
@MainActor
final class ExpenseStore {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Seeding

    /// Inserts the 12 default categories on first launch (no categories exist).
    func seedIfNeeded() throws {
        let count = try context.fetchCount(FetchDescriptor<Category>())
        guard count == 0 else { return }
        for seed in CategoryRules.seededCategories {
            context.insert(Category(name: seed.name, colorName: seed.colorName, iconName: seed.iconName, isSeeded: true))
        }
        try context.save()
    }

    // MARK: - Categories

    /// Seeded categories first in their canonical order, then user-created ones alphabetically.
    func allCategories() throws -> [Category] {
        let all = try context.fetch(FetchDescriptor<Category>())
        let seededOrder = Dictionary(uniqueKeysWithValues: CategoryRules.seededCategories.enumerated().map { ($1.name, $0) })
        return all.sorted { a, b in
            switch (seededOrder[a.name], seededOrder[b.name]) {
            case let (i?, j?): return i < j
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        }
    }

    enum CategoryCreationError: Error, Equatable {
        case capReached
        case duplicateName
        case invalidName
    }

    @discardableResult
    func createCategory(named rawName: String) throws -> Category {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw CategoryCreationError.invalidName }
        let existing = try context.fetch(FetchDescriptor<Category>())
        guard CategoryRules.canCreate(existingCount: existing.count) else {
            throw CategoryCreationError.capReached
        }
        guard !CategoryRules.isDuplicateName(name, existing: existing.map(\.name)) else {
            throw CategoryCreationError.duplicateName
        }
        let category = Category(name: name, colorName: "gray", iconName: "tag.fill", isSeeded: false)
        context.insert(category)
        try context.save()
        return category
    }

    /// Deleting a category requires reassigning its expenses (referential
    /// integrity). Label mappings follow to the replacement as well.
    func deleteCategory(_ category: Category, reassigningTo replacement: Category) throws {
        guard category !== replacement else { return }
        for expense in category.expenses ?? [] {
            expense.category = replacement
        }
        for mapping in category.mappings ?? [] {
            mapping.category = replacement
        }
        context.delete(category)
        try context.save()
    }

    // MARK: - Label mappings

    func mapping(forNormalizedLabel key: String) throws -> LabelMapping? {
        var descriptor = FetchDescriptor<LabelMapping>(predicate: #Predicate { $0.normalizedLabel == key })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Upserts the description→category memory: bumps use count and recency,
    /// refreshes display casing, and repoints the category.
    func recordMapping(label: String, category: Category, at date: Date) throws {
        let key = normalize(label)
        guard !key.isEmpty else { return }
        if let existing = try mapping(forNormalizedLabel: key) {
            existing.useCount += 1
            existing.lastUsedAt = date
            existing.displayLabel = label
            existing.category = category
        } else {
            context.insert(LabelMapping(normalizedLabel: key, displayLabel: label, category: category, lastUsedAt: date))
        }
        try context.save()
    }

    /// Autocomplete input: the pre-deduplicated, pre-ranked mapping table.
    func labelStats() throws -> [LabelStat] {
        try context.fetch(FetchDescriptor<LabelMapping>()).map {
            LabelStat(label: $0.displayLabel, normalizedLabel: $0.normalizedLabel, useCount: $0.useCount, lastUsedAt: $0.lastUsedAt)
        }
    }

    /// (normalizedLabel, categoryName) pairs for the category suggester.
    func mappingPairs() throws -> [(normalizedLabel: String, category: String)] {
        try context.fetch(FetchDescriptor<LabelMapping>()).compactMap { m in
            guard let name = m.category?.name else { return nil }
            return (m.normalizedLabel, name)
        }
    }

    // MARK: - Expenses

    /// Persists an expense and records/updates the label mapping.
    @discardableResult
    func saveExpense(amountDollars: Int, label: String, category: Category, timestamp: Date = .now) throws -> Expense {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let expense = Expense(
            amountDollars: amountDollars,
            label: trimmed,
            normalizedLabel: normalize(trimmed),
            timestamp: timestamp,
            category: category
        )
        context.insert(expense)
        try context.save()
        try recordMapping(label: trimmed, category: category, at: timestamp)
        return expense
    }

    func allExpenses() throws -> [Expense] {
        try context.fetch(FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)]))
    }

    func expenses(in interval: DateInterval) throws -> [Expense] {
        let start = interval.start
        let end = interval.end
        return try context.fetch(FetchDescriptor<Expense>(
            predicate: #Predicate { $0.timestamp >= start && $0.timestamp < end },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        ))
    }

    /// Edits preserve the original timestamp (spec). A category or label
    /// change updates the mapping for *future* expenses; past expenses are
    /// untouched.
    func updateExpense(_ expense: Expense, amountDollars: Int, label: String, category: Category) throws {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        expense.amountDollars = amountDollars
        expense.label = trimmed
        expense.normalizedLabel = normalize(trimmed)
        expense.category = category
        try context.save()
        try recordMapping(label: trimmed, category: category, at: .now)
    }

    /// Everything needed to undo a delete.
    struct DeletedExpenseSnapshot {
        let amountDollars: Int
        let label: String
        let categoryName: String
        let timestamp: Date
    }

    func deleteExpense(_ expense: Expense) throws -> DeletedExpenseSnapshot {
        let snapshot = DeletedExpenseSnapshot(
            amountDollars: expense.amountDollars,
            label: expense.label,
            categoryName: expense.category?.name ?? CategoryRules.fallbackCategoryName,
            timestamp: expense.timestamp
        )
        context.delete(expense)
        try context.save()
        return snapshot
    }

    /// Restores a deleted expense with its original fields. If its category
    /// disappeared in the meantime, falls back to "Other".
    @discardableResult
    func restoreExpense(_ snapshot: DeletedExpenseSnapshot) throws -> Expense {
        let category = try category(named: snapshot.categoryName)
            ?? category(named: CategoryRules.fallbackCategoryName)
        guard let category else {
            throw CategoryCreationError.invalidName
        }
        let expense = Expense(
            amountDollars: snapshot.amountDollars,
            label: snapshot.label,
            normalizedLabel: normalize(snapshot.label),
            timestamp: snapshot.timestamp,
            category: category
        )
        context.insert(expense)
        try context.save()
        return expense
    }

    func category(named name: String) throws -> Category? {
        var descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.name == name })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
