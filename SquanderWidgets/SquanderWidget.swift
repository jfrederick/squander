import SwiftUI
import SwiftData
import WidgetKit
import SquanderCore

/// Whole-dollar formatting, mirroring the app's `Formatting.swift` (which
/// belongs to the app target and is not compiled into the extension).
extension Int {
    var wholeDollars: String {
        formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

struct SquanderWidgetEntry: TimelineEntry {
    let date: Date
    /// Whole-dollar total of the calendar day containing `date`.
    let todayTotal: Int
    let presets: [QuickLogPreset]
}

struct SquanderWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SquanderWidgetEntry {
        SquanderWidgetEntry(date: .now, todayTotal: 0, presets: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SquanderWidgetEntry) -> Void) {
        completion(Self.loadEntry(at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SquanderWidgetEntry>) -> Void) {
        let now = Date.now
        let calendar = Calendar.current
        var entries = [Self.loadEntry(at: now)]
        // Day rollover: a second entry at the next midnight so yesterday's
        // total never lingers (spec: widget-quick-entry).
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
            entries.append(Self.loadEntry(at: calendar.startOfDay(for: tomorrow)))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    /// Reads today's total and the quick-log presets from the shared store.
    /// Falls back to an empty entry if the store can't be opened.
    private static func loadEntry(at date: Date) -> SquanderWidgetEntry {
        guard let container = try? SquanderContainer.makeContainer() else {
            return SquanderWidgetEntry(date: date, todayTotal: 0, presets: [])
        }
        let context = ModelContext(container)
        let expenses = (try? context.fetch(FetchDescriptor<Expense>())) ?? []

        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
        let todayTotal = expenses
            .filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
            .reduce(0) { $0 + $1.amountDollars }

        let presets = QuickLogPresets.compute(
            expenses: expenses.map { ($0.normalizedLabel, $0.label, $0.amountDollars, $0.timestamp) }
        )
        return SquanderWidgetEntry(date: date, todayTotal: todayTotal, presets: presets)
    }
}

struct SquanderWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SquanderWidgetEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                mediumView
            case .accessoryCircular:
                circularView
            case .accessoryRectangular:
                rectangularView
            default:
                smallView
            }
        }
        .containerBackground(.background, for: .widget)
        .widgetURL(URL(string: "squander://entry"))
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Today")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(entry.todayTotal.wholeDollars)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(entry.todayTotal.wholeDollars)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !entry.presets.isEmpty {
                presetGrid
            }
        }
    }

    private var presetGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)],
            spacing: 6
        ) {
            ForEach(entry.presets.prefix(4), id: \.label) { preset in
                Button(intent: LogQuickExpenseIntent(label: preset.label, amount: preset.amount)) {
                    Text("\(preset.label) \(preset.amount.wholeDollars)")
                        .font(.caption2.weight(.medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.accentColor)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var circularView: some View {
        VStack(spacing: 0) {
            Text("Today")
                .font(.system(size: 10))
            Text(entry.todayTotal.wholeDollars)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Squander")
                .font(.headline)
            Text("Today \(entry.todayTotal.wholeDollars)")
                .font(.system(.body, design: .rounded, weight: .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SquanderWidget: Widget {
    let kind = "SquanderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SquanderWidgetProvider()) { entry in
            SquanderWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Spending")
        .description("Today's total and one-tap quick-log buttons.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}
