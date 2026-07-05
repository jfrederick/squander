import Foundation

/// A statistical record for a previously used expense description label.
public struct LabelStat: Equatable, Sendable {
    /// Original casing for display.
    public let label: String
    public let normalizedLabel: String
    public let useCount: Int
    public let lastUsedAt: Date

    public init(label: String, normalizedLabel: String, useCount: Int, lastUsedAt: Date) {
        self.label = label
        self.normalizedLabel = normalizedLabel
        self.useCount = useCount
        self.lastUsedAt = lastUsedAt
    }
}

/// Provides description autocomplete suggestions from past-usage statistics.
public enum Autocomplete {
    /// Returns up to `limit` suggestions from `stats` matching `query`.
    ///
    /// The query is normalized before matching. An empty (or whitespace-only)
    /// query yields no suggestions. Prefix matches on `normalizedLabel` rank
    /// strictly before substring-only matches; within each tier, results are
    /// sorted by `useCount` descending, then `lastUsedAt` descending, then
    /// `label` ascending. Results are deduped by `normalizedLabel`.
    public static func suggestions(for query: String, from stats: [LabelStat], limit: Int = 5) -> [LabelStat] {
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else { return [] }

        // Dedupe by normalizedLabel, keeping the "best" entry per label
        // (highest useCount, then most recent lastUsedAt).
        var bestByLabel: [String: LabelStat] = [:]
        for stat in stats {
            guard stat.normalizedLabel.contains(normalizedQuery) else { continue }
            if let existing = bestByLabel[stat.normalizedLabel] {
                if isBetter(stat, than: existing) {
                    bestByLabel[stat.normalizedLabel] = stat
                }
            } else {
                bestByLabel[stat.normalizedLabel] = stat
            }
        }

        let prefixMatches = bestByLabel.values.filter { $0.normalizedLabel.hasPrefix(normalizedQuery) }
        let substringOnlyMatches = bestByLabel.values.filter { !$0.normalizedLabel.hasPrefix(normalizedQuery) }

        let sortedPrefix = prefixMatches.sorted(by: rankedBefore)
        let sortedSubstring = substringOnlyMatches.sorted(by: rankedBefore)

        let combined = sortedPrefix + sortedSubstring
        return Array(combined.prefix(limit))
    }

    private static func isBetter(_ a: LabelStat, than b: LabelStat) -> Bool {
        if a.useCount != b.useCount { return a.useCount > b.useCount }
        return a.lastUsedAt > b.lastUsedAt
    }

    private static func rankedBefore(_ a: LabelStat, _ b: LabelStat) -> Bool {
        if a.useCount != b.useCount { return a.useCount > b.useCount }
        if a.lastUsedAt != b.lastUsedAt { return a.lastUsedAt > b.lastUsedAt }
        return a.label < b.label
    }
}
