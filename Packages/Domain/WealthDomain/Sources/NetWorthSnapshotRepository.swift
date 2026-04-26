import Foundation

public struct NetWorthSnapshotRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [NetWorthSnapshot]
    public var save: @Sendable (NetWorthSnapshot) async throws -> Void
    public var prune: @Sendable (Date) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [NetWorthSnapshot],
        save: @escaping @Sendable (NetWorthSnapshot) async throws -> Void,
        prune: @escaping @Sendable (Date) async throws -> Void = { _ in }
    ) {
        self.fetchAll = fetchAll
        self.save = save
        self.prune = prune
    }
}

public extension NetWorthSnapshotRepository {
    static let empty = NetWorthSnapshotRepository(
        fetchAll: { [] },
        save: { _ in },
        prune: { _ in }
    )
}
