import Foundation

/// One category's slice of a period's spending.
public struct CategoryShare: Equatable, Sendable {
    public let category: String
    /// Whole-dollar total for the category.
    public let total: Int
    /// Whole-percent share of the grand total, rounded half up
    /// (e.g. 300/150/50 of 500 -> 60/30/10).
    public let share: Int

    public init(category: String, total: Int, share: Int) {
        self.category = category
        self.total = total
        self.share = share
    }
}

/// Computes per-category totals and percentage shares for a set of expenses
/// (typically one calendar month's worth).
public enum CategoryBreakdown {
    /// Groups amounts by category name, ranked by total descending (ties
    /// broken alphabetically for determinism). Categories that end up with a
    /// zero total are omitted, as is everything when there are no expenses.
    ///
    /// Shares are integer percentages of the grand total, rounded half up
    /// using pure integer math: `(total * 200 + grand) / (2 * grand)`.
    public static func compute(expenses: [(amount: Int, category: String)]) -> [CategoryShare] {
        var totalsByCategory: [String: Int] = [:]
        for expense in expenses {
            totalsByCategory[expense.category, default: 0] += expense.amount
        }

        let grandTotal = totalsByCategory.values.reduce(0, +)
        guard grandTotal > 0 else { return [] }

        return totalsByCategory
            .filter { $0.value > 0 }
            .sorted { a, b in
                if a.value != b.value { return a.value > b.value }
                return a.key < b.key
            }
            .map { category, total in
                CategoryShare(
                    category: category,
                    total: total,
                    share: (total * 200 + grandTotal) / (2 * grandTotal)
                )
            }
    }
}
