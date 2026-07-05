import Testing
@testable import SpendthriftCore

@Suite("normalize")
struct NormalizeTests {
    @Test("trims whitespace, casefolds, and strips diacritics")
    func trimCaseDiacritics() {
        #expect(normalize("Café ") == "cafe")
    }

    @Test("trims newlines")
    func trimsNewlines() {
        #expect(normalize("\ncafe\n") == "cafe")
    }

    @Test("case-insensitive matching")
    func caseInsensitive() {
        #expect(normalize("Mexican") == normalize("mexican"))
    }

    @Test("idempotent on already-normalized string")
    func idempotent() {
        #expect(normalize("cafe") == "cafe")
    }

    @Test("empty and whitespace-only strings normalize to empty")
    func emptyAndWhitespace() {
        #expect(normalize("").isEmpty)
        #expect(normalize("   \n\t  ").isEmpty)
    }
}
