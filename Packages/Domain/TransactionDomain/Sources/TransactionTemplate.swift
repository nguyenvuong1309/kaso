import Foundation

public struct TransactionTemplate: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var kind: TransactionKind
    public var amount: Decimal
    public var category: TransactionCategory
    public var note: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        kind: TransactionKind,
        amount: Decimal,
        category: TransactionCategory,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.amount = amount
        self.category = category
        self.note = note
        self.createdAt = createdAt
    }

    public func toDraft(occurredAt: Date) -> TransactionDraft {
        TransactionDraft(
            amount: amount,
            kind: kind,
            category: category,
            occurredAt: occurredAt,
            note: note
        )
    }
}
