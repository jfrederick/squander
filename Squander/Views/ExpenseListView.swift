import SwiftUI
import SwiftData

/// Drill-in list of expenses for a given period, grouped by calendar day in
/// reverse chronological order (expense-management spec).
struct ExpenseListView: View {
    let interval: DateInterval
    let title: String

    @Environment(\.expenseStore) private var store
    @Environment(\.modelContext) private var modelContext

    @Query private var allExpenses: [Expense]

    @State private var pendingUndoSnapshot: ExpenseStore.DeletedExpenseSnapshot?
    @State private var showUndoBar = false

    init(interval: DateInterval, title: String) {
        self.interval = interval
        self.title = title
        let start = interval.start
        let end = interval.end
        _allExpenses = Query(
            filter: #Predicate<Expense> { $0.timestamp >= start && $0.timestamp < end },
            sort: [SortDescriptor(\Expense.timestamp, order: .reverse)]
        )
    }

    private var calendar: Calendar { .current }

    private struct DaySection: Identifiable {
        let day: Date
        var id: Date { day }
        let expenses: [Expense]
    }

    private var sections: [DaySection] {
        let grouped = Dictionary(grouping: allExpenses) { calendar.startOfDay(for: $0.timestamp) }
        return grouped.keys.sorted(by: >).map { day in
            DaySection(day: day, expenses: grouped[day]?.sorted { $0.timestamp > $1.timestamp } ?? [])
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                ForEach(sections) { section in
                    Section(header: Text(dayHeaderText(for: section.day))) {
                        ForEach(Array(section.expenses.enumerated()), id: \.element.persistentModelID) { _, expense in
                            NavigationLink {
                                ExpenseEditView(expense: expense)
                            } label: {
                                expenseRow(expense, globalIndex: globalIndex(of: expense))
                            }
                            .accessibilityIdentifier("expense-row-\(globalIndex(of: expense))")
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(expense)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)

            if showUndoBar {
                undoBar
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func globalIndex(of expense: Expense) -> Int {
        allExpenses.firstIndex(where: { $0.persistentModelID == expense.persistentModelID }) ?? 0
    }

    private func expenseRow(_ expense: Expense, globalIndex: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.label)
                    .font(.body)
                HStack(spacing: 4) {
                    if let category = expense.category {
                        Image(systemName: category.iconName)
                            .foregroundStyle(CategoryColor.color(named: category.colorName))
                        Text(category.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Text(expense.amountDollars.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                .fontWeight(.medium)
        }
        .accessibilityElement(children: .combine)
    }

    private func dayHeaderText(for day: Date) -> String {
        if calendar.isDateInToday(day) {
            return "Today"
        }
        if calendar.isDateInYesterday(day) {
            return "Yesterday"
        }
        return day.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private func delete(_ expense: Expense) {
        guard let store else { return }
        do {
            let snapshot = try store.deleteExpense(expense)
            pendingUndoSnapshot = snapshot
            showUndoBar = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                if pendingUndoSnapshot != nil {
                    pendingUndoSnapshot = nil
                    showUndoBar = false
                }
            }
        } catch {
            // No-op: deletion failed, nothing to undo.
        }
    }

    private var undoBar: some View {
        HStack {
            Text("Expense deleted")
                .foregroundStyle(.white)
            Spacer()
            Button("Undo") {
                undoDelete()
            }
            .foregroundStyle(.white)
            .fontWeight(.semibold)
            .accessibilityIdentifier("undo-button")
        }
        .padding()
        .background(.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 12))
        .padding()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func undoDelete() {
        guard let store, let pendingUndoSnapshot else { return }
        try? store.restoreExpense(pendingUndoSnapshot)
        self.pendingUndoSnapshot = nil
        showUndoBar = false
    }
}
