import SwiftUI
import SpendthriftCore

/// Shared numeric keypad UI for whole-dollar amount entry (design D4).
/// 4x3 grid: 1-9, blank, 0, delete. No decimal key by design.
struct KeypadView: View {
    @Binding var state: AmountEntryState

    private let rows: [[KeypadKey]] = [
        [.digit(1), .digit(2), .digit(3)],
        [.digit(4), .digit(5), .digit(6)],
        [.digit(7), .digit(8), .digit(9)],
        [.blank, .digit(0), .delete]
    ]

    private enum KeypadKey {
        case digit(Int)
        case delete
        case blank
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: 12) {
                    ForEach(0..<rows[rowIndex].count, id: \.self) { columnIndex in
                        keyView(for: rows[rowIndex][columnIndex])
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func keyView(for key: KeypadKey) -> some View {
        switch key {
        case .digit(let d):
            Button {
                state.tapDigit(d)
            } label: {
                Text("\(d)")
                    .font(.system(.title, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
            }
            .buttonStyle(.plain)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityIdentifier("keypad-\(d)")
            .accessibilityLabel("\(d)")

        case .delete:
            Button {
                state.tapDelete()
            } label: {
                Image(systemName: "delete.left")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
            }
            .buttonStyle(.plain)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityIdentifier("keypad-delete")
            .accessibilityLabel("Delete")

        case .blank:
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    KeypadView(state: .constant(AmountEntryState()))
        .padding()
}
