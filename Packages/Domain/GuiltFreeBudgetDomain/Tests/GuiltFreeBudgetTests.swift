import Foundation
import Testing
@testable import GuiltFreeBudgetDomain

// MARK: - GuiltFreeBudget value type

@Test("empty budget has zeroed fields and income-missing health")
func emptyBudgetIsZeroed() {
    let budget = GuiltFreeBudget.empty

    #expect(budget.monthlyIncome == 0)
    #expect(budget.totalFixedCosts == 0)
    #expect(budget.totalSavings == 0)
    #expect(budget.totalEmergency == 0)
    #expect(budget.freeMoney == 0)
    #expect(budget.health == .incomeMissing)
    #expect(budget.freeMoneyRatio == 0)
    #expect(budget.fixedCostsRatio == 0)
    #expect(budget.savingsRatio == 0)
}

@Test("init stores all provided fields")
func budgetInitStoresFields() {
    let budget = GuiltFreeBudget(
        monthlyIncome: 30_000_000,
        totalFixedCosts: 10_000_000,
        totalSavings: 5_000_000,
        totalEmergency: 2_000_000,
        freeMoney: 13_000_000,
        health: .healthy,
        freeMoneyRatio: 0.4,
        fixedCostsRatio: 0.33,
        savingsRatio: 0.23
    )

    #expect(budget.monthlyIncome == 30_000_000)
    #expect(budget.totalFixedCosts == 10_000_000)
    #expect(budget.totalSavings == 5_000_000)
    #expect(budget.totalEmergency == 2_000_000)
    #expect(budget.freeMoney == 13_000_000)
    #expect(budget.health == .healthy)
    #expect(budget.freeMoneyRatio == 0.4)
    #expect(budget.fixedCostsRatio == 0.33)
    #expect(budget.savingsRatio == 0.23)
}

@Test("two budgets with identical fields are equal")
func budgetEquatableEqual() {
    let lhs = GuiltFreeBudget(
        monthlyIncome: 10,
        totalFixedCosts: 1,
        totalSavings: 2,
        totalEmergency: 3,
        freeMoney: 4,
        health: .tight,
        freeMoneyRatio: 0.1,
        fixedCostsRatio: 0.2,
        savingsRatio: 0.3
    )
    let rhs = GuiltFreeBudget(
        monthlyIncome: 10,
        totalFixedCosts: 1,
        totalSavings: 2,
        totalEmergency: 3,
        freeMoney: 4,
        health: .tight,
        freeMoneyRatio: 0.1,
        fixedCostsRatio: 0.2,
        savingsRatio: 0.3
    )

    #expect(lhs == rhs)
}

@Test("budgets differing in health are not equal")
func budgetEquatableDiffers() {
    let base = GuiltFreeBudget.empty
    var other = GuiltFreeBudget.empty
    other.health = .overspending

    #expect(base != other)
}

// MARK: - GuiltFreeBudgetHealth

@Test("budget health raw values round-trip through Codable")
func healthCodableRoundTrip() throws {
    let cases: [GuiltFreeBudgetHealth] = [.healthy, .tight, .overspending, .incomeMissing]
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    for value in cases {
        let data = try encoder.encode(value)
        let decoded = try decoder.decode(GuiltFreeBudgetHealth.self, from: data)
        #expect(decoded == value)
    }
}

@Test("budget health raw values are stable strings")
func healthRawValues() {
    #expect(GuiltFreeBudgetHealth.healthy.rawValue == "healthy")
    #expect(GuiltFreeBudgetHealth.tight.rawValue == "tight")
    #expect(GuiltFreeBudgetHealth.overspending.rawValue == "overspending")
    #expect(GuiltFreeBudgetHealth.incomeMissing.rawValue == "incomeMissing")
}
