import Testing
import Foundation
@testable import SquanderCore

@Suite("QuickLogPresets")
struct QuickLogPresetsTests {
    typealias ExpenseTuple = (normalizedLabel: String, label: String, amount: Int, timestamp: Date)

    /// Fixed base date: 2026-01-01 00:00:00 UTC.
    static let base = Date(timeIntervalSince1970: 1_767_225_600)

    /// A fixed date `days` after (or before, if negative) the base date.
    static func day(_ days: Int) -> Date {
        base.addingTimeInterval(TimeInterval(days) * 86_400)
    }

    static func expenses(
        _ normalizedLabel: String,
        label: String? = nil,
        amounts: [Int],
        startingDay: Int = 0
    ) -> [ExpenseTuple] {
        amounts.enumerated().map { offset, amount in
            (normalizedLabel, label ?? normalizedLabel, amount, day(startingDay + offset))
        }
    }

    @Test("spec scenario: cafe 20x modal $6 and electrolytes 5x modal $4")
    func specScenario() {
        // cafe: 20 expenses, $6 is modal (12 of 20), some $5s and $7s mixed in.
        let cafe = Self.expenses("cafe", amounts: [6, 5, 6, 7, 6, 6, 5, 6, 6, 7, 6, 6, 5, 6, 6, 7, 6, 6, 5, 6])
        // electrolytes: 5 expenses, $4 is modal.
        let electrolytes = Self.expenses("electrolytes", amounts: [4, 4, 3, 4, 4], startingDay: 30)

        let presets = QuickLogPresets.compute(expenses: cafe + electrolytes)
        #expect(presets == [
            QuickLogPreset(label: "cafe", amount: 6),
            QuickLogPreset(label: "electrolytes", amount: 4)
        ])
    }

    @Test("no label with two or more expenses yields no presets")
    func insufficientHistory() {
        let expenses: [ExpenseTuple] = [
            ("cafe", "cafe", 6, Self.day(0)),
            ("electrolytes", "electrolytes", 4, Self.day(1)),
            ("parking", "parking", 12, Self.day(2))
        ]
        #expect(QuickLogPresets.compute(expenses: expenses).isEmpty)
    }

    @Test("empty history yields no presets")
    func emptyHistory() {
        #expect(QuickLogPresets.compute(expenses: []).isEmpty)
    }

    @Test("a single-expense label is excluded even alongside qualifying ones")
    func singleExpenseLabelExcluded() {
        let expenses = Self.expenses("cafe", amounts: [6, 6])
            + [("gym", "gym", 30, Self.day(50))] as [ExpenseTuple]
        let presets = QuickLogPresets.compute(expenses: expenses)
        #expect(presets == [QuickLogPreset(label: "cafe", amount: 6)])
    }

    @Test("labels rank by expense count descending")
    func countRanking() {
        let expenses = Self.expenses("rare", amounts: [9, 9])
            + Self.expenses("common", amounts: [2, 2, 2], startingDay: 10)
        let presets = QuickLogPresets.compute(expenses: expenses)
        #expect(presets.map(\.label) == ["common", "rare"])
    }

    @Test("equal counts tie-break by most recent expense descending")
    func recencyTieBreak() {
        let older = Self.expenses("older", amounts: [1, 1], startingDay: 0)
        let newer = Self.expenses("newer", amounts: [2, 2], startingDay: 5)
        let presets = QuickLogPresets.compute(expenses: older + newer)
        #expect(presets.map(\.label) == ["newer", "older"])
    }

    @Test("equal count and recency tie-break by label ascending")
    func labelTieBreak() {
        // Same counts, same most-recent timestamp (day 1 for both).
        let expenses: [ExpenseTuple] = [
            ("banana", "banana", 1, Self.day(0)),
            ("banana", "banana", 1, Self.day(1)),
            ("apple", "apple", 2, Self.day(0)),
            ("apple", "apple", 2, Self.day(1))
        ]
        let presets = QuickLogPresets.compute(expenses: expenses)
        #expect(presets.map(\.label) == ["apple", "banana"])
    }

    @Test("preset amount is the label's most frequent amount")
    func modalAmount() {
        let presets = QuickLogPresets.compute(expenses: Self.expenses("cafe", amounts: [5, 6, 6, 7, 6]))
        #expect(presets == [QuickLogPreset(label: "cafe", amount: 6)])
    }

    @Test("equally frequent amounts tie-break by most recent use")
    func amountRecencyTieBreak() {
        // $5 twice (days 0, 1), $8 twice (days 2, 3) -> $8 used more recently.
        let presets = QuickLogPresets.compute(expenses: Self.expenses("cafe", amounts: [5, 5, 8, 8]))
        #expect(presets == [QuickLogPreset(label: "cafe", amount: 8)])
    }

    @Test("amount tie-break prefers recency even when the older amount appears first and last-but-one")
    func amountRecencyTieBreakInterleaved() {
        // $8 on days 0 and 2; $5 on days 1 and 3 -> $5's latest use is newest.
        let presets = QuickLogPresets.compute(expenses: Self.expenses("cafe", amounts: [8, 5, 8, 5]))
        #expect(presets == [QuickLogPreset(label: "cafe", amount: 5)])
    }

    @Test("at most four presets by default")
    func defaultLimit() {
        let expenses = Self.expenses("a", amounts: [1, 1, 1, 1, 1, 1])
            + Self.expenses("b", amounts: [2, 2, 2, 2, 2], startingDay: 10)
            + Self.expenses("c", amounts: [3, 3, 3, 3], startingDay: 20)
            + Self.expenses("d", amounts: [4, 4, 4], startingDay: 30)
            + Self.expenses("e", amounts: [5, 5], startingDay: 40)
        let presets = QuickLogPresets.compute(expenses: expenses)
        #expect(presets.map(\.label) == ["a", "b", "c", "d"])
    }

    @Test("custom limit is respected")
    func customLimit() {
        let expenses = Self.expenses("a", amounts: [1, 1, 1])
            + Self.expenses("b", amounts: [2, 2], startingDay: 10)
        let presets = QuickLogPresets.compute(expenses: expenses, limit: 1)
        #expect(presets == [QuickLogPreset(label: "a", amount: 1)])
    }

    @Test("zero limit yields no presets")
    func zeroLimit() {
        let expenses = Self.expenses("a", amounts: [1, 1, 1])
        #expect(QuickLogPresets.compute(expenses: expenses, limit: 0).isEmpty)
    }

    @Test("display casing comes from the most recent expense")
    func displayCasing() {
        let expenses: [ExpenseTuple] = [
            ("cafe", "cafe", 6, Self.day(0)),
            ("cafe", "CAFE", 6, Self.day(1)),
            ("cafe", "Café", 6, Self.day(2))
        ]
        let presets = QuickLogPresets.compute(expenses: expenses)
        #expect(presets == [QuickLogPreset(label: "Café", amount: 6)])
    }

    @Test("groups match on normalizedLabel across differing display casings")
    func groupsByNormalizedLabel() {
        let expenses: [ExpenseTuple] = [
            ("cafe", "Cafe", 6, Self.day(0)),
            ("cafe", "café", 6, Self.day(1))
        ]
        let presets = QuickLogPresets.compute(expenses: expenses)
        #expect(presets.count == 1)
        #expect(presets.first?.label == "café")
    }
}
