import Testing
@testable import SquanderCore

@Suite("AmountEntryState")
struct AmountEntryStateTests {
    @Test("starts empty")
    func startsEmpty() {
        let state = AmountEntryState()
        #expect(state.amount == 0)
        #expect(!state.canProceed)
    }

    @Test("digits build the amount")
    func digitsBuildAmount() {
        var state = AmountEntryState()
        state.tapDigit(4)
        state.tapDigit(2)
        #expect(state.amount == 42)
    }

    @Test("leading zero is ignored")
    func leadingZeroIgnored() {
        var state = AmountEntryState()
        state.tapDigit(0)
        #expect(state.amount == 0)
        #expect(!state.canProceed)
    }

    @Test("zero after nonzero digit is accepted")
    func zeroAfterNonzeroAccepted() {
        var state = AmountEntryState()
        state.tapDigit(1)
        state.tapDigit(0)
        #expect(state.amount == 10)
    }

    @Test("delete removes the last digit: 42 -> 4 -> 0")
    func deleteRemovesLastDigit() {
        var state = AmountEntryState()
        state.tapDigit(4)
        state.tapDigit(2)
        #expect(state.amount == 42)
        state.tapDelete()
        #expect(state.amount == 4)
        state.tapDelete()
        #expect(state.amount == 0)
    }

    @Test("delete on empty state stays at zero")
    func deleteOnEmptyStaysZero() {
        var state = AmountEntryState()
        state.tapDelete()
        #expect(state.amount == 0)
    }

    @Test("amount capped at maximum: further digits rejected once at cap")
    func cappedAtMaximum() {
        var state = AmountEntryState()
        for digit in [9, 9, 9, 9, 9] {
            state.tapDigit(digit)
        }
        #expect(state.amount == 99_999)
        state.tapDigit(1)
        #expect(state.amount == 99_999)
    }

    @Test("$9,999 plus a digit reaching exactly $99,999 is allowed")
    func nineNineNineNinePlusDigitAllowed() {
        var state = AmountEntryState()
        for digit in [9, 9, 9, 9] {
            state.tapDigit(digit)
        }
        #expect(state.amount == 9_999)
        state.tapDigit(9)
        #expect(state.amount == 99_999)
    }

    @Test("digit that would exceed maxAmount is rejected")
    func digitExceedingMaxRejected() {
        var state = AmountEntryState()
        for digit in [9, 9, 9, 9, 9, 9] {
            state.tapDigit(digit)
        }
        // After 5 digits we're at 99999 (cap). A 6th digit is rejected.
        #expect(state.amount == 99_999)
    }

    @Test("digits outside 0...9 are ignored")
    func outOfRangeDigitsIgnored() {
        var state = AmountEntryState()
        state.tapDigit(-1)
        state.tapDigit(10)
        #expect(state.amount == 0)
        state.tapDigit(5)
        state.tapDigit(42)
        #expect(state.amount == 5)
    }

    @Test("zero amount cannot proceed")
    func zeroCannotProceed() {
        let state = AmountEntryState()
        #expect(!state.canProceed)
    }

    @Test("nonzero amount can proceed")
    func nonzeroCanProceed() {
        var state = AmountEntryState()
        state.tapDigit(1)
        #expect(state.canProceed)
    }

    @Test("maxAmount constant is 99999")
    func maxAmountConstant() {
        #expect(AmountEntryState.maxAmount == 99_999)
    }
}
