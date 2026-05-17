import Foundation

public struct RegretRatingRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [RegretRating]
    public var save: @Sendable (RegretRating) async throws -> Void
    public var delete: @Sendable (UUID) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [RegretRating],
        save: @escaping @Sendable (RegretRating) async throws -> Void,
        delete: @escaping @Sendable (UUID) async throws -> Void
    ) {
        self.fetchAll = fetchAll
        self.save = save
        self.delete = delete
    }
}

public extension RegretRatingRepository {
    static let empty = RegretRatingRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { _ in }
    )
}

public struct RegretReminderContextClient: Sendable {
    public var fetchCandidates: @Sendable () async throws -> [RegretReminderInput]

    public init(fetchCandidates: @escaping @Sendable () async throws -> [RegretReminderInput]) {
        self.fetchCandidates = fetchCandidates
    }
}

public extension RegretReminderContextClient {
    static let empty = RegretReminderContextClient(fetchCandidates: { [] })
}
