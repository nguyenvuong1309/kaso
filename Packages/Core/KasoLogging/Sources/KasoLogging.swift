import OSLog

public enum KasoLogCategory: String, Sendable {
    case app
    case persistence
    case security
}

public extension Logger {
    static func kaso(_ category: KasoLogCategory) -> Logger {
        Logger(subsystem: "com.vuongnguyen.kaso", category: category.rawValue)
    }
}
