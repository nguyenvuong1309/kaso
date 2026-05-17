import Foundation

public struct GuiltFreeBudgetConfiguration: Codable, Equatable, Sendable {
    public var monthlyIncome: Decimal
    public var monthlySavingsTarget: Decimal
    public var emergencyFundMonthlyContribution: Decimal
    public var fixedCosts: [GuiltFreeFixedCost]
    public var updatedAt: Date

    public init(
        monthlyIncome: Decimal = 0,
        monthlySavingsTarget: Decimal = 0,
        emergencyFundMonthlyContribution: Decimal = 0,
        fixedCosts: [GuiltFreeFixedCost] = [],
        updatedAt: Date = Date()
    ) {
        self.monthlyIncome = monthlyIncome
        self.monthlySavingsTarget = monthlySavingsTarget
        self.emergencyFundMonthlyContribution = emergencyFundMonthlyContribution
        self.fixedCosts = fixedCosts
        self.updatedAt = updatedAt
    }
}
