import Testing
import Foundation
@testable import SquanderCore

@Suite("Autocomplete")
struct AutocompleteTests {
    static func date(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let d = formatter.date(from: iso) else {
            fatalError("bad date \(iso)")
        }
        return d
    }

    @Test("prefix match suggests past description")
    func prefixMatch() {
        let stats = [
            LabelStat(label: "cafe", normalizedLabel: "cafe", useCount: 1, lastUsedAt: Self.date("2026-01-01T00:00:00Z"))
        ]
        let results = Autocomplete.suggestions(for: "ca", from: stats)
        #expect(results.map { $0.label } == ["cafe"])
    }

    @Test("case-insensitive matching: Mexican matches mex")
    func caseInsensitiveMatching() {
        let stats = [
            LabelStat(label: "Mexican", normalizedLabel: normalize("Mexican"), useCount: 1, lastUsedAt: Self.date("2026-01-01T00:00:00Z"))
        ]
        let results = Autocomplete.suggestions(for: "mex", from: stats)
        #expect(results.map { $0.label } == ["Mexican"])
    }

    @Test("substring match ranks below prefix match: electrolytes/espresso with query e")
    func substringRanksBelowPrefix() {
        let stats = [
            LabelStat(label: "electrolytes", normalizedLabel: "electrolytes", useCount: 1, lastUsedAt: Self.date("2026-01-01T00:00:00Z")),
            LabelStat(label: "espresso", normalizedLabel: "espresso", useCount: 1, lastUsedAt: Self.date("2026-01-01T00:00:00Z"))
        ]
        let results = Autocomplete.suggestions(for: "e", from: stats)
        // both should appear
        #expect(Set(results.map { $0.label }) == Set(["electrolytes", "espresso"]))
        // "espresso" is a prefix match (starts with "e" trivially - both do).
        // Use a query that differentiates prefix vs substring instead.
    }

    @Test("prefix vs substring-only ordering with a differentiating query")
    func prefixVsSubstringDifferentiating() {
        // "latte" is a prefix match for "la"; "chai latte" only contains "la" as substring.
        let stats = [
            LabelStat(label: "chai latte", normalizedLabel: "chai latte", useCount: 1, lastUsedAt: Self.date("2026-01-01T00:00:00Z")),
            LabelStat(label: "latte", normalizedLabel: "latte", useCount: 1, lastUsedAt: Self.date("2026-01-01T00:00:00Z"))
        ]
        let results = Autocomplete.suggestions(for: "la", from: stats)
        #expect(results.map { $0.label } == ["latte", "chai latte"])
    }

    @Test("no matches shows no suggestions")
    func noMatches() {
        let stats = [
            LabelStat(label: "cafe", normalizedLabel: "cafe", useCount: 1, lastUsedAt: Self.date("2026-01-01T00:00:00Z"))
        ]
        let results = Autocomplete.suggestions(for: "zzz", from: stats)
        #expect(results.isEmpty)
    }

    @Test("empty query returns no suggestions")
    func emptyQuery() {
        let stats = [
            LabelStat(label: "cafe", normalizedLabel: "cafe", useCount: 1, lastUsedAt: Self.date("2026-01-01T00:00:00Z"))
        ]
        #expect(Autocomplete.suggestions(for: "", from: stats).isEmpty)
        #expect(Autocomplete.suggestions(for: "   ", from: stats).isEmpty)
    }

    @Test("frequent description ranks first: cafe 20x vs carwash 2x")
    func frequencyRanking() {
        let stats = [
            LabelStat(label: "carwash", normalizedLabel: "carwash", useCount: 2, lastUsedAt: Self.date("2026-01-01T00:00:00Z")),
            LabelStat(label: "cafe", normalizedLabel: "cafe", useCount: 20, lastUsedAt: Self.date("2026-01-01T00:00:00Z"))
        ]
        let results = Autocomplete.suggestions(for: "ca", from: stats)
        #expect(results.map { $0.label } == ["cafe", "carwash"])
    }

    @Test("at most five suggestions returned")
    func topFiveLimit() {
        let stats = (0..<8).map { i in
            LabelStat(
                label: "cab\(i)",
                normalizedLabel: "cab\(i)",
                useCount: 8 - i,
                lastUsedAt: Self.date("2026-01-01T00:00:00Z")
            )
        }
        let results = Autocomplete.suggestions(for: "ca", from: stats)
        #expect(results.count == 5)
        #expect(results.map { $0.label } == ["cab0", "cab1", "cab2", "cab3", "cab4"])
    }

    @Test("custom limit is respected")
    func customLimit() {
        let stats = (0..<8).map { i in
            LabelStat(
                label: "cab\(i)",
                normalizedLabel: "cab\(i)",
                useCount: 8 - i,
                lastUsedAt: Self.date("2026-01-01T00:00:00Z")
            )
        }
        let results = Autocomplete.suggestions(for: "ca", from: stats, limit: 3)
        #expect(results.count == 3)
    }

    @Test("duplicates collapsed by normalizedLabel")
    func duplicatesCollapsed() {
        let stats = [
            LabelStat(label: "cafe", normalizedLabel: "cafe", useCount: 5, lastUsedAt: Self.date("2026-01-01T00:00:00Z")),
            LabelStat(label: "cafe", normalizedLabel: "cafe", useCount: 5, lastUsedAt: Self.date("2026-01-02T00:00:00Z")),
            LabelStat(label: "cafe", normalizedLabel: "cafe", useCount: 5, lastUsedAt: Self.date("2026-01-03T00:00:00Z"))
        ]
        let results = Autocomplete.suggestions(for: "caf", from: stats)
        #expect(results.count == 1)
        #expect(results.first?.label == "cafe")
    }

    @Test("ties broken by lastUsedAt descending, then label ascending")
    func tieBreaking() {
        let stats = [
            LabelStat(label: "cab", normalizedLabel: "cab", useCount: 3, lastUsedAt: Self.date("2026-01-01T00:00:00Z")),
            LabelStat(label: "cafe", normalizedLabel: "cafe", useCount: 3, lastUsedAt: Self.date("2026-01-02T00:00:00Z")),
            LabelStat(label: "car", normalizedLabel: "car", useCount: 3, lastUsedAt: Self.date("2026-01-02T00:00:00Z"))
        ]
        let results = Autocomplete.suggestions(for: "ca", from: stats)
        // cafe and car tie on useCount and lastUsedAt -> alphabetical
        #expect(results.map { $0.label } == ["cafe", "car", "cab"])
    }
}
