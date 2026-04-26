import Foundation
import TransactionDomain

public enum BudgetStatus: Equatable, Sendable {
    case healthy
    case nearLimit
    case exceeded
}

public struct Budget: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var category: TransactionCategory
    public var monthlyLimit: Decimal
    public var spent: Decimal

    public init(
        id: UUID = UUID(),
        category: TransactionCategory,
        monthlyLimit: Decimal,
        spent: Decimal = Decimal(0)
    ) {
        self.id = id
        self.category = category
        self.monthlyLimit = monthlyLimit
        self.spent = spent
    }

    public var remaining: Decimal {
        monthlyLimit - spent
    }

    public var utilization: Double {
        guard monthlyLimit > Decimal(0) else {
            return 0
        }

        return NSDecimalNumber(decimal: spent).doubleValue
            / NSDecimalNumber(decimal: monthlyLimit).doubleValue
    }

    public var status: BudgetStatus {
        if utilization >= 1 {
            return .exceeded
        }

        if utilization >= 0.8 {
            return .nearLimit
        }

        return .healthy
    }
}
