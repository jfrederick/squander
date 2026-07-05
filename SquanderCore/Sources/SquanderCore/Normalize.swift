import Foundation

/// Trims whitespace/newlines, case-folds, and strips diacritics.
///
/// Example: "Café " -> "cafe"
public func normalize(_ s: String) -> String {
    let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
    let folded = trimmed.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
    return folded
}
