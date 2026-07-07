import Foundation

/// A month's total compared against the previous calendar month.
public struct MonthComparison: Equatable, Sendable {
    public enum Direction: Equatable, Sendable {
        case increase
        case decrease
        case flat
    }

    /// Whole-dollar difference: current minus previous (0 when there is no
    /// previous total to compare against).
    public let delta: Int
    /// Whole-percent change vs the previous month, rounded half away from
    /// zero. `nil` when the previous month is absent or zero — the "no prior
    /// data" case, where a percentage is undefined.
    public let percentChange: Int?
    public let direction: Direction

    public init(delta: Int, percentChange: Int?, direction: Direction) {
        self.delta = delta
        self.percentChange = percentChange
        self.direction = direction
    }


    /// The month-over-month sentence shared by the Insights header line and
    /// the recap card, so the two renderings can't drift (copy in Core per
    /// the WeeklyDigest/SpendingPace precedent). Nil with no baseline month.
    public var headline: String? {
        guard let percentChange else { return nil }
        let dollars = delta < 0 ? "-\(abs(delta).wholeDollars)" : "+\(delta.wholeDollars)"
        let percent = percentChange < 0 ? "\(percentChange)%" : "+\(percentChange)%"
        return "\(dollars) (\(percent)) vs last month"
    }

    /// Compares `currentTotal` against `previousTotal`. Pass `nil` for
    /// `previousTotal` when the previous month has no expenses.
    public static func compute(currentTotal: Int, previousTotal: Int?) -> MonthComparison {
        guard let previousTotal, previousTotal != 0 else {
            return MonthComparison(delta: 0, percentChange: nil, direction: .flat)
        }

        let delta = currentTotal - previousTotal
        let direction: Direction = delta > 0 ? .increase : (delta < 0 ? .decrease : .flat)

        // Integer rounding half away from zero: (|delta| * 200 + prev) / (2 * prev),
        // sign restored afterward. previousTotal is a positive dollar total.
        let magnitude = (abs(delta) * 200 + previousTotal) / (2 * previousTotal)
        let percent = delta < 0 ? -magnitude : magnitude

        return MonthComparison(delta: delta, percentChange: percent, direction: direction)
    }
}
