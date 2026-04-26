public struct TransactionCategoryRepository: Sendable {
    public var fetchCustomCategories: @Sendable () async throws -> [TransactionCategory]
    public var saveCustomCategories: @Sendable ([TransactionCategory]) async throws -> Void

    public init(
        fetchCustomCategories: @escaping @Sendable () async throws -> [TransactionCategory],
        saveCustomCategories: @escaping @Sendable ([TransactionCategory]) async throws -> Void
    ) {
        self.fetchCustomCategories = fetchCustomCategories
        self.saveCustomCategories = saveCustomCategories
    }
}

public extension TransactionCategoryRepository {
    static let empty = TransactionCategoryRepository(
        fetchCustomCategories: { [] },
        saveCustomCategories: { _ in }
    )
}
