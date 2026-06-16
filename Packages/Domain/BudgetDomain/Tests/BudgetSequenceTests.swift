import Foundation
import Testing
import TransactionDomain
@testable import BudgetDomain

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 12,
    calendar: Calendar = Calendar(identifier: .gregorian)
) throws -> Date {
    try #require(
        DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date
    )
}

@Test("applying spending to an empty budget list returns empty")
func applyingSpendingEmptyBudgets() throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try makeDate(year: 2026, month: 5, day: 10, calendar: calendar)
    let transactions = [
        Transaction(amount: 100_000, kind: .expense, category: .food, occurredAt: date),
    ]

    let result = [Budget]().applyingMonthlySpending(
        from: transactions,
        containing: date,
        calendar: calendar
    )

    #expect(result.isEmpty)
}

@Test("applying empty transactions resets spent to zero")
func applyingEmptyTransactionsResetsSpent() throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try makeDate(year: 2026, month: 5, day: 10, calendar: calendar)
    let budgets = [
        Budget(category: .food, monthlyLimit: 1_000_000, spent: 400_000),
    ]

    let result = budgets.applyingMonthlySpending(
        from: [],
        containing: date,
        calendar: calendar
    )

    #expect(result == [Budget(category: .food, monthlyLimit: 1_000_000, spent: 0)])
}

@Test("income transactions are excluded from spending")
func applyingSpendingExcludesIncome() throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try makeDate(year: 2026, month: 5, day: 10, calendar: calendar)
    let budgets = [Budget(category: .salary, monthlyLimit: 1_000_000)]
    let transactions = [
        Transaction(amount: 5_000_000, kind: .income, category: .salary, occurredAt: date),
    ]

    let result = budgets.applyingMonthlySpending(
        from: transactions,
        containing: date,
        calendar: calendar
    )

    #expect(result == [Budget(category: .salary, monthlyLimit: 1_000_000, spent: 0)])
}

@Test("transactions in other categories are excluded")
func applyingSpendingExcludesOtherCategories() throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try makeDate(year: 2026, month: 5, day: 10, calendar: calendar)
    let budgets = [Budget(category: .food, monthlyLimit: 1_000_000)]
    let transactions = [
        Transaction(amount: 300_000, kind: .expense, category: .transport, occurredAt: date),
    ]

    let result = budgets.applyingMonthlySpending(
        from: transactions,
        containing: date,
        calendar: calendar
    )

    #expect(result == [Budget(category: .food, monthlyLimit: 1_000_000, spent: 0)])
}

@Test("transactions in other months are excluded")
func applyingSpendingExcludesOtherMonths() throws {
    let calendar = Calendar(identifier: .gregorian)
    let targetDate = try makeDate(year: 2026, month: 5, day: 10, calendar: calendar)
    let nextMonth = try makeDate(year: 2026, month: 6, day: 1, calendar: calendar)
    let lastMonth = try makeDate(year: 2026, month: 4, day: 30, calendar: calendar)
    let budgets = [Budget(category: .food, monthlyLimit: 1_000_000)]
    let transactions = [
        Transaction(amount: 100_000, kind: .expense, category: .food, occurredAt: targetDate),
        Transaction(amount: 200_000, kind: .expense, category: .food, occurredAt: nextMonth),
        Transaction(amount: 300_000, kind: .expense, category: .food, occurredAt: lastMonth),
    ]

    let result = budgets.applyingMonthlySpending(
        from: transactions,
        containing: targetDate,
        calendar: calendar
    )

    #expect(result == [Budget(category: .food, monthlyLimit: 1_000_000, spent: 100_000)])
}

@Test("spending matches across different days within the same month")
func applyingSpendingSameMonthDifferentDays() throws {
    let calendar = Calendar(identifier: .gregorian)
    let target = try makeDate(year: 2026, month: 5, day: 15, calendar: calendar)
    let firstDay = try makeDate(year: 2026, month: 5, day: 1, calendar: calendar)
    let lastDay = try makeDate(year: 2026, month: 5, day: 31, calendar: calendar)
    let budgets = [Budget(category: .food, monthlyLimit: 1_000_000)]
    let transactions = [
        Transaction(amount: 100_000, kind: .expense, category: .food, occurredAt: firstDay),
        Transaction(amount: 250_000, kind: .expense, category: .food, occurredAt: target),
        Transaction(amount: 50_000, kind: .expense, category: .food, occurredAt: lastDay),
    ]

    let result = budgets.applyingMonthlySpending(
        from: transactions,
        containing: target,
        calendar: calendar
    )

    #expect(result == [Budget(category: .food, monthlyLimit: 1_000_000, spent: 400_000)])
}

@Test("budget order is preserved in the result")
func applyingSpendingPreservesOrder() throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try makeDate(year: 2026, month: 5, day: 10, calendar: calendar)
    let budgets = [
        Budget(category: .transport, monthlyLimit: 500_000),
        Budget(category: .food, monthlyLimit: 1_000_000),
        Budget(category: .health, monthlyLimit: 200_000),
    ]

    let result = budgets.applyingMonthlySpending(
        from: [],
        containing: date,
        calendar: calendar
    )

    #expect(result.map(\.category) == [.transport, .food, .health])
}

@Test("monthly limit is left untouched by applying spending")
func applyingSpendingKeepsLimit() throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try makeDate(year: 2026, month: 5, day: 10, calendar: calendar)
    let budgets = [Budget(category: .food, monthlyLimit: 1_234_567)]
    let transactions = [
        Transaction(amount: 99_000, kind: .expense, category: .food, occurredAt: date),
    ]

    let result = budgets.applyingMonthlySpending(
        from: transactions,
        containing: date,
        calendar: calendar
    )

    #expect(result.first?.monthlyLimit == Decimal(1_234_567))
    #expect(result.first?.spent == Decimal(99_000))
}
