public struct BudgetRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [Budget]
    public var saveAll: @Sendable ([Budget]) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [Budget],
        saveAll: @escaping @Sendable ([Budget]) async throws -> Void
    ) {
        self.fetchAll = fetchAll
        self.saveAll = saveAll
    }
}

public extension BudgetRepository {
    static let empty = BudgetRepository(
        fetchAll: { [] },
        saveAll: { _ in }
    )
}
