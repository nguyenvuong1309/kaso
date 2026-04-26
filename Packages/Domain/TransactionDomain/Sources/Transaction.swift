import Foundation

public enum TransactionKind: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case income
    case expense

    public var id: String {
        rawValue
    }

    public var nameKey: String {
        "transaction.kind.\(rawValue)"
    }
}

public struct Transaction: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var amount: Decimal
    public var kind: TransactionKind
    public var category: TransactionCategory
    public var occurredAt: Date
    public var note: String?
    public var receiptImageIdentifier: String?

    public init(
        id: UUID = UUID(),
        amount: Decimal,
        kind: TransactionKind,
        category: TransactionCategory,
        occurredAt: Date,
        note: String? = nil,
        receiptImageIdentifier: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.kind = kind
        self.category = category
        self.occurredAt = occurredAt
        self.note = note
        self.receiptImageIdentifier = receiptImageIdentifier
    }
}

public extension Transaction {
    static func sampleExpense(
        id: UUID = UUID(),
        amount: Decimal = 45_000,
        occurredAt: Date = Date()
    ) -> Transaction {
        Transaction(
            id: id,
            amount: amount,
            kind: .expense,
            category: .food,
            occurredAt: occurredAt,
            note: "sample.transaction.note"
        )
    }
}
