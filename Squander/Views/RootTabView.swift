import SwiftUI

/// App root: a two-tab layout with Entry as the default tab (design D4/D8).
struct RootTabView: View {
    @State private var selectedTab: Tab = .entry

    private enum Tab: Hashable {
        case entry
        case totals
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            EntryView()
                .tabItem {
                    Label("Entry", systemImage: "square.grid.3x3.fill")
                        .accessibilityIdentifier("tab-entry")
                }
                .tag(Tab.entry)

            TotalsView()
                .tabItem {
                    Label("Totals", systemImage: "chart.bar.fill")
                        .accessibilityIdentifier("tab-totals")
                }
                .tag(Tab.totals)
        }
        // squander://entry — the widget's non-button tap target opens the
        // app straight onto the keypad (spec: widget-quick-entry).
        .onOpenURL { url in
            if url.scheme == "squander", url.host == "entry" {
                selectedTab = .entry
            }
        }
    }
}

#Preview {
    RootTabView()
}
