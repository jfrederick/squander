import Foundation

/// A one-tap quick-log button: a remembered description paired with its
/// most common whole-dollar amount.
public struct QuickLogPreset: Equatable, Sendable {
    /// Display casing of the label (from the most recent expense).
    public let label: String
    /// Whole dollars, matching the app-wide Int amount convention.
    public let amount: Int

    public init(label: String, amount: Int) {
        self.label = label
        self.amount = amount
    }
}

/// Derives the widget's quick-log presets from expense history.
public enum QuickLogPresets {
    /// Returns up to `limit` presets.
    ///
    /// Rules (spec `widget-quick-entry`):
    /// - Expenses are grouped by `normalizedLabel`; a label qualifies only
    ///   once it has at least two saved expenses.
    /// - Labels rank by expense count descending, ties broken by most
    ///   recent expense descending, then label ascending.
    /// - Each preset's amount is the label's most frequent amount, ties
    ///   broken by the amount used most recently (then lowest amount, for
    ///   determinism).
    /// - The preset's display label is the most recent expense's casing.
    public static func compute(
        expenses: [(normalizedLabel: String, label: String, amount: Int, timestamp: Date)],
        limit: Int = 4
    ) -> [QuickLogPreset] {
        guard limit > 0 else { return [] }

        let groups = Dictionary(grouping: expenses, by: \.normalizedLabel)

        struct Candidate {
            let count: Int
            let mostRecent: Date
            let label: String
            let amount: Int
        }

        let candidates: [Candidate] = groups.values.compactMap { group in
            guard group.count >= 2 else { return nil }
            // Most recent expense supplies the display casing.
            let newest = group.max { a, b in a.timestamp < b.timestamp }!
            return Candidate(
                count: group.count,
                mostRecent: newest.timestamp,
                label: newest.label,
                amount: modalAmount(of: group)
            )
        }

        let ranked = candidates.sorted { a, b in
            if a.count != b.count { return a.count > b.count }
            if a.mostRecent != b.mostRecent { return a.mostRecent > b.mostRecent }
            return a.label < b.label
        }

        return ranked.prefix(limit).map { QuickLogPreset(label: $0.label, amount: $0.amount) }
    }

    /// The most frequent amount in `group`; ties broken by most recent use,
    /// then by lowest amount so the result is fully deterministic.
    private static func modalAmount(
        of group: [(normalizedLabel: String, label: String, amount: Int, timestamp: Date)]
    ) -> Int {
        struct AmountStat {
            var count = 0
            var lastUsedAt = Date.distantPast
        }
        var stats: [Int: AmountStat] = [:]
        for expense in group {
            var stat = stats[expense.amount, default: AmountStat()]
            stat.count += 1
            stat.lastUsedAt = max(stat.lastUsedAt, expense.timestamp)
            stats[expense.amount] = stat
        }
        return stats.min { a, b in
            if a.value.count != b.value.count { return a.value.count > b.value.count }
            if a.value.lastUsedAt != b.value.lastUsedAt { return a.value.lastUsedAt > b.value.lastUsedAt }
            return a.key < b.key
        }!.key
    }
}
