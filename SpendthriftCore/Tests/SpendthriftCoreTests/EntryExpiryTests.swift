import Testing
import Foundation
@testable import SpendthriftCore

@Suite("EntryExpiry")
struct EntryExpiryTests {
    static func date(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let d = formatter.date(from: iso) else {
            fatalError("bad date \(iso)")
        }
        return d
    }

    @Test("exactly 300 seconds does not trigger reset")
    func exactly300SecondsNoReset() {
        let backgroundedAt = Self.date("2026-07-04T12:00:00Z")
        let now = backgroundedAt.addingTimeInterval(300)
        #expect(!EntryExpiry.shouldReset(backgroundedAt: backgroundedAt, now: now))
    }

    @Test("301 seconds triggers reset")
    func the301SecondsTriggersReset() {
        let backgroundedAt = Self.date("2026-07-04T12:00:00Z")
        let now = backgroundedAt.addingTimeInterval(301)
        #expect(EntryExpiry.shouldReset(backgroundedAt: backgroundedAt, now: now))
    }

    @Test("well under timeout does not reset")
    func wellUnderTimeoutNoReset() {
        let backgroundedAt = Self.date("2026-07-04T12:00:00Z")
        let now = backgroundedAt.addingTimeInterval(60)
        #expect(!EntryExpiry.shouldReset(backgroundedAt: backgroundedAt, now: now))
    }

    @Test("well over timeout resets")
    func wellOverTimeoutResets() {
        let backgroundedAt = Self.date("2026-07-04T12:00:00Z")
        let now = backgroundedAt.addingTimeInterval(600)
        #expect(EntryExpiry.shouldReset(backgroundedAt: backgroundedAt, now: now))
    }

    @Test("zero elapsed time does not reset")
    func zeroElapsedNoReset() {
        let backgroundedAt = Self.date("2026-07-04T12:00:00Z")
        #expect(!EntryExpiry.shouldReset(backgroundedAt: backgroundedAt, now: backgroundedAt))
    }

    @Test("timeout constant is 300 seconds")
    func timeoutConstant() {
        #expect(EntryExpiry.timeout == 300)
    }
}
