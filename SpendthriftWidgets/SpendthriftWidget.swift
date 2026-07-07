import SwiftUI
import SwiftData
import WidgetKit
import SpendthriftCore
import os

// Int.wholeDollars comes from SpendthriftCore (DollarFormatting.swift) — the
// one formatter every surface shares; don't shadow it with a local copy.

struct SpendthriftWidgetEntry: TimelineEntry {
    let date: Date
    /// Whole-dollar totals for the calendar day/month/year containing `date`.
    let summary: SpendSummary
    let presets: [QuickLogPreset]
}

struct SpendthriftWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpendthriftWidgetEntry {
        SpendthriftWidgetEntry(date: .now, summary: .zero, presets: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SpendthriftWidgetEntry) -> Void) {
        completion(Self.loadEntry(at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpendthriftWidgetEntry>) -> Void) {
        let now = Date.now
        let calendar = Calendar.current
        var entries = [Self.loadEntry(at: now)]
        // Day rollover: a second entry at the next midnight so yesterday's
        // totals never linger (spec: widget-quick-entry). Month/year totals
        // recompute for the new day too.
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
            entries.append(Self.loadEntry(at: calendar.startOfDay(for: tomorrow)))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    /// One container for the extension process; widget extensions run under
    /// a tight memory ceiling, so don't rebuild it per timeline reload.
    private static let sharedContainer: ModelContainer? = {
        do {
            return try SpendthriftContainer.makeContainer()
        } catch {
            Logger(subsystem: "dev.jimfrederick.spendthrift.widgets", category: "store")
                .error("Widget could not open the shared store: \(error, privacy: .public)")
            return nil
        }
    }()

    /// Reads the day/month/year totals and the quick-log presets from the
    /// shared store. Falls back to an empty entry if the store can't be
    /// opened (already logged above — an entitlement/App Group
    /// misconfiguration would otherwise be indistinguishable from "no
    /// expenses yet").
    private static func loadEntry(at date: Date) -> SpendthriftWidgetEntry {
        guard let container = sharedContainer else {
            return SpendthriftWidgetEntry(date: date, summary: .zero, presets: [])
        }
        let context = ModelContext(container)
        let expenses = (try? context.fetch(FetchDescriptor<Expense>())) ?? []

        let summary = SpendSummary.compute(
            expenses: expenses.map { (timestamp: $0.timestamp, amount: $0.amountDollars) },
            asOf: date,
            calendar: Calendar.current
        )
        let presets = QuickLogPresets.compute(
            expenses: expenses.map { ($0.normalizedLabel, $0.label, $0.amountDollars, $0.timestamp) }
        )
        return SpendthriftWidgetEntry(date: date, summary: summary, presets: presets)
    }
}

struct SpendthriftWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SpendthriftWidgetEntry

    /// Status ring colors; the spent-today threshold itself is Core policy
    /// (SpendSummary.hasSpentToday, unit-tested there).
    private var statusColor: Color {
        entry.summary.hasSpentToday
            ? Color(red: 0.90, green: 0.26, blue: 0.21)
            : Color(red: 0.55, green: 0.85, blue: 0.55)
    }

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
                summaryStack
            }
        }
        .containerBackground(for: .widget) {
            // Accessory families render vibrantly and ignore this; the Home
            // Screen families get the status outline drawn at the widget's
            // own container shape so it hugs the corner radius.
            ZStack {
                Rectangle().fill(.background)
                ContainerRelativeShape()
                    .strokeBorder(statusColor, lineWidth: 2.5)
            }
        }
        .widgetURL(URL(string: "spendthrift://entry"))
    }

    private var mediumView: some View {
        HStack(spacing: 12) {
            summaryStack
                .frame(maxWidth: .infinity, alignment: .leading)

            if !entry.presets.isEmpty {
                presetGrid
            }
        }
    }

    /// The three headline numbers: today big, month and year beneath, flame
    /// mark in the corner.
    private var summaryStack: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top) {
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                FlameMark()
                    .frame(height: 20)
            }
            Text(entry.summary.today.wholeDollars)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Spacer(minLength: 2)
            HStack(alignment: .top, spacing: 14) {
                stat("Month", entry.summary.thisMonth)
                stat("Year", entry.summary.thisYear)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func stat(_ label: String, _ amount: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(amount.wholeDollars)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
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
            Text(entry.summary.today.wholeDollars)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Spendthrift")
                .font(.headline)
            Text("Today \(entry.summary.today.wholeDollars)")
                .font(.system(.body, design: .rounded, weight: .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SpendthriftWidget: Widget {
    let kind = "SpendthriftWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendthriftWidgetProvider()) { entry in
            SpendthriftWidgetView(entry: entry)
        }
        .configurationDisplayName("Spending at a Glance")
        .description("Today, this month, and this year — plus one-tap quick-log buttons.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}
