import Foundation

/// Rules governing the bounded set of expense categories.
public enum CategoryRules {
    public static let maxCount = 30
    public static let fallbackCategoryName = "Other"

    /// The 12 default categories seeded on first launch, in display order.
    public static let seededCategories: [(name: String, colorName: String, iconName: String)] = [
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

    /// Whether a new category can be created given the current count.
    public static func canCreate(existingCount: Int) -> Bool {
        existingCount < maxCount
    }

    /// Whether `name` duplicates an existing category name (compared via `normalize()`).
    public static func isDuplicateName(_ name: String, existing: [String]) -> Bool {
        let normalizedName = normalize(name)
        return existing.contains { normalize($0) == normalizedName }
    }
}
