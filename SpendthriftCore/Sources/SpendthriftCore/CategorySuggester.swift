import Foundation

/// Suggests a category for a new (never-remembered) description using
/// on-device heuristics: token overlap / prefix similarity against
/// remembered description->category mappings, falling back to a keyword table.
public enum CategorySuggester {
    /// Default keyword -> category table used when no mapping-based match is found.
    /// Keys are lowercase, single-token keywords.
    public static let defaultKeywordTable: [String: String] = [
        "taco": "Food & Drink",
        "tacos": "Food & Drink",
        "coffee": "Food & Drink",
        "latte": "Food & Drink",
        "espresso": "Food & Drink",
        "restaurant": "Food & Drink",
        "pizza": "Food & Drink",
        "burger": "Food & Drink",
        "bar": "Food & Drink",
        "brewery": "Food & Drink",
        "diner": "Food & Drink",
        "sushi": "Food & Drink",
        "grocery": "Groceries",
        "groceries": "Groceries",
        "supermarket": "Groceries",
        "market": "Groceries",
        "uber": "Transport",
        "lyft": "Transport",
        "taxi": "Transport",
        "gas": "Transport",
        "fuel": "Transport",
        "parking": "Transport",
        "transit": "Transport",
        "train": "Transport",
        "bus": "Transport",
        "tolls": "Transport",
        "amazon": "Shopping",
        "clothes": "Shopping",
        "clothing": "Shopping",
        "shoes": "Shopping",
        "mall": "Shopping",
        "movie": "Entertainment",
        "movies": "Entertainment",
        "cinema": "Entertainment",
        "concert": "Entertainment",
        "games": "Entertainment",
        "gaming": "Entertainment",
        "gym": "Health",
        "pharmacy": "Health",
        "doctor": "Health",
        "dentist": "Health",
        "medicine": "Health",
        "vitamins": "Health",
        "electrolytes": "Health",
        "rent": "Home",
        "utilities": "Home",
        "furniture": "Home",
        "hotel": "Travel",
        "flight": "Travel",
        "airbnb": "Travel",
        "airline": "Travel",
        "netflix": "Subscriptions",
        "spotify": "Subscriptions",
        "subscription": "Subscriptions",
        "gift": "Gifts",
        "gifts": "Gifts",
        "haircut": "Personal Care",
        "salon": "Personal Care",
        "spa": "Personal Care"
    ]

    /// Resolution order:
    /// 1. Token-overlap / prefix similarity against `mappings`.
    /// 2. Keyword table scan (deterministic, sorted key order).
    /// 3. `nil` if nothing matches confidently.
    public static func suggest(
        normalizedLabel: String,
        mappings: [(normalizedLabel: String, category: String)],
        keywordTable: [String: String] = CategorySuggester.defaultKeywordTable
    ) -> String? {
        if let category = suggestFromMappings(normalizedLabel: normalizedLabel, mappings: mappings) {
            return category
        }
        return suggestFromKeywordTable(normalizedLabel: normalizedLabel, keywordTable: keywordTable)
    }

    private static func tokens(of s: String) -> [String] {
        s.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    }

    private static func suggestFromMappings(
        normalizedLabel: String,
        mappings: [(normalizedLabel: String, category: String)]
    ) -> String? {
        guard !mappings.isEmpty else { return nil }

        let inputTokens = Set(tokens(of: normalizedLabel))

        struct Candidate {
            let mappingLabel: String
            let category: String
            let sharedTokenCount: Int
            let commonPrefixLength: Int
        }

        var candidates: [Candidate] = []

        for mapping in mappings {
            let mappingTokens = Set(tokens(of: mapping.normalizedLabel))
            let sharedTokens = inputTokens.intersection(mappingTokens)
            let isPrefixRelated = mapping.normalizedLabel.hasPrefix(normalizedLabel)
                || normalizedLabel.hasPrefix(mapping.normalizedLabel)

            guard !sharedTokens.isEmpty || isPrefixRelated else { continue }

            let commonPrefixLength = commonPrefixCount(normalizedLabel, mapping.normalizedLabel)

            candidates.append(
                Candidate(
                    mappingLabel: mapping.normalizedLabel,
                    category: mapping.category,
                    sharedTokenCount: sharedTokens.count,
                    commonPrefixLength: commonPrefixLength
                )
            )
        }

        guard !candidates.isEmpty else { return nil }

        let best = candidates.sorted { a, b in
            if a.sharedTokenCount != b.sharedTokenCount { return a.sharedTokenCount > b.sharedTokenCount }
            if a.commonPrefixLength != b.commonPrefixLength { return a.commonPrefixLength > b.commonPrefixLength }
            return a.mappingLabel < b.mappingLabel
        }.first

        return best?.category
    }

    private static func commonPrefixCount(_ a: String, _ b: String) -> Int {
        var count = 0
        for (charA, charB) in zip(a, b) {
            if charA == charB {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    private static func suggestFromKeywordTable(
        normalizedLabel: String,
        keywordTable: [String: String]
    ) -> String? {
        let inputTokens = Set(tokens(of: normalizedLabel))
        let sortedKeys = keywordTable.keys.sorted()

        for keyword in sortedKeys {
            if inputTokens.contains(keyword) || normalizedLabel.contains(keyword) {
                return keywordTable[keyword]
            }
        }
        return nil
    }
}
