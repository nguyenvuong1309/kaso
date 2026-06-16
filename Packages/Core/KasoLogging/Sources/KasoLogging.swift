import Foundation
import OSLog

public enum KasoLogCategory: String, Sendable {
    case app
    case persistence
    case security
}

public extension Logger {
    /// Logs are tagged with the running target's bundle identifier so dev and
    /// prod builds (different bundle IDs) surface as distinct subsystems in
    /// Console / the unified logging system.
    static func kaso(_ category: KasoLogCategory) -> Logger {
        let subsystem = Bundle.main.bundleIdentifier ?? "com.vuongnguyen.kaso"
        return Logger(subsystem: subsystem, category: category.rawValue)
    }
}
