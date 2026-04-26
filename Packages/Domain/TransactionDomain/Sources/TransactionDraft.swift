import Foundation

public enum TransactionValidationError: Error, Equatable, Sendable {
    case amountMustBePositive
}

public struct TransactionDraft: Equatable, Sendable {
    public var amount: Decimal
    public var kind: TransactionKind
    public var category: TransactionCategory
    public var occurredAt: Date
    public var note: String?
    public var receiptImageIdentifier: String?

    public init(
        amount: Decimal,
        kind: TransactionKind,
        category: TransactionCategory,
        occurredAt: Date,
        note: String? = nil,
        receiptImageIdentifier: String? = nil
    ) {
        self.amount = amount
        self.kind = kind
        self.category = category
        self.occurredAt = occurredAt
        self.note = note
        self.receiptImageIdentifier = receiptImageIdentifier
    }

    public func validated(id: @autoclosure () -> UUID = UUID()) throws -> Transaction {
        guard amount > Decimal(0) else {
            throw TransactionValidationError.amountMustBePositive
        }

        return Transaction(
            id: id(),
            amount: amount,
            kind: kind,
            category: category,
            occurredAt: occurredAt,
            note: note,
            receiptImageIdentifier: receiptImageIdentifier
        )
    }
}
