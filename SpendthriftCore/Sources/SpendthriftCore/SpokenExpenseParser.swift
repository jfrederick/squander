import Foundation

/// A parsed voice utterance: whole-dollar amount plus the leftover
/// description tokens.
public struct SpokenExpense: Equatable, Sendable {
    public let amountDollars: Int
    public let label: String

    public init(amountDollars: Int, label: String) {
        self.amountDollars = amountDollars
        self.label = label
    }
}

/// Turns a Siri-transcribed utterance ("six dollar coffee", "$14 lunch",
/// "spent twenty bucks for parking") into an amount and description.
/// Deterministic token grammar — no ML, English only. Returns nil when no
/// in-range amount or no description tokens remain.
public enum SpokenExpenseParser {
    /// Leading command words Siri users habitually include.
    private static let commandFillers: Set<String> = ["log", "add", "spent"]
    private static let currencyWords: Set<String> = ["dollar", "dollars", "buck", "bucks"]
    private static let connectives: Set<String> = ["for", "on", "of"]

    private static let units: [String: Int] = [
        "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
        "six": 6, "seven": 7, "eight": 8, "nine": 9,
    ]
    private static let teens: [String: Int] = [
        "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14,
        "fifteen": 15, "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19,
    ]
    private static let tens: [String: Int] = [
        "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50,
        "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90,
    ]

    public static func parse(_ utterance: String) -> SpokenExpense? {
        var tokens = tokenize(utterance)
        while let first = tokens.first, commandFillers.contains(first) {
            tokens.removeFirst()
        }
        guard !tokens.isEmpty else { return nil }

        guard let span = amountSpan(in: tokens) else { return nil }
        guard span.value >= 1, span.value <= AmountEntryState.maxAmount else { return nil }

        var lower = span.range.lowerBound
        var upper = span.range.upperBound
        // Swallow one connective touching the amount ("spent 14 ON lunch",
        // "coffee FOR six dollars") so it doesn't pollute the description.
        if upper < tokens.count, connectives.contains(tokens[upper]) {
            upper += 1
        } else if lower > 0, connectives.contains(tokens[lower - 1]) {
            lower -= 1
        }

        let labelTokens = tokens[..<lower] + tokens[upper...]
        guard !labelTokens.isEmpty else { return nil }
        return SpokenExpense(amountDollars: span.value, label: labelTokens.joined(separator: " "))
    }

    // MARK: - Tokenization

    private static func tokenize(_ utterance: String) -> [String] {
        normalize(utterance)
            .split(whereSeparator: { $0.isWhitespace || $0 == "-" })
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?")) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Amount location

    private struct AmountSpan {
        let value: Int
        let range: Range<Int>
    }

    /// The amount is the numeric group directly before a currency word when
    /// one exists (so number words in the description don't steal it);
    /// otherwise the first numeric group anywhere in the utterance.
    private static func amountSpan(in tokens: [String]) -> AmountSpan? {
        if let currencyIndex = tokens.firstIndex(where: { currencyWords.contains($0) }) {
            for start in 0..<currencyIndex {
                if let number = number(in: tokens, from: start), start + number.length == currencyIndex {
                    return AmountSpan(value: number.value, range: start..<(currencyIndex + 1))
                }
            }
            // Currency word with no number attached: fall through to a
            // plain scan (e.g. "dollars" appearing inside a description).
        }
        for start in 0..<tokens.count {
            if let number = number(in: tokens, from: start) {
                return AmountSpan(value: number.value, range: start..<(start + number.length))
            }
        }
        return nil
    }

    // MARK: - Number reading

    /// A digit token or the longest valid number-word run starting at `start`.
    private static func number(in tokens: [String], from start: Int) -> (value: Int, length: Int)? {
        if let digits = digitValue(tokens[start]) {
            return (digits, 1)
        }
        return wordRun(in: tokens, from: start)
    }

    private static func digitValue(_ token: String) -> Int? {
        var body = Substring(token)
        if body.hasPrefix("$") { body = body.dropFirst() }
        guard !body.isEmpty, body.count <= 6, body.allSatisfy(\.isNumber) else { return nil }
        return Int(body)
    }

    /// Greedy word-number reader ("a hundred and ten" -> 110) that returns
    /// the longest prefix forming a well-formed number, so "seven eleven"
    /// reads as 7 leaving "eleven" to the description.
    private static func wordRun(in tokens: [String], from start: Int) -> (value: Int, length: Int)? {
        var total = 0      // completed thousands
        var current = 0    // group under construction
        var index = start
        var best: (value: Int, length: Int)?

        func markValid() { best = (total + current, index - start + 1) }

        loop: while index < tokens.count {
            let token = tokens[index]
            switch token {
            case "zero":
                guard index == start else { break loop }
                best = (0, 1)
                break loop
            case "a":
                // "a" only counts as one before hundred/thousand.
                guard index == start, index + 1 < tokens.count,
                      tokens[index + 1] == "hundred" || tokens[index + 1] == "thousand"
                else { break loop }
                current = 1
            case "and":
                // Joiner inside a group ("hundred and ten") — never terminal.
                guard total + current > 0, current % 100 == 0, index + 1 < tokens.count,
                      units[tokens[index + 1]] != nil || teens[tokens[index + 1]] != nil || tens[tokens[index + 1]] != nil
                else { break loop }
            case "hundred":
                guard (1...9).contains(current) else { break loop }
                current *= 100
                markValid()
            case "thousand":
                guard (1...9).contains(current) else { break loop }
                total += current * 1000
                current = 0
                markValid()
            default:
                if let unit = units[token] {
                    guard current % 100 == 0 || tens.values.contains(current % 100) else { break loop }
                    current += unit
                    markValid()
                } else if let teen = teens[token] {
                    guard current % 100 == 0 else { break loop }
                    current += teen
                    markValid()
                } else if let ten = tens[token] {
                    guard current % 100 == 0 else { break loop }
                    current += ten
                    markValid()
                } else {
                    break loop
                }
            }
            index += 1
        }
        return best
    }
}
