import Foundation

public struct RoundUpRepository: Sendable {
    public var loadRule: @Sendable () async throws -> RoundUpRule
    public var saveRule: @Sendable (RoundUpRule) async throws -> Void
    public var fetchEntries: @Sendable () async throws -> [RoundUpEntry]
    public var saveEntry: @Sendable (RoundUpEntry) async throws -> Void
    public var deleteEntry: @Sendable (UUID) async throws -> Void
    public var clearAll: @Sendable () async throws -> Void

    public init(
        loadRule: @escaping @Sendable () async throws -> RoundUpRule,
        saveRule: @escaping @Sendable (RoundUpRule) async throws -> Void,
        fetchEntries: @escaping @Sendable () async throws -> [RoundUpEntry],
        saveEntry: @escaping @Sendable (RoundUpEntry) async throws -> Void,
        deleteEntry: @escaping @Sendable (UUID) async throws -> Void,
        clearAll: @escaping @Sendable () async throws -> Void
    ) {
        self.loadRule = loadRule
        self.saveRule = saveRule
        self.fetchEntries = fetchEntries
        self.saveEntry = saveEntry
        self.deleteEntry = deleteEntry
        self.clearAll = clearAll
    }
}

public extension RoundUpRepository {
    static let empty = RoundUpRepository(
        loadRule: { RoundUpRule() },
        saveRule: { _ in },
        fetchEntries: { [] },
        saveEntry: { _ in },
        deleteEntry: { _ in },
        clearAll: {}
    )
}
