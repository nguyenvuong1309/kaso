import Foundation

public struct AssetRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [Asset]
    public var save: @Sendable (Asset) async throws -> Void
    public var delete: @Sendable (UUID) async throws -> Void
    public var replaceAutoTracked: @Sendable ([Asset]) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [Asset],
        save: @escaping @Sendable (Asset) async throws -> Void,
        delete: @escaping @Sendable (UUID) async throws -> Void,
        replaceAutoTracked: @escaping @Sendable ([Asset]) async throws -> Void = { _ in }
    ) {
        self.fetchAll = fetchAll
        self.save = save
        self.delete = delete
        self.replaceAutoTracked = replaceAutoTracked
    }
}

public extension AssetRepository {
    static let empty = AssetRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { _ in },
        replaceAutoTracked: { _ in }
    )
}
