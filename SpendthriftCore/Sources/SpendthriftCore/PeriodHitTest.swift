import Foundation

public extension Array where Element == PeriodTotal {
    /// The element whose interval contains `date`, half-open (start
    /// inclusive, end exclusive) — the same bucketing expenses use, so a
    /// date exactly on a period boundary resolves to the later period.
    /// Used to map a tapped chart x-position back to its bar's period.
    func period(containing date: Date) -> PeriodTotal? {
        first { $0.interval.start <= date && date < $0.interval.end }
    }
}
