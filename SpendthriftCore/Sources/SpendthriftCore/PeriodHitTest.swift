import Foundation

public extension Array where Element == PeriodTotal {
    /// The element whose interval contains `date`, half-open (start
    /// inclusive, end exclusive) — the same bucketing expenses use, so a
    /// date exactly on a period boundary resolves to the later period.
    /// Used to map a tapped chart x-position back to its bar's period.
    func period(containing date: Date) -> PeriodTotal? {
        first { $0.interval.start <= date && date < $0.interval.end }
    }

    /// The drill-in target for a chart tap resolved to `date`: the
    /// containing period only if it has expenses. Empty periods return nil —
    /// the app never offers empty-period drill-ins (the totals list omits
    /// them entirely).
    func drillInPeriod(containing date: Date) -> PeriodTotal? {
        guard let period = period(containing: date), period.total > 0 else { return nil }
        return period
    }
}
