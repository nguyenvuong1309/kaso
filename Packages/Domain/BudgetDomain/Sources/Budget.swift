import Foundation
import TransactionDomain

public enum BudgetStatus: Equatable, Sendable {
    case healthy
    case nearLimit
    case exceeded
}

public struct Budget: Identifiable, Codable, Equatable, Sendable {
    public var category: TransactionCategory
    public var monthlyLimit: Decimal
    public var spent: Decimal

    public var id: String {
        category.id
    }

    public init(
        category: TransactionCategory,
        monthlyLimit: Decimal,
        spent: Decimal = Decimal(0)
    ) {
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

public extension Sequence where Element == Budget {
    func applyingMonthlySpending(
        from transactions: [Transaction],
        containing date: Date,
        calendar: Calendar = .current
    ) -> [Budget] {
        map { budget in
            var updatedBudget = budget
            updatedBudget.spent = transactions
                .filter {
                    $0.kind == .expense
                        && $0.category == budget.category
                        && calendar.isDate($0.occurredAt, equalTo: date, toGranularity: .month)
                }
                .reduce(Decimal(0)) { $0 + $1.amount }
            return updatedBudget
        }
    }
}
