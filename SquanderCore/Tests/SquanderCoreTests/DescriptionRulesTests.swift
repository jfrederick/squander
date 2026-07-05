import Testing
@testable import SquanderCore

@Suite("DescriptionRules")
struct DescriptionRulesTests {
    @Test("clamp truncates to maxLength characters")
    func clampTruncates() {
        let raw = String(repeating: "a", count: 50)
        let clamped = DescriptionRules.clamp(raw)
        #expect(clamped.count == 40)
        #expect(clamped == String(repeating: "a", count: 40))
    }

    @Test("clamp leaves short strings unchanged")
    func clampLeavesShortUnchanged() {
        #expect(DescriptionRules.clamp("cafe") == "cafe")
    }

    @Test("clamp leaves exactly-40-character strings unchanged")
    func clampLeavesExactLengthUnchanged() {
        let raw = String(repeating: "b", count: 40)
        #expect(DescriptionRules.clamp(raw) == raw)
    }

    @Test("trimmedIfValid trims whitespace and newlines")
    func trimmedIfValidTrims() {
        #expect(DescriptionRules.trimmedIfValid("  cafe  ") == "cafe")
        #expect(DescriptionRules.trimmedIfValid("\ncafe\n") == "cafe")
    }

    @Test("trimmedIfValid returns nil for empty string")
    func trimmedIfValidNilForEmpty() {
        #expect(DescriptionRules.trimmedIfValid("") == nil)
    }

    @Test("trimmedIfValid returns nil for whitespace-only string")
    func trimmedIfValidNilForWhitespaceOnly() {
        #expect(DescriptionRules.trimmedIfValid("   ") == nil)
        #expect(DescriptionRules.trimmedIfValid("\n\t  \n") == nil)
    }

    @Test("trimmedIfValid result is guaranteed 1...40 characters")
    func trimmedIfValidResultBounded() {
        let raw = "  " + String(repeating: "c", count: 60) + "  "
        let result = DescriptionRules.trimmedIfValid(raw)
        #expect(result != nil)
        #expect(result!.count == 40)
    }

    @Test("maxLength constant is 40")
    func maxLengthConstant() {
        #expect(DescriptionRules.maxLength == 40)
    }
}
