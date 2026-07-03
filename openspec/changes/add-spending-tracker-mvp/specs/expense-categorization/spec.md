# expense-categorization

## ADDED Requirements

### Requirement: Bounded category set
The app SHALL maintain a single flat list of categories with at least 10 and at most 30 entries. On first launch the app SHALL seed a default set of 12 categories: Food & Drink, Groceries, Transport, Shopping, Entertainment, Health, Home, Travel, Subscriptions, Gifts, Personal Care, Other. Each category SHALL have a unique name and a color/icon for display.

#### Scenario: Defaults seeded on first launch
- **WHEN** the app launches for the first time
- **THEN** the 12 default categories exist and are available for assignment

#### Scenario: Category cap enforced
- **WHEN** 30 categories exist and the user attempts to create another
- **THEN** creation is refused with an explanation that the limit is 30

#### Scenario: Duplicate names rejected
- **WHEN** the user attempts to create a category named "Food & Drink" (any letter case) and it already exists
- **THEN** creation is refused

### Requirement: Description-to-category memory
The app SHALL remember the category confirmed for each normalized description (trimmed, case-folded, diacritic-folded). When a new expense's description exactly matches a remembered description, the app SHALL assign the remembered category automatically without prompting.

#### Scenario: Known description auto-categorized
- **WHEN** "electrolytes" was previously confirmed as "Health" and the user saves a new expense described "electrolytes"
- **THEN** the expense is assigned "Health" with no category prompt

#### Scenario: Normalization applies to matching
- **WHEN** "Cafe" was previously confirmed as "Food & Drink" and the user enters "cafe "
- **THEN** the expense is assigned "Food & Drink" with no category prompt

#### Scenario: Memory updates on correction
- **WHEN** the user edits an expense described "cafe" and changes its category from "Food & Drink" to "Entertainment"
- **THEN** the remembered category for "cafe" becomes "Entertainment" for future expenses
- **AND** previously saved "cafe" expenses keep their existing category

### Requirement: Category suggestion for new descriptions
When a description has no remembered category, the app SHALL suggest the most likely category using on-device heuristics (e.g., keyword and token similarity to remembered descriptions), and SHALL require the user to confirm or change it before the expense is saved. Confirming SHALL record the description→category mapping.

#### Scenario: New description prompts with a suggestion
- **WHEN** the user enters the never-before-seen description "tacos"
- **THEN** a category picker is shown with a single suggested category preselected

#### Scenario: One-tap confirm
- **WHEN** the suggestion is shown and the user taps Save/Confirm
- **THEN** the expense is saved with the suggested category
- **AND** the mapping "tacos" → that category is remembered

#### Scenario: Override the suggestion
- **WHEN** the suggestion is "Shopping" but the user selects "Groceries" instead
- **THEN** the expense is saved with "Groceries" and "Groceries" is remembered for that description

#### Scenario: No confident suggestion falls back to Other
- **WHEN** no heuristic produces a confident match for a new description
- **THEN** the picker is shown with "Other" preselected

### Requirement: Creating a category during entry
The category picker SHALL allow creating a new category inline, subject to the 30-category cap, so the entry flow is never blocked by category management.

#### Scenario: Inline creation
- **WHEN** the user is on the category picker with fewer than 30 categories and chooses "New category", entering "Pets"
- **THEN** "Pets" is created, selected for the expense, and available for all future expenses

#### Scenario: Inline creation refused at cap
- **WHEN** 30 categories exist and the user chooses "New category" in the picker
- **THEN** the app explains the 30-category limit and prompts the user to pick an existing category
