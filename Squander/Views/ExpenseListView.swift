import SwiftUI
import SwiftData

/// Drill-in list of expenses for a given period, grouped by calendar day in
/// reverse chronological order (expense-management spec).
struct ExpenseListView: View {
    let interval: DateInterval
    let title: String

    @Environment(\.expenseStore) private var store

    @Query private var allExpenses: [Expense]

    @State private var pendingUndoSnapshot: ExpenseStore.DeletedExpenseSnapshot?
    @State private var showUndoBar = false
    /// Each delete bumps this; a dismiss timer only clears state if no newer
    /// delete has replaced the snapshot it was scheduled for.
    @State private var undoGeneration = 0

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
        let indices = indexByID
        return ZStack(alignment: .bottom) {
            List {
                ForEach(sections) { section in
                    Section(header: Text(dayHeaderText(for: section.day))) {
                        ForEach(Array(section.expenses.enumerated()), id: \.element.persistentModelID) { _, expense in
                            NavigationLink {
                                ExpenseEditView(expense: expense)
                            } label: {
                                expenseRow(expense, globalIndex: globalIndex(of: expense, in: indices))
                            }
                            .accessibilityIdentifier("expense-row-\(globalIndex(of: expense, in: indices))")
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

    /// One O(n) pass instead of an O(n) scan per row; -1 (never a real row)
    /// for anything transiently absent so identifiers can't collide.
    private var indexByID: [PersistentIdentifier: Int] {
        Dictionary(uniqueKeysWithValues: allExpenses.enumerated().map { ($1.persistentModelID, $0) })
    }

    private func globalIndex(of expense: Expense, in indices: [PersistentIdentifier: Int]) -> Int {
        indices[expense.persistentModelID] ?? -1
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
            Text(expense.amountDollars.wholeDollars)
                .fontWeight(.medium)
        }
        .accessibilityElement(children: .combine)
    }

    private func dayHeaderText(for day: Date) -> String {
        dayLabel(for: day, calendar: calendar)
    }

    private func delete(_ expense: Expense) {
        guard let store else { return }
        do {
            let snapshot = try store.deleteExpense(expense)
            pendingUndoSnapshot = snapshot
            showUndoBar = true
            undoGeneration += 1
            let generation = undoGeneration
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                // A later delete owns the bar now; leave its window alone.
                if undoGeneration == generation, pendingUndoSnapshot != nil {
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
