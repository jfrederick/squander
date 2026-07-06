import Testing
@testable import SpendthriftCore

@Suite("SpokenExpenseParser")
struct SpokenExpenseParserTests {
    // MARK: - Digit amounts

    @Test("dollar-sign digit amount first")
    func dollarSignDigitFirst() {
        let result = SpokenExpenseParser.parse("$6 coffee")
        #expect(result?.amountDollars == 6)
        #expect(result?.label == "coffee")
    }

    @Test("bare digit amount first")
    func bareDigitFirst() {
        let result = SpokenExpenseParser.parse("6 coffee")
        #expect(result?.amountDollars == 6)
        #expect(result?.label == "coffee")
    }

    @Test("digit amount last")
    func digitLast() {
        let result = SpokenExpenseParser.parse("coffee $6")
        #expect(result?.amountDollars == 6)
        #expect(result?.label == "coffee")
    }

    @Test("digit amount with currency word")
    func digitWithCurrencyWord() {
        let result = SpokenExpenseParser.parse("14 dollars lunch")
        #expect(result?.amountDollars == 14)
        #expect(result?.label == "lunch")
    }

    // MARK: - Number words

    @Test("single number word with singular currency word")
    func wordAmountSingularCurrency() {
        let result = SpokenExpenseParser.parse("six dollar coffee")
        #expect(result?.amountDollars == 6)
        #expect(result?.label == "coffee")
    }

    @Test("bucks with connective")
    func bucksWithConnective() {
        let result = SpokenExpenseParser.parse("six bucks for coffee")
        #expect(result?.amountDollars == 6)
        #expect(result?.label == "coffee")
    }

    @Test("description first, word amount last")
    func descriptionFirstWordAmount() {
        let result = SpokenExpenseParser.parse("coffee six dollars")
        #expect(result?.amountDollars == 6)
        #expect(result?.label == "coffee")
    }

    @Test("hyphenated compound tens")
    func hyphenatedCompound() {
        let result = SpokenExpenseParser.parse("twenty-five dollars parking")
        #expect(result?.amountDollars == 25)
        #expect(result?.label == "parking")
    }

    @Test("compound tens without hyphen")
    func plainCompound() {
        let result = SpokenExpenseParser.parse("twenty five dollars parking")
        #expect(result?.amountDollars == 25)
        #expect(result?.label == "parking")
    }

    @Test("a hundred and ten")
    func aHundredAndTen() {
        let result = SpokenExpenseParser.parse("a hundred and ten groceries")
        #expect(result?.amountDollars == 110)
        #expect(result?.label == "groceries")
    }

    @Test("one thousand two hundred")
    func thousandCompound() {
        let result = SpokenExpenseParser.parse("one thousand two hundred rent")
        #expect(result?.amountDollars == 1200)
        #expect(result?.label == "rent")
    }

    @Test("teen amount")
    func teenAmount() {
        let result = SpokenExpenseParser.parse("fifteen dollars for gas")
        #expect(result?.amountDollars == 15)
        #expect(result?.label == "gas")
    }

    // MARK: - Command filler

    @Test("leading log filler stripped")
    func logFiller() {
        let result = SpokenExpenseParser.parse("log six dollar coffee")
        #expect(result?.amountDollars == 6)
        #expect(result?.label == "coffee")
    }

    @Test("leading spent filler with on connective")
    func spentFiller() {
        let result = SpokenExpenseParser.parse("spent 14 on lunch")
        #expect(result?.amountDollars == 14)
        #expect(result?.label == "lunch")
    }

    @Test("leading add filler")
    func addFiller() {
        let result = SpokenExpenseParser.parse("add twenty bucks for parking")
        #expect(result?.amountDollars == 20)
        #expect(result?.label == "parking")
    }

    // MARK: - Casing and whitespace

    @Test("mixed case and extra whitespace")
    func mixedCase() {
        let result = SpokenExpenseParser.parse("  Six Dollar   Coffee ")
        #expect(result?.amountDollars == 6)
        #expect(result?.label == "coffee")
    }

    // MARK: - Amount binds to currency word

    @Test("number words in description, amount adjacent to currency word")
    func numberWordsInDescription() {
        let result = SpokenExpenseParser.parse("five guys twelve dollars")
        #expect(result?.amountDollars == 12)
        #expect(result?.label == "five guys")
    }

    @Test("bare numbers only: first number wins, rest is description")
    func firstBareNumberWins() {
        let result = SpokenExpenseParser.parse("seven eleven")
        #expect(result?.amountDollars == 7)
        #expect(result?.label == "eleven")
    }

    // MARK: - Rejections

    @Test("no amount returns nil")
    func noAmount() {
        #expect(SpokenExpenseParser.parse("coffee at the corner shop") == nil)
    }

    @Test("no description returns nil")
    func noDescription() {
        #expect(SpokenExpenseParser.parse("six dollars") == nil)
    }

    @Test("zero amount returns nil")
    func zeroAmount() {
        #expect(SpokenExpenseParser.parse("0 coffee") == nil)
        #expect(SpokenExpenseParser.parse("zero dollar coffee") == nil)
    }

    @Test("over-max amount returns nil")
    func overMax() {
        #expect(SpokenExpenseParser.parse("$100000 car") == nil)
    }

    @Test("empty and whitespace-only return nil")
    func emptyInput() {
        #expect(SpokenExpenseParser.parse("") == nil)
        #expect(SpokenExpenseParser.parse("   ") == nil)
    }

    @Test("max amount accepted at boundary")
    func maxBoundary() {
        let result = SpokenExpenseParser.parse("$99999 car")
        #expect(result?.amountDollars == 99_999)
        #expect(result?.label == "car")
    }
}
