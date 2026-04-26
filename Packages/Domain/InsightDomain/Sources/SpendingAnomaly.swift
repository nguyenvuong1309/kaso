import Foundation
import TransactionDomain

public enum SpendingAnomalyKind: Equatable, Sendable {
    case largeTransaction
    case categorySpike
}

public struct SpendingAnomaly: Equatable, Identifiable, Sendable {
    public let id: String
    public var kind: SpendingAnomalyKind
    public var category: TransactionCategory
    public var amount: Decimal
    public var baselineAmount: Decimal
    public var occurredAt: Date
    public var transactionID: UUID?

    public init(
        id: String,
        kind: SpendingAnomalyKind,
        category: TransactionCategory,
        amount: Decimal,
        baselineAmount: Decimal,
        occurredAt: Date,
        transactionID: UUID? = nil
    ) {
        self.id = id
        self.kind = kind
        self.category = category
        self.amount = amount
        self.baselineAmount = baselineAmount
        self.occurredAt = occurredAt
        self.transactionID = transactionID
    }

    public var ratio: Decimal {
        guard baselineAmount > 0 else {
            return 0
        }

        return amount / baselineAmount
    }
}
