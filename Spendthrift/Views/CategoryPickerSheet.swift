import SwiftUI
import SpendthriftCore

/// Sheet listing all categories for selection, with inline "New category"
/// creation subject to the 30-category cap (expense-categorization spec).
struct CategoryPickerSheet: View {
    @Environment(\.expenseStore) private var store
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedCategory: Category?

    @State private var categories: [Category] = []
    @State private var isAddingNewCategory = false
    @State private var newCategoryName = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(categories, id: \.name) { category in
                        Button {
                            selectedCategory = category
                            dismiss()
                        } label: {
                            HStack {
                                Label(category.name, systemImage: category.iconName)
                                    .foregroundStyle(CategoryColor.color(named: category.colorName))
                                Spacer()
                                if selectedCategory?.name == category.name {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .accessibilityIdentifier("category-row-\(category.name)")
                    }
                }

                Section {
                    if isAddingNewCategory {
                        newCategoryEntryRow
                    } else {
                        Button {
                            isAddingNewCategory = true
                            errorMessage = nil
                        } label: {
                            Label("New category", systemImage: "plus.circle")
                        }
                        .accessibilityIdentifier("new-category-button")
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                            .accessibilityIdentifier("category-cap-message")
                    }
                }
            }
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCategories()
            }
        }
    }

    private var newCategoryEntryRow: some View {
        HStack {
            TextField("Category name", text: $newCategoryName)
                .accessibilityIdentifier("new-category-name-field")

            Button("Add") {
                createCategory()
            }
            .accessibilityIdentifier("add-category-confirm-button")
            .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func loadCategories() {
        guard let store else { return }
        categories = (try? store.allCategories()) ?? []
    }

    private func createCategory() {
        guard let store else { return }

        guard CategoryRules.canCreate(existingCount: categories.count) else {
            errorMessage = "You've reached the limit of \(CategoryRules.maxCount) categories."
            isAddingNewCategory = false
            return
        }

        do {
            let newCategory = try store.createCategory(named: newCategoryName)
            selectedCategory = newCategory
            newCategoryName = ""
            isAddingNewCategory = false
            errorMessage = nil
            dismiss()
        } catch let error as ExpenseStore.CategoryCreationError {
            switch error {
            case .capReached:
                errorMessage = "You've reached the limit of \(CategoryRules.maxCount) categories."
            case .duplicateName:
                errorMessage = "A category with that name already exists."
            case .invalidName:
                errorMessage = "Please enter a category name."
            }
        } catch {
            errorMessage = "Could not create the category."
        }
    }
}

#Preview {
    CategoryPickerSheet(selectedCategory: .constant(nil))
}
