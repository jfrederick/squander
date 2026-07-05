import SwiftUI

/// Large whole-dollar amount display shared by entry and edit screens.
/// Shows a dimmed "$0" in the empty state (spec: "amount display shows an
/// empty/zero state").
struct AmountDisplayView: View {
    let amountDollars: Int

    private var formattedAmount: String {
        amountDollars.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    var body: some View {
        Text(formattedAmount)
            .font(.system(size: 56, weight: .bold, design: .rounded))
            .foregroundStyle(amountDollars == 0 ? .secondary : .primary)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .accessibilityIdentifier("amount-display")
            .accessibilityLabel("Amount \(formattedAmount)")
    }
}

#Preview {
    VStack(spacing: 24) {
        AmountDisplayView(amountDollars: 0)
        AmountDisplayView(amountDollars: 42)
        AmountDisplayView(amountDollars: 99_999)
    }
}
