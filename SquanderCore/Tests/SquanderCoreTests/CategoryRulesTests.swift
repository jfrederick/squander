import Testing
@testable import SquanderCore

@Suite("CategoryRules")
struct CategoryRulesTests {
    @Test("seededCategories has exactly the 12 expected entries in order")
    func seededCategoriesExactSet() {
        let expected: [(name: String, colorName: String, iconName: String)] = [
            (name: "Food & Drink", colorName: "orange", iconName: "fork.knife"),
            (name: "Groceries", colorName: "green", iconName: "cart.fill"),
            (name: "Transport", colorName: "blue", iconName: "car.fill"),
            (name: "Shopping", colorName: "pink", iconName: "bag.fill"),
            (name: "Entertainment", colorName: "purple", iconName: "film.fill"),
            (name: "Health", colorName: "red", iconName: "heart.fill"),
            (name: "Home", colorName: "teal", iconName: "house.fill"),
            (name: "Travel", colorName: "indigo", iconName: "airplane"),
            (name: "Subscriptions", colorName: "cyan", iconName: "arrow.triangle.2.circlepath"),
            (name: "Gifts", colorName: "yellow", iconName: "gift.fill"),
            (name: "Personal Care", colorName: "mint", iconName: "sparkles"),
            (name: "Other", colorName: "gray", iconName: "ellipsis.circle.fill")
        ]

        #expect(CategoryRules.seededCategories.count == 12)
        for (actual, exp) in zip(CategoryRules.seededCategories, expected) {
            #expect(actual.name == exp.name)
            #expect(actual.colorName == exp.colorName)
            #expect(actual.iconName == exp.iconName)
        }
    }

    @Test("canCreate is true below the cap")
    func canCreateBelowCap() {
        #expect(CategoryRules.canCreate(existingCount: 29))
        #expect(CategoryRules.canCreate(existingCount: 0))
    }

    @Test("canCreate is false at or above the cap")
    func canCreateAtCap() {
        #expect(!CategoryRules.canCreate(existingCount: 30))
        #expect(!CategoryRules.canCreate(existingCount: 31))
    }

    @Test("maxCount constant is 30")
    func maxCountConstant() {
        #expect(CategoryRules.maxCount == 30)
    }

    @Test("fallbackCategoryName is Other")
    func fallbackCategoryName() {
        #expect(CategoryRules.fallbackCategoryName == "Other")
    }

    @Test("isDuplicateName detects exact match")
    func duplicateExactMatch() {
        #expect(CategoryRules.isDuplicateName("Food & Drink", existing: ["Food & Drink", "Transport"]))
    }

    @Test("isDuplicateName is case-insensitive")
    func duplicateCaseInsensitive() {
        #expect(CategoryRules.isDuplicateName("food & drink", existing: ["Food & Drink"]))
        #expect(CategoryRules.isDuplicateName("FOOD & DRINK", existing: ["Food & Drink"]))
    }

    @Test("isDuplicateName is diacritic-insensitive and trims whitespace")
    func duplicateNormalizedComparison() {
        #expect(CategoryRules.isDuplicateName(" Café ", existing: ["cafe"]))
    }

    @Test("isDuplicateName returns false for a genuinely new name")
    func notDuplicate() {
        #expect(!CategoryRules.isDuplicateName("Pets", existing: ["Food & Drink", "Transport"]))
    }
}
