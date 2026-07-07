import SwiftUI
import CoreTransferable
import SpendthriftCore

/// The month-recap card: renders both inline in Insights and standalone
/// through ImageRenderer for the share sheet, so it takes plain values —
/// no queries, no environment (spec: spending-insights, month recap).
/// All sentences come from Core (MonthRecap/MonthComparison); this view
/// only lays them out.
struct RecapCardView: View {
    let monthTitle: String
    let total: Int
    let comparison: MonthComparison
    /// Exactly the categories rendered — the caller truncates to the
    /// spec's top three.
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

            if let headline = comparison.headline {
                Text(headline)
                    .font(.footnote)
                    .foregroundStyle(comparisonColor(for: comparison.direction))
            }

            Divider()

            ForEach(topCategories, id: \.category) { share in
                HStack {
                    Text(share.category)
                        .font(.subheadline)
                    Spacer()
                    Text(share.total.wholeDollars)
                        .font(.subheadline.weight(.medium))
                }
            }

            Divider()

            if let biggestDayLine = recap.biggestDayLine {
                factRow(symbol: "flame", text: biggestDayLine)
            }
            factRow(symbol: "leaf", text: recap.streakLine)
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
}

/// Lazily renders the recap card to a PNG when the share actually happens —
/// never on List re-render. Holds only Sendable values; the card view is
/// built inside the exporting closure on the main actor.
struct RecapShareItem: Transferable {
    let monthTitle: String
    let total: Int
    let comparison: MonthComparison
    let topCategories: [CategoryShare]
    let recap: MonthRecap
    /// Captured from the presenting view so the export matches what the
    /// user sees — ImageRenderer does not inherit the app's environment.
    let colorScheme: ColorScheme
    let displayScale: CGFloat

    enum RenderError: Error {
        case renderFailed
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            try await MainActor.run {
                let card = RecapCardView(
                    monthTitle: item.monthTitle,
                    total: item.total,
                    comparison: item.comparison,
                    topCategories: item.topCategories,
                    recap: item.recap
                )
                // Opaque backing: bare .padding would export transparent
                // pixels that composite badly on dark surfaces.
                let content = card
                    .frame(width: 360)
                    .padding(12)
                    .background(Color(uiColor: .systemBackground))
                    .environment(\.colorScheme, item.colorScheme)
                let renderer = ImageRenderer(content: content)
                renderer.scale = item.displayScale
                guard let data = renderer.uiImage?.pngData() else {
                    throw RenderError.renderFailed
                }
                return data
            }
        }
    }
}
