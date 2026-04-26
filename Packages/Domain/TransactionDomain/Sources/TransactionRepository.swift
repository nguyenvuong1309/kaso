public struct TransactionRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [Transaction]
    public var save: @Sendable (Transaction) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [Transaction],
        save: @escaping @Sendable (Transaction) async throws -> Void
    ) {
        self.fetchAll = fetchAll
        self.save = save
    }
}

public extension TransactionRepository {
    static let empty = TransactionRepository(
        fetchAll: { [] },
        save: { _ in }
    )
}
