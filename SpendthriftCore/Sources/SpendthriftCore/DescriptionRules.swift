import Foundation

/// Validation and normalization rules for expense descriptions.
public enum DescriptionRules {
    public static let maxLength = 40

    /// Hard-truncates `raw` to `maxLength` characters (used to prevent
    /// further input once the limit is reached).
    public static func clamp(_ raw: String) -> String {
        if raw.count <= maxLength {
            return raw
        }
        return String(raw.prefix(maxLength))
    }

    /// Trims leading/trailing whitespace and newlines from `raw`.
    ///
    /// Returns `nil` if the trimmed result is empty. The returned string,
    /// when non-nil, is guaranteed to be 1...40 characters.
    public static func trimmedIfValid(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let clamped = clamp(trimmed)
        return clamped
    }
}
