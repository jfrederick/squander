import Foundation
import SwiftData
import SpendthriftCore

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

    enum CategoryDeletionError: Error, Equatable {
        /// "Other" is the guaranteed fallback for restores and suggestions
        /// and must always exist.
        case cannotDeleteFallback
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
        guard normalize(category.name) != normalize(CategoryRules.fallbackCategoryName) else {
            throw CategoryDeletionError.cannotDeleteFallback
        }
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
        upsertMapping(label: label, category: category, at: date)
        try context.save()
    }

    /// Same upsert without the save, so the capture path can flush the
    /// expense insert and the mapping change in a single save.
    private func upsertMapping(label: String, category: Category, at date: Date) {
        let key = normalize(label)
        guard !key.isEmpty else { return }
        if let existing = try? mapping(forNormalizedLabel: key) {
            existing.useCount += 1
            existing.lastUsedAt = date
            existing.displayLabel = label
            existing.category = category
        } else {
            context.insert(LabelMapping(normalizedLabel: key, displayLabel: label, category: category, lastUsedAt: date))
        }
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
        upsertMapping(label: trimmed, category: category, at: timestamp)
        try context.save()
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
        let normalized = normalize(trimmed)
        // Only a label or category correction is a mapping event; an
        // amount-only (or no-op) edit must not inflate the label's
        // autocomplete frequency/recency ranking.
        let mappingChanged = normalized != expense.normalizedLabel || category !== expense.category
        expense.amountDollars = amountDollars
        expense.label = trimmed
        expense.normalizedLabel = normalized
        expense.category = category
        if mappingChanged {
            upsertMapping(label: trimmed, category: category, at: .now)
        }
        try context.save()
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

    /// The one category-resolution policy for non-interactive entry paths
    /// (widget quick-log, voice): remembered mapping first, optionally the
    /// heuristic suggester (for paths where novel descriptions are common),
    /// then the guaranteed "Other" fallback. Nil only if "Other" is missing,
    /// which seeding rules out.
    func resolveCategory(forLabel label: String, consultSuggester: Bool) throws -> Category? {
        let normalized = normalize(label)
        if let remembered = try mapping(forNormalizedLabel: normalized)?.category {
            return remembered
        }
        if consultSuggester,
           let suggestedName = CategorySuggester.suggest(normalizedLabel: normalized, mappings: try mappingPairs()),
           let suggested = try category(named: suggestedName) {
            return suggested
        }
        return try category(named: CategoryRules.fallbackCategoryName)
    }
}
