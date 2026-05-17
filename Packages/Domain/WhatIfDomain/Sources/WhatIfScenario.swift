import Foundation

public struct WhatIfScenario: Equatable, Sendable {
    public var monthlyIncome: Decimal
    public var monthlyExpenses: Decimal
    public var incomeDelta: Decimal
    public var expenseDelta: Decimal
    public var additionalSavings: Decimal
    public var horizonMonths: Int
    public var annualInvestmentReturnRate: Double
    public var goalAmount: Decimal?

    public init(
        monthlyIncome: Decimal = 0,
        monthlyExpenses: Decimal = 0,
        incomeDelta: Decimal = 0,
        expenseDelta: Decimal = 0,
        additionalSavings: Decimal = 0,
        horizonMonths: Int = 12,
        annualInvestmentReturnRate: Double = 0.05,
        goalAmount: Decimal? = nil
    ) {
        self.monthlyIncome = monthlyIncome
        self.monthlyExpenses = monthlyExpenses
        self.incomeDelta = incomeDelta
        self.expenseDelta = expenseDelta
        self.additionalSavings = additionalSavings
        self.horizonMonths = horizonMonths
        self.annualInvestmentReturnRate = annualInvestmentReturnRate
        self.goalAmount = goalAmount
    }
}

public struct WhatIfProjection: Equatable, Sendable {
    public var effectiveMonthlyIncome: Decimal
    public var effectiveMonthlyExpenses: Decimal
    public var monthlyNetSavings: Decimal
    public var savingsRate: Double
    public var endingBalance: Decimal
    public var totalSaved: Decimal
    public var totalInterestEarned: Decimal
    public var monthsToGoal: Int?
    public var monthlyBalances: [Decimal]

    public init(
        effectiveMonthlyIncome: Decimal,
        effectiveMonthlyExpenses: Decimal,
        monthlyNetSavings: Decimal,
        savingsRate: Double,
        endingBalance: Decimal,
        totalSaved: Decimal,
        totalInterestEarned: Decimal,
        monthsToGoal: Int?,
        monthlyBalances: [Decimal]
    ) {
        self.effectiveMonthlyIncome = effectiveMonthlyIncome
        self.effectiveMonthlyExpenses = effectiveMonthlyExpenses
        self.monthlyNetSavings = monthlyNetSavings
        self.savingsRate = savingsRate
        self.endingBalance = endingBalance
        self.totalSaved = totalSaved
        self.totalInterestEarned = totalInterestEarned
        self.monthsToGoal = monthsToGoal
        self.monthlyBalances = monthlyBalances
    }

    public static let empty = WhatIfProjection(
        effectiveMonthlyIncome: 0,
        effectiveMonthlyExpenses: 0,
        monthlyNetSavings: 0,
        savingsRate: 0,
        endingBalance: 0,
        totalSaved: 0,
        totalInterestEarned: 0,
        monthsToGoal: nil,
        monthlyBalances: []
    )
}
