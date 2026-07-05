import SwiftUI
import SquanderCore

/// Two-step single-screen expense capture (design D4): amount step, then
/// description+category step. No NavigationStack push between the steps.
struct EntryView: View {
    @Environment(\.expenseStore) private var store
    @Environment(\.scenePhase) private var scenePhase

    private enum Step {
        case amount
        case description
    }

    @State private var step: Step = .amount
    @State private var amountState = AmountEntryState()
    @State private var description: String = ""
    @State private var suggestions: [LabelStat] = []
    @State private var showCategoryArea = false
    @State private var selectedCategory: Category?
    @State private var suggestedCategoryName: String = CategoryRules.fallbackCategoryName
    @State private var showCategoryPicker = false
    @State private var showConfirmation = false
    @State private var backgroundedAt: Date?

    @FocusState private var isDescriptionFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 24) {
                    AmountDisplayView(amountDollars: amountState.amount)
                        .padding(.top, 32)

                    if step == .description {
                        descriptionSection
                    }

                    Spacer()

                    if step == .amount {
                        amountStepControls
                    }
                }
                .padding()

                if showConfirmation {
                    confirmationOverlay
                }
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if step == .description {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Back") {
                            step = .amount
                        }
                        .accessibilityIdentifier("back-button")
                    }
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerSheet(selectedCategory: $selectedCategory)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    // MARK: - Amount step

    private var amountStepControls: some View {
        VStack(spacing: 20) {
            KeypadView(state: $amountState)

            Button("Next") {
                advanceToDescription()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(amountState.canProceed ? Color.accentColor : Color.gray.opacity(0.3))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(!amountState.canProceed)
            .accessibilityIdentifier("next-button")
        }
    }

    private func advanceToDescription() {
        guard amountState.canProceed else { return }
        step = .description
        isDescriptionFieldFocused = true
    }

    // MARK: - Description step

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Description", text: $description)
                .textFieldStyle(.roundedBorder)
                .focused($isDescriptionFieldFocused)
                .accessibilityIdentifier("description-field")
                .accessibilityLabel("Description")
                .onChange(of: description) { _, newValue in
                    description = DescriptionRules.clamp(newValue)
                    refreshSuggestions()
                    refreshCategoryArea()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isDescriptionFieldFocused = true
                    }
                    refreshSuggestions()
                    refreshCategoryArea()
                }

            if !suggestions.isEmpty {
                suggestionList
            }

            if showCategoryArea {
                categoryConfirmationArea
            }

            Button("Save") {
                save()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(canSave ? Color.accentColor : Color.gray.opacity(0.3))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(!canSave)
            .accessibilityIdentifier("save-button")
        }
    }

    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                Button {
                    acceptSuggestion(suggestion)
                } label: {
                    Text(suggestion.label)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("suggestion-row-\(index)")
                .accessibilityLabel("Suggestion \(suggestion.label)")

                if index < suggestions.count - 1 {
                    Divider()
                }
            }
        }
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var categoryConfirmationArea: some View {
        HStack {
            Label(
                selectedCategory?.name ?? suggestedCategoryName,
                systemImage: selectedCategory?.iconName ?? "tag.fill"
            )
            .foregroundStyle(CategoryColor.color(named: selectedCategory?.colorName ?? "gray"))
            .accessibilityIdentifier("category-chip")
            .accessibilityLabel("Category \(selectedCategory?.name ?? suggestedCategoryName)")

            Spacer()

            Button("Change") {
                showCategoryPicker = true
            }
            .accessibilityIdentifier("category-change-button")
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    private var canSave: Bool {
        guard DescriptionRules.trimmedIfValid(description) != nil else { return false }
        if showCategoryArea {
            return selectedCategory != nil || !suggestedCategoryName.isEmpty
        }
        return true
    }

    // MARK: - Suggestions & category resolution

    private func refreshSuggestions() {
        guard let store else {
            suggestions = []
            return
        }
        let stats = (try? store.labelStats()) ?? []
        suggestions = Autocomplete.suggestions(for: description, from: stats)
    }

    /// Determines whether the description already has a remembered category
    /// (no prompt needed) or needs the inline confirmation area.
    private func refreshCategoryArea() {
        guard let store else { return }
        guard let trimmed = DescriptionRules.trimmedIfValid(description) else {
            showCategoryArea = false
            selectedCategory = nil
            return
        }

        let key = normalize(trimmed)
        if let mapping = ((try? store.mapping(forNormalizedLabel: key)) ?? nil) {
            // Known description: no prompt needed at all.
            showCategoryArea = false
            selectedCategory = mapping.category
            return
        }

        showCategoryArea = true
        if selectedCategory == nil {
            let pairs = (try? store.mappingPairs()) ?? []
            let suggestedName = CategorySuggester.suggest(normalizedLabel: key, mappings: pairs)
                ?? CategoryRules.fallbackCategoryName
            suggestedCategoryName = suggestedName
        }
    }

    private func acceptSuggestion(_ suggestion: LabelStat) {
        description = suggestion.label
        guard let store else { return }
        if let mapping = ((try? store.mapping(forNormalizedLabel: suggestion.normalizedLabel)) ?? nil) {
            showCategoryArea = false
            selectedCategory = mapping.category
        } else {
            refreshCategoryArea()
        }
        suggestions = []
    }

    // MARK: - Save

    private func save() {
        guard let store else { return }
        guard let trimmed = DescriptionRules.trimmedIfValid(description) else { return }

        let category: Category?
        if showCategoryArea {
            if let selectedCategory {
                category = selectedCategory
            } else {
                category = try? store.category(named: suggestedCategoryName)
            }
        } else {
            // Known description path: use the remembered mapping's category.
            let key = normalize(trimmed)
            category = (((try? store.mapping(forNormalizedLabel: key)) ?? nil))?.category
        }

        guard let resolvedCategory = category else { return }

        do {
            try store.saveExpense(amountDollars: amountState.amount, label: trimmed, category: resolvedCategory)
        } catch {
            return
        }

        resetToEmptyAmountStep()
        showSaveConfirmation()
    }

    private func resetToEmptyAmountStep() {
        step = .amount
        amountState = AmountEntryState()
        description = ""
        suggestions = []
        showCategoryArea = false
        selectedCategory = nil
        suggestedCategoryName = CategoryRules.fallbackCategoryName
    }

    private func showSaveConfirmation() {
        showConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showConfirmation = false
        }
    }

    private var confirmationOverlay: some View {
        VStack {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
                .padding(24)
                .background(.thinMaterial, in: Circle())
                .accessibilityIdentifier("save-confirmation")
                .accessibilityLabel("Expense saved")
            Spacer()
        }
        .transition(.opacity)
        .allowsHitTesting(false)
    }

    // MARK: - Backgrounding (spec: 5-minute in-progress-entry expiry)

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            backgroundedAt = .now
        case .active:
            if let backgroundedAt, EntryExpiry.shouldReset(backgroundedAt: backgroundedAt, now: .now) {
                resetToEmptyAmountStep()
            }
            self.backgroundedAt = nil
        default:
            break
        }
    }
}

#Preview {
    EntryView()
}
