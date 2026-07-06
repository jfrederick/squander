import SwiftUI

/// App root: a two-tab layout with Entry as the default tab (design D4/D8).
/// Saving an expense switches to the Totals tab; the transient save
/// confirmation overlays whichever tab is showing.
struct RootTabView: View {
    @State private var selectedTab: Tab = .entry
    @State private var showSaveConfirmation = false
    /// Each save bumps this; a dismiss timer only hides the confirmation it
    /// was scheduled for, so rapid saves keep the overlay up.
    @State private var confirmationGeneration = 0

    private enum Tab: Hashable {
        case entry
        case totals
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // No identifiers on tabItem labels — SwiftUI doesn't surface
                // them on the rendered tab-bar buttons; tests must use
                // app.tabBars.buttons["Entry"/"Totals"] by visible label.
                EntryView(onSaved: handleExpenseSaved)
                    .tabItem {
                        Label("Entry", systemImage: "square.grid.3x3.fill")
                    }
                    .tag(Tab.entry)

                TotalsView()
                    .tabItem {
                        Label("Totals", systemImage: "chart.bar.fill")
                    }
                    .tag(Tab.totals)
            }

            if showSaveConfirmation {
                saveConfirmationOverlay
            }
        }
        // spendthrift://entry — the widget's non-button tap target opens the
        // app straight onto the keypad (spec: widget-quick-entry).
        .onOpenURL { url in
            if url.scheme == "spendthrift", url.host == "entry" {
                selectedTab = .entry
            }
        }
        // Returning to Entry is the "next expense" signal — drop the
        // confirmation early rather than letting it hover over the keypad.
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .entry, showSaveConfirmation {
                confirmationGeneration += 1
                withAnimation {
                    showSaveConfirmation = false
                }
            }
        }
    }

    private func handleExpenseSaved() {
        selectedTab = .totals
        withAnimation {
            showSaveConfirmation = true
        }
        confirmationGeneration += 1
        let generation = confirmationGeneration
        // 3s (not shorter): UI-test accessibility snapshots take ~2s+ after
        // the Save tap; a briefer window outlives its own assertion.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if confirmationGeneration == generation {
                withAnimation {
                    showSaveConfirmation = false
                }
            }
        }
    }

    // MARK: - Save confirmation (spec: non-blocking, no tap to dismiss)

    private var saveConfirmationOverlay: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 48))
            .foregroundStyle(.green)
            .padding(24)
            .background(.thinMaterial, in: Circle())
            .accessibilityIdentifier("save-confirmation")
            .accessibilityLabel("Expense saved")
            .transition(.opacity)
            .allowsHitTesting(false)
    }
}

#Preview {
    RootTabView()
}
