import Foundation

/// Tracks whole-dollar amount entry via a numeric keypad.
///
/// `amount == 0` represents the empty state. Leading zeros are ignored,
/// entry is capped at `maxAmount`, and only digits 0...9 are accepted.
public struct AmountEntryState: Equatable, Sendable {
    public static let maxAmount = 99_999

    public private(set) var amount: Int

    public init() {
        self.amount = 0
    }

    /// Restores entry state from a previously saved amount (e.g. when
    /// editing an existing expense). Values outside 0...maxAmount are
    /// clamped so the state's invariants hold regardless of input.
    public init(amount: Int) {
        self.amount = min(max(amount, 0), Self.maxAmount)
    }

    /// Appends `digit` to the amount, ignoring invalid input.
    ///
    /// - A leading zero (when `amount == 0` and `digit == 0`) is ignored.
    /// - Digits outside 0...9 are ignored.
    /// - If appending the digit would push the amount beyond `maxAmount`,
    ///   the digit is ignored and the amount is left unchanged.
    public mutating func tapDigit(_ digit: Int) {
        guard (0...9).contains(digit) else { return }
        if amount == 0 && digit == 0 { return }

        let candidate = amount * 10 + digit
        guard candidate <= Self.maxAmount else { return }
        amount = candidate
    }

    /// Removes the last digit of the amount (42 -> 4 -> 0).
    public mutating func tapDelete() {
        amount = amount / 10
    }

    /// Whether the current amount is valid to proceed with (>= 1).
    public var canProceed: Bool {
        amount >= 1
    }
}
