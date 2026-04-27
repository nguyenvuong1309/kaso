import Foundation

public struct PhantomExpenseRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [PhantomExpense]
    public var save: @Sendable (PhantomExpense) async throws -> Void
    public var delete: @Sendable (UUID) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [PhantomExpense],
        save: @escaping @Sendable (PhantomExpense) async throws -> Void,
        delete: @escaping @Sendable (UUID) async throws -> Void
    ) {
        self.fetchAll = fetchAll
        self.save = save
        self.delete = delete
    }
}

public extension PhantomExpenseRepository {
    static let empty = PhantomExpenseRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { _ in }
    )
}
