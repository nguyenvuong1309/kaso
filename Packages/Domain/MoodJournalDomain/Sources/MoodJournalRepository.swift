import Foundation

public struct MoodJournalRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [MoodEntry]
    public var save: @Sendable (MoodEntry) async throws -> Void
    public var delete: @Sendable (UUID) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [MoodEntry],
        save: @escaping @Sendable (MoodEntry) async throws -> Void,
        delete: @escaping @Sendable (UUID) async throws -> Void
    ) {
        self.fetchAll = fetchAll
        self.save = save
        self.delete = delete
    }
}

public extension MoodJournalRepository {
    static let empty = MoodJournalRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { _ in }
    )
}
