import Foundation

public enum RetirementSimulationStatus: String, Codable, Equatable, Sendable {
    case ready
    case reachable
    case unreachable
}

public struct RetirementSimulation: Equatable, Sendable {
    public let monthlyIncome: Decimal
    public let monthlyExpense: Decimal
    public let monthlyContribution: Decimal
    public let currentSavings: Decimal
    public let annualReturnRate: Decimal
    public let targetAnnualExpenseMultiplier: Int
    public let targetAmount: Decimal
    public let projectedMonthCount: Int?
    public let status: RetirementSimulationStatus

    public init(
        monthlyIncome: Decimal,
        monthlyExpense: Decimal,
        monthlyContribution: Decimal,
        currentSavings: Decimal,
        annualReturnRate: Decimal,
        targetAnnualExpenseMultiplier: Int,
        targetAmount: Decimal,
        projectedMonthCount: Int?,
        status: RetirementSimulationStatus
    ) {
        self.monthlyIncome = monthlyIncome
        self.monthlyExpense = monthlyExpense
        self.monthlyContribution = monthlyContribution
        self.currentSavings = currentSavings
        self.annualReturnRate = annualReturnRate
        self.targetAnnualExpenseMultiplier = targetAnnualExpenseMultiplier
        self.targetAmount = targetAmount
        self.projectedMonthCount = projectedMonthCount
        self.status = status
    }
}

public enum RetirementSimulator {
    public static func simulate(
        monthlyIncome: Decimal,
        monthlyExpense: Decimal,
        currentSavings: Decimal = 0,
        annualReturnRate: Decimal = Decimal(string: "0.05") ?? 0.05,
        targetAnnualExpenseMultiplier: Int = 25,
        maximumProjectionYearCount: Int = 80
    ) -> RetirementSimulation? {
        guard monthlyExpense > 0, targetAnnualExpenseMultiplier > 0 else {
            return nil
        }

        let safeCurrentSavings = max(currentSavings, 0)
        let monthlyContribution = max(monthlyIncome - monthlyExpense, 0)
        let targetAmount = monthlyExpense * 12 * Decimal(targetAnnualExpenseMultiplier)

        if safeCurrentSavings >= targetAmount {
            return RetirementSimulation(
                monthlyIncome: monthlyIncome,
                monthlyExpense: monthlyExpense,
                monthlyContribution: monthlyContribution,
                currentSavings: safeCurrentSavings,
                annualReturnRate: annualReturnRate,
                targetAnnualExpenseMultiplier: targetAnnualExpenseMultiplier,
                targetAmount: targetAmount,
                projectedMonthCount: 0,
                status: .ready
            )
        }

        let projectedMonthCount = projectedMonths(
            currentSavings: safeCurrentSavings,
            monthlyContribution: monthlyContribution,
            annualReturnRate: annualReturnRate,
            targetAmount: targetAmount,
            maximumMonthCount: maximumProjectionYearCount * 12
        )

        return RetirementSimulation(
            monthlyIncome: monthlyIncome,
            monthlyExpense: monthlyExpense,
            monthlyContribution: monthlyContribution,
            currentSavings: safeCurrentSavings,
            annualReturnRate: annualReturnRate,
            targetAnnualExpenseMultiplier: targetAnnualExpenseMultiplier,
            targetAmount: targetAmount,
            projectedMonthCount: projectedMonthCount,
            status: projectedMonthCount == nil ? .unreachable : .reachable
        )
    }

    private static func projectedMonths(
        currentSavings: Decimal,
        monthlyContribution: Decimal,
        annualReturnRate: Decimal,
        targetAmount: Decimal,
        maximumMonthCount: Int
    ) -> Int? {
        guard monthlyContribution > 0 || annualReturnRate > 0 else {
            return nil
        }

        let monthlyReturnRate = NSDecimalNumber(decimal: annualReturnRate / 12).doubleValue
        var projectedSavings = NSDecimalNumber(decimal: currentSavings).doubleValue
        let monthlyContributionValue = NSDecimalNumber(decimal: monthlyContribution).doubleValue
        let targetValue = NSDecimalNumber(decimal: targetAmount).doubleValue

        for month in 1...maximumMonthCount {
            projectedSavings = projectedSavings * (1 + monthlyReturnRate) + monthlyContributionValue
            if projectedSavings >= targetValue {
                return month
            }
        }

        return nil
    }
}
