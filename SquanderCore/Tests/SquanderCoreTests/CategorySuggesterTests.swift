import Testing
@testable import SquanderCore

@Suite("CategorySuggester")
struct CategorySuggesterTests {
    @Test("token overlap picks the mapping sharing a whole token")
    func tokenOverlap() {
        let mappings: [(normalizedLabel: String, category: String)] = [
            (normalizedLabel: "cafe", category: "Food & Drink"),
            (normalizedLabel: "carwash", category: "Transport")
        ]
        let result = CategorySuggester.suggest(normalizedLabel: "cafe downtown", mappings: mappings)
        #expect(result == "Food & Drink")
    }

    @Test("prefix similarity: cafe latte matches cafe mapping")
    func prefixSimilarity() {
        let mappings: [(normalizedLabel: String, category: String)] = [
            (normalizedLabel: "cafe", category: "Food & Drink")
        ]
        let result = CategorySuggester.suggest(normalizedLabel: "cafe latte", mappings: mappings)
        #expect(result == "Food & Drink")
    }

    @Test("prefix similarity works in reverse: short input, longer mapping")
    func prefixSimilarityReverse() {
        let mappings: [(normalizedLabel: String, category: String)] = [
            (normalizedLabel: "cafe latte", category: "Food & Drink")
        ]
        let result = CategorySuggester.suggest(normalizedLabel: "cafe", mappings: mappings)
        #expect(result == "Food & Drink")
    }

    @Test("most shared tokens wins over fewer shared tokens")
    func mostSharedTokensWins() {
        let mappings: [(normalizedLabel: String, category: String)] = [
            (normalizedLabel: "corner cafe", category: "Food & Drink"),
            (normalizedLabel: "cafe", category: "Entertainment")
        ]
        // "corner cafe downtown" shares 2 tokens with "corner cafe" vs 1 with "cafe"
        let result = CategorySuggester.suggest(normalizedLabel: "corner cafe downtown", mappings: mappings)
        #expect(result == "Food & Drink")
    }

    @Test("ties broken by longer common prefix")
    func tiesBrokenByCommonPrefix() {
        let mappings: [(normalizedLabel: String, category: String)] = [
            (normalizedLabel: "cab service", category: "Transport"),
            (normalizedLabel: "cafe service", category: "Food & Drink")
        ]
        // input shares 1 token ("service") with both; "cafe" has longer common prefix with "cafe stop" than "cab"
        let result = CategorySuggester.suggest(normalizedLabel: "cafe stop service", mappings: mappings)
        #expect(result == "Food & Drink")
    }

    @Test("ties broken alphabetically by mapping label as final tiebreaker")
    func tiesBrokenAlphabetically() {
        let mappings: [(normalizedLabel: String, category: String)] = [
            (normalizedLabel: "zzz stuff", category: "Shopping"),
            (normalizedLabel: "aaa stuff", category: "Entertainment")
        ]
        let result = CategorySuggester.suggest(normalizedLabel: "stuff", mappings: mappings)
        #expect(result == "Entertainment")
    }

    @Test("keyword table hit: tacos maps to Food & Drink")
    func keywordTableHit() {
        let result = CategorySuggester.suggest(normalizedLabel: "tacos", mappings: [])
        #expect(result == "Food & Drink")
    }

    @Test("keyword table hit within a longer description")
    func keywordTableHitWithinLongerDescription() {
        let result = CategorySuggester.suggest(normalizedLabel: "uber to airport", mappings: [])
        #expect(result == "Transport")
    }

    @Test("mapping-based match takes precedence over keyword table")
    func mappingPrecedenceOverKeyword() {
        let mappings: [(normalizedLabel: String, category: String)] = [
            (normalizedLabel: "tacos", category: "Entertainment")
        ]
        let result = CategorySuggester.suggest(normalizedLabel: "tacos", mappings: mappings)
        #expect(result == "Entertainment")
    }

    @Test("no confident match returns nil")
    func noConfidentMatchReturnsNil() {
        let result = CategorySuggester.suggest(normalizedLabel: "xyzzy plugh", mappings: [])
        #expect(result == nil)
    }

    @Test("no confident match with unrelated mappings returns nil")
    func noMatchWithUnrelatedMappings() {
        let mappings: [(normalizedLabel: String, category: String)] = [
            (normalizedLabel: "cafe", category: "Food & Drink")
        ]
        let result = CategorySuggester.suggest(normalizedLabel: "xyzzy plugh", mappings: mappings)
        #expect(result == nil)
    }

    @Test("defaultKeywordTable contains expected sample entries")
    func defaultKeywordTableSampleEntries() {
        #expect(CategorySuggester.defaultKeywordTable["taco"] == "Food & Drink")
        #expect(CategorySuggester.defaultKeywordTable["coffee"] == "Food & Drink")
        #expect(CategorySuggester.defaultKeywordTable["uber"] == "Transport")
        #expect(CategorySuggester.defaultKeywordTable["gas"] == "Transport")
        #expect(CategorySuggester.defaultKeywordTable["netflix"] == "Subscriptions")
        #expect(CategorySuggester.defaultKeywordTable["gym"] == "Health")
        #expect(CategorySuggester.defaultKeywordTable["pharmacy"] == "Health")
        #expect(CategorySuggester.defaultKeywordTable["hotel"] == "Travel")
        #expect(CategorySuggester.defaultKeywordTable["flight"] == "Travel")
        #expect(CategorySuggester.defaultKeywordTable["haircut"] == "Personal Care")
    }

    @Test("defaultKeywordTable has at least 40 entries")
    func defaultKeywordTableSize() {
        #expect(CategorySuggester.defaultKeywordTable.count >= 40)
    }

    @Test("keyword lookup is deterministic regardless of dictionary ordering")
    func keywordLookupDeterministic() {
        // "gas" and "gift" both could be substrings in pathological inputs;
        // ensure a plain, unambiguous case resolves consistently across runs.
        let resultsAreConsistent = (0..<5).map { _ in
            CategorySuggester.suggest(normalizedLabel: "gas station", mappings: [])
        }
        #expect(resultsAreConsistent.allSatisfy { $0 == "Transport" })
    }
}
