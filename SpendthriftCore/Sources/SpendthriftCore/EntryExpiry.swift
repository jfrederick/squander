import Foundation

/// Determines whether a partially entered expense should be reset after
/// the app returns from the background.
public enum EntryExpiry {
    /// Idle timeout in seconds after which in-progress entry is discarded.
    public static let timeout: TimeInterval = 300

    /// Whether the elapsed time between `backgroundedAt` and `now` strictly
    /// exceeds the timeout (5 minutes).
    public static func shouldReset(backgroundedAt: Date, now: Date) -> Bool {
        now.timeIntervalSince(backgroundedAt) > timeout
    }
}
