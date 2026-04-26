import Foundation
import Testing
import TransactionDomain
@testable import BudgetDomain

@Test("calculates budget status thresholds")
func calculatesBudgetStatusThresholds() {
    #expect(
        Budget(
            category: .food,
            monthlyLimit: 1_000_000,
            spent: 799_000
        ).status == .healthy
    )
    #expect(
        Budget(
            category: .food,
            monthlyLimit: 1_000_000,
            spent: 800_000
        ).status == .nearLimit
    )
    #expect(
        Budget(
            category: .food,
            monthlyLimit: 1_000_000,
            spent: 1_000_000
        ).status == .exceeded
    )
}

@Test("applies current month spending to category budgets")
func appliesCurrentMonthSpendingToCategoryBudgets() throws {
    let calendar = Calendar(identifier: .gregorian)
    let targetDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let previousMonthDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 3, day: 26).date
    )
    let budgets = [
        Budget(category: .food, monthlyLimit: 1_000_000),
        Budget(category: .transport, monthlyLimit: 500_000),
    ]
    let transactions = [
        Transaction(
            amount: 20_000_000,
            kind: .income,
            category: .salary,
            occurredAt: targetDate
        ),
        Transaction(
            amount: 250_000,
            kind: .expense,
            category: .food,
            occurredAt: targetDate
        ),
        Transaction(
            amount: 150_000,
            kind: .expense,
            category: .food,
            occurredAt: targetDate
        ),
        Transaction(
            amount: 300_000,
            kind: .expense,
            category: .transport,
            occurredAt: targetDate
        ),
        Transaction(
            amount: 500_000,
            kind: .expense,
            category: .food,
            occurredAt: previousMonthDate
        ),
    ]

    let updatedBudgets = budgets.applyingMonthlySpending(
        from: transactions,
        containing: targetDate,
        calendar: calendar
    )

    #expect(
        updatedBudgets == [
            Budget(
                category: .food,
                monthlyLimit: 1_000_000,
                spent: 400_000
            ),
            Budget(
                category: .transport,
                monthlyLimit: 500_000,
                spent: 300_000
            ),
        ]
    )
}
