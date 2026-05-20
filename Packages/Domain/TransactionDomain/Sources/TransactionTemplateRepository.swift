import Foundation

public struct TransactionTemplateRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [TransactionTemplate]
    public var save: @Sendable (TransactionTemplate) async throws -> Void
    public var delete: @Sendable (UUID) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [TransactionTemplate],
        save: @escaping @Sendable (TransactionTemplate) async throws -> Void,
        delete: @escaping @Sendable (UUID) async throws -> Void
    ) {
        self.fetchAll = fetchAll
        self.save = save
        self.delete = delete
    }
}

public extension TransactionTemplateRepository {
    static let empty = TransactionTemplateRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { _ in }
    )

    static let preview = TransactionTemplateRepository(
        fetchAll: {
            [
                TransactionTemplate(
                    name: "Cà phê sáng",
                    kind: .expense,
                    amount: 35_000,
                    category: .food,
                    note: "Highlands"
                ),
                TransactionTemplate(
                    name: "Grab đi làm",
                    kind: .expense,
                    amount: 65_000,
                    category: .transport
                ),
                TransactionTemplate(
                    name: "Lương tháng",
                    kind: .income,
                    amount: 20_000_000,
                    category: .salary
                ),
            ]
        },
        save: { _ in },
        delete: { _ in }
    )
}
