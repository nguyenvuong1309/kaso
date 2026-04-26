import Foundation

public struct SavingGoalProgress: Codable, Equatable, Sendable {
    public var currentAmount: Decimal
    public var targetAmount: Decimal

    public init(
        currentAmount: Decimal,
        targetAmount: Decimal
    ) {
        self.currentAmount = currentAmount
        self.targetAmount = targetAmount
    }

    public var remainingAmount: Decimal {
        guard currentAmount < targetAmount else {
            return 0
        }

        return targetAmount - currentAmount
    }

    public var fraction: Double {
        guard targetAmount > 0 else {
            return 0
        }

        let current = NSDecimalNumber(decimal: currentAmount).doubleValue
        let target = NSDecimalNumber(decimal: targetAmount).doubleValue
        return min(max(current / target, 0), 1)
    }

    public var percent: Double {
        fraction * 100
    }

    public var isCompleted: Bool {
        targetAmount > 0 && currentAmount >= targetAmount
    }
}
