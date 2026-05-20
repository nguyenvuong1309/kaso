import Foundation

/// A single saved reflection session.
///
/// Stores only `topic`, the user's optional free-form note, and `recordedAt`.
/// Notes stay on-device and the encrypted store treats them as sensitive.
public struct TherapistReflection: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let topic: TherapistTopic
    public let note: String?
    public let recordedAt: Date

    public init(
        id: UUID = UUID(),
        topic: TherapistTopic,
        note: String? = nil,
        recordedAt: Date = Date()
    ) {
        self.id = id
        self.topic = topic
        self.note = note
        self.recordedAt = recordedAt
    }
}

public struct TherapistRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [TherapistReflection]
    public var save: @Sendable (TherapistReflection) async throws -> Void
    public var delete: @Sendable (UUID) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [TherapistReflection],
        save: @escaping @Sendable (TherapistReflection) async throws -> Void,
        delete: @escaping @Sendable (UUID) async throws -> Void
    ) {
        self.fetchAll = fetchAll
        self.save = save
        self.delete = delete
    }
}

public extension TherapistRepository {
    static let empty = TherapistRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { _ in }
    )
}
