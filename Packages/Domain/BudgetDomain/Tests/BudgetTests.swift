import Foundation
import Testing
import TransactionDomain
@testable import BudgetDomain

@Test("id is derived from the category id")
func budgetIdMatchesCategoryId() {
    let budget = Budget(category: .food, monthlyLimit: 1_000_000)
    #expect(budget.id == "food")
    #expect(budget.id == TransactionCategory.food.id)
}

@Test("default spent is zero")
func budgetDefaultSpentIsZero() {
    let budget = Budget(category: .transport, monthlyLimit: 500_000)
    #expect(budget.spent == Decimal(0))
}

@Test("remaining subtracts spent from the monthly limit")
func budgetRemaining() {
    let budget = Budget(category: .food, monthlyLimit: 1_000_000, spent: 350_000)
    #expect(budget.remaining == Decimal(650_000))
}

@Test("remaining is the full limit when nothing is spent")
func budgetRemainingFullLimit() {
    let budget = Budget(category: .food, monthlyLimit: 1_000_000)
    #expect(budget.remaining == Decimal(1_000_000))
}

@Test("remaining goes negative when overspent")
func budgetRemainingNegative() {
    let budget = Budget(category: .food, monthlyLimit: 1_000_000, spent: 1_200_000)
    #expect(budget.remaining == Decimal(-200_000))
}

@Test("utilization is the spent over limit ratio")
func budgetUtilization() {
    let budget = Budget(category: .food, monthlyLimit: 1_000_000, spent: 250_000)
    #expect(budget.utilization == 0.25)
}

@Test("utilization is zero when the limit is zero")
func budgetUtilizationZeroLimit() {
    let budget = Budget(category: .food, monthlyLimit: 0, spent: 100_000)
    #expect(budget.utilization == 0)
}

@Test("utilization is zero when the limit is negative")
func budgetUtilizationNegativeLimit() {
    let budget = Budget(category: .food, monthlyLimit: -10, spent: 100_000)
    #expect(budget.utilization == 0)
}

@Test("utilization can exceed one when overspent")
func budgetUtilizationOverOne() {
    let budget = Budget(category: .food, monthlyLimit: 1_000_000, spent: 1_500_000)
    #expect(budget.utilization == 1.5)
}

@Test("utilization is zero when nothing is spent")
func budgetUtilizationZeroSpent() {
    let budget = Budget(category: .food, monthlyLimit: 1_000_000)
    #expect(budget.utilization == 0)
}

@Test("status is exceeded at exactly full utilization")
func budgetStatusExceededBoundary() {
    let budget = Budget(category: .food, monthlyLimit: 1_000_000, spent: 1_000_000)
    #expect(budget.status == .exceeded)
}

@Test("status is exceeded above full utilization")
func budgetStatusExceededAbove() {
    let budget = Budget(category: .food, monthlyLimit: 1_000_000, spent: 2_000_000)
    #expect(budget.status == .exceeded)
}

@Test("status is nearLimit at exactly the eighty percent boundary")
func budgetStatusNearLimitBoundary() {
    let budget = Budget(category: .food, monthlyLimit: 1_000_000, spent: 800_000)
    #expect(budget.status == .nearLimit)
}

@Test("status is healthy just below the nearLimit threshold")
func budgetStatusHealthyJustBelow() {
    let budget = Budget(category: .food, monthlyLimit: 1_000_000, spent: 799_999)
    #expect(budget.status == .healthy)
}

@Test("status is healthy when nothing is spent")
func budgetStatusHealthyZeroSpent() {
    let budget = Budget(category: .food, monthlyLimit: 1_000_000)
    #expect(budget.status == .healthy)
}

@Test("status is healthy when the limit is zero")
func budgetStatusHealthyZeroLimit() {
    let budget = Budget(category: .food, monthlyLimit: 0, spent: 100_000)
    #expect(budget.status == .healthy)
}

@Test("budget is Equatable across all stored properties")
func budgetEquatable() {
    let lhs = Budget(category: .food, monthlyLimit: 1_000_000, spent: 200_000)
    let rhs = Budget(category: .food, monthlyLimit: 1_000_000, spent: 200_000)
    #expect(lhs == rhs)
    #expect(lhs != Budget(category: .transport, monthlyLimit: 1_000_000, spent: 200_000))
    #expect(lhs != Budget(category: .food, monthlyLimit: 999_999, spent: 200_000))
    #expect(lhs != Budget(category: .food, monthlyLimit: 1_000_000, spent: 200_001))
}

@Test("budget round-trips through Codable")
func budgetCodableRoundTrip() throws {
    let budget = Budget(category: .health, monthlyLimit: 750_000, spent: 123_456)
    let data = try JSONEncoder().encode(budget)
    let decoded = try JSONDecoder().decode(Budget.self, from: data)
    #expect(decoded == budget)
}

@Test("budget status enum cases are distinct")
func budgetStatusEquatable() {
    #expect(BudgetStatus.healthy == .healthy)
    #expect(BudgetStatus.healthy != .nearLimit)
    #expect(BudgetStatus.nearLimit != .exceeded)
    #expect(BudgetStatus.exceeded == .exceeded)
}
