import SwiftUI
import SpendthriftCore

/// The month-recap card: renders both inline in Insights and standalone
/// through ImageRenderer for the share sheet, so it takes plain values —
/// no queries, no environment (spec: spending-insights, month recap).
struct RecapCardView: View {
    let monthTitle: String
    let total: Int
    let comparison: MonthComparison
    /// Top categories, already ranked (the view truncates to three).
    let topCategories: [CategoryShare]
    let recap: MonthRecap

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(monthTitle)
                    .font(.headline)
                Spacer()
                Text(total.wholeDollars)
                    .font(.system(.title2, design: .rounded, weight: .bold))
            }

            if let percent = comparison.percentChange {
                Text("\(percent < 0 ? "" : "+")\(percent)% vs last month")
                    .font(.footnote)
                    .foregroundStyle(comparisonColor)
            }

            Divider()

            ForEach(topCategories.prefix(3), id: \.category) { share in
                HStack {
                    Text(share.category)
                        .font(.subheadline)
                    Spacer()
                    Text(share.total.wholeDollars)
                        .font(.subheadline.weight(.medium))
                }
            }

            Divider()

            if let biggest = recap.biggestDay {
                factRow(
                    symbol: "flame",
                    text: "Biggest day: \(biggest.day.formatted(.dateTime.month(.abbreviated).day())) · \(biggest.total.wholeDollars)"
                )
            }
            factRow(
                symbol: "leaf",
                text: "Longest no-spend streak: \(recap.longestNoSpendStreak) \(recap.longestNoSpendStreak == 1 ? "day" : "days")"
            )
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }

    private func factRow(symbol: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.footnote)
        }
    }

    private var comparisonColor: Color {
        switch comparison.direction {
        case .increase: return .red
        case .decrease: return .green
        case .flat: return .secondary
        }
    }
}
