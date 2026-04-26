import Foundation

public struct EmergencyFundRecommendation: Equatable, Sendable {
    public let monthlyExpense: Decimal
    public let targetMonthCount: Int
    public let recommendedAmount: Decimal
    public let currentAmount: Decimal
    public let remainingAmount: Decimal
    public let coverageMonthCount: Double
    public let monthlyTopUpAmount: Decimal

    public init(
        monthlyExpense: Decimal,
        targetMonthCount: Int,
        recommendedAmount: Decimal,
        currentAmount: Decimal,
        remainingAmount: Decimal,
        coverageMonthCount: Double,
        monthlyTopUpAmount: Decimal
    ) {
        self.monthlyExpense = monthlyExpense
        self.targetMonthCount = targetMonthCount
        self.recommendedAmount = recommendedAmount
        self.currentAmount = currentAmount
        self.remainingAmount = remainingAmount
        self.coverageMonthCount = coverageMonthCount
        self.monthlyTopUpAmount = monthlyTopUpAmount
    }
}

public enum EmergencyFundPlanner {
    public static func recommendation(
        monthlyExpense: Decimal,
        currentAmount: Decimal = 0,
        targetMonthCount: Int = 6,
        buildMonthCount: Int = 12
    ) -> EmergencyFundRecommendation? {
        guard monthlyExpense > 0, targetMonthCount > 0, buildMonthCount > 0 else {
            return nil
        }

        let safeCurrentAmount = max(currentAmount, 0)
        let recommendedAmount = monthlyExpense * Decimal(targetMonthCount)
        let remainingAmount = max(recommendedAmount - safeCurrentAmount, 0)
        let coverageMonthCount = NSDecimalNumber(
            decimal: safeCurrentAmount / monthlyExpense
        ).doubleValue

        return EmergencyFundRecommendation(
            monthlyExpense: monthlyExpense,
            targetMonthCount: targetMonthCount,
            recommendedAmount: recommendedAmount,
            currentAmount: safeCurrentAmount,
            remainingAmount: remainingAmount,
            coverageMonthCount: min(coverageMonthCount, Double(targetMonthCount)),
            monthlyTopUpAmount: remainingAmount / Decimal(buildMonthCount)
        )
    }
}
