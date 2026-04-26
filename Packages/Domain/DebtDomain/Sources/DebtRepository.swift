import Foundation

public struct DebtRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [Debt]
    public var save: @Sendable (Debt) async throws -> Void
    public var delete: @Sendable (UUID) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [Debt],
        save: @escaping @Sendable (Debt) async throws -> Void,
        delete: @escaping @Sendable (UUID) async throws -> Void
    ) {
        self.fetchAll = fetchAll
        self.save = save
        self.delete = delete
    }
}

public extension DebtRepository {
    static let empty = DebtRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { _ in }
    )
}
