import Foundation

/// Shared display formatting (design D3: whole-dollar currency, zero
/// fraction digits, everywhere).
extension Int {
    var wholeDollars: String {
        formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

/// Shared "Today"/"Yesterday"/date day label used by the totals list and the
/// drill-in expense list.
func dayLabel(for date: Date, calendar: Calendar = .current) -> String {
    if calendar.isDateInToday(date) {
        return "Today"
    }
    if calendar.isDateInYesterday(date) {
        return "Yesterday"
    }
    return date.formatted(.dateTime.month(.abbreviated).day().year())
}
