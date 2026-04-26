import Foundation

public struct LiabilityRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [Liability]
    public var save: @Sendable (Liability) async throws -> Void
    public var delete: @Sendable (UUID) async throws -> Void
    public var replaceAutoTracked: @Sendable ([Liability]) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [Liability],
        save: @escaping @Sendable (Liability) async throws -> Void,
        delete: @escaping @Sendable (UUID) async throws -> Void,
        replaceAutoTracked: @escaping @Sendable ([Liability]) async throws -> Void = { _ in }
    ) {
        self.fetchAll = fetchAll
        self.save = save
        self.delete = delete
        self.replaceAutoTracked = replaceAutoTracked
    }
}

public extension LiabilityRepository {
    static let empty = LiabilityRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { _ in },
        replaceAutoTracked: { _ in }
    )
}
