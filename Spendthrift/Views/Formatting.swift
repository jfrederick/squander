import Foundation
import SwiftUI
import SpendthriftCore

// Int.wholeDollars moved to SpendthriftCore (DollarFormatting.swift) so the
// digest notification copy shares the exact formatter the views use.

/// Shared month-over-month color semantics (red = spent more, green = spent
/// less) used by the Insights header line and the recap card; the sentence
/// itself is MonthComparison.headline in Core.
func comparisonColor(for direction: MonthComparison.Direction) -> Color {
    switch direction {
    case .increase: return .red
    case .decrease: return .green
    case .flat: return .secondary
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
