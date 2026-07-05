import SwiftUI

/// Maps a Category's stored `colorName` string to a SwiftUI Color.
enum CategoryColor {
    static func color(named colorName: String) -> Color {
        switch colorName {
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "yellow": return .yellow
        case "teal": return .teal
        case "indigo": return .indigo
        case "brown": return .brown
        case "mint": return .mint
        case "cyan": return .cyan
        default: return .gray
        }
    }
}
