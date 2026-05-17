import Foundation

public enum GuiltFreeBudgetHealth: String, Codable, Equatable, Sendable {
    case healthy
    case tight
    case overspending
    case incomeMissing
}

public struct GuiltFreeBudget: Equatable, Sendable {
    public var monthlyIncome: Decimal
    public var totalFixedCosts: Decimal
    public var totalSavings: Decimal
    public var totalEmergency: Decimal
    public var freeMoney: Decimal
    public var health: GuiltFreeBudgetHealth
    public var freeMoneyRatio: Double
    public var fixedCostsRatio: Double
    public var savingsRatio: Double

    public init(
        monthlyIncome: Decimal,
        totalFixedCosts: Decimal,
        totalSavings: Decimal,
        totalEmergency: Decimal,
        freeMoney: Decimal,
        health: GuiltFreeBudgetHealth,
        freeMoneyRatio: Double,
        fixedCostsRatio: Double,
        savingsRatio: Double
    ) {
        self.monthlyIncome = monthlyIncome
        self.totalFixedCosts = totalFixedCosts
        self.totalSavings = totalSavings
        self.totalEmergency = totalEmergency
        self.freeMoney = freeMoney
        self.health = health
        self.freeMoneyRatio = freeMoneyRatio
        self.fixedCostsRatio = fixedCostsRatio
        self.savingsRatio = savingsRatio
    }

    public static let empty = GuiltFreeBudget(
        monthlyIncome: 0,
        totalFixedCosts: 0,
        totalSavings: 0,
        totalEmergency: 0,
        freeMoney: 0,
        health: .incomeMissing,
        freeMoneyRatio: 0,
        fixedCostsRatio: 0,
        savingsRatio: 0
    )
}
