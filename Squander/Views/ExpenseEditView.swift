import SwiftUI
import SquanderCore

/// Edit an existing expense: amount, description, and category, applying the
/// same validation as entry (expense-management spec). Timestamp is
/// preserved by ExpenseStore.updateExpense.
struct ExpenseEditView: View {
    let expense: Expense

    @Environment(\.expenseStore) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var amountState: AmountEntryState
    @State private var description: String
    @State private var selectedCategory: Category?

    @State private var showCategoryPicker = false

    init(expense: Expense) {
        self.expense = expense
        _amountState = State(initialValue: Self.amountState(for: expense.amountDollars))
        _description = State(initialValue: expense.label)
        _selectedCategory = State(initialValue: expense.category)
    }

    /// Builds an AmountEntryState matching `amount` by replaying its digits,
    /// since AmountEntryState only exposes tapDigit/tapDelete (no direct
    /// setter), per the fixed SquanderCore contract.
    private static func amountState(for amount: Int) -> AmountEntryState {
        var state = AmountEntryState()
        for digit in String(amount).compactMap({ $0.wholeNumberValue }) {
            state.tapDigit(digit)
        }
        return state
    }

    var body: some View {
        Form {
            Section("Amount") {
                AmountDisplayView(amountDollars: amountState.amount)
                KeypadView(state: $amountState)
                    .padding(.vertical, 8)
            }

            Section("Description") {
                TextField("Description", text: $description)
                    .onChange(of: description) { _, newValue in
                        description = DescriptionRules.clamp(newValue)
                    }
                    .accessibilityIdentifier("edit-description-field")
            }

            Section("Category") {
                Button {
                    showCategoryPicker = true
                } label: {
                    HStack {
                        if let selectedCategory {
                            Label(selectedCategory.name, systemImage: selectedCategory.iconName)
                                .foregroundStyle(CategoryColor.color(named: selectedCategory.colorName))
                        } else {
                            Text("Select a category")
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier("edit-category-button")
            }
        }
        .navigationTitle("Edit Expense")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(!canSave)
                .accessibilityIdentifier("edit-save-button")
            }
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerSheet(selectedCategory: $selectedCategory)
        }
    }

    private var canSave: Bool {
        guard amountState.canProceed else { return false }
        guard DescriptionRules.trimmedIfValid(description) != nil else { return false }
        return selectedCategory != nil
    }

    private func save() {
        guard let store else { return }
        guard let trimmed = DescriptionRules.trimmedIfValid(description) else { return }
        guard let category = selectedCategory else { return }
        guard amountState.canProceed else { return }

        do {
            try store.updateExpense(expense, amountDollars: amountState.amount, label: trimmed, category: category)
            dismiss()
        } catch {
            // No-op: leave the form open so the user can retry.
        }
    }
}
