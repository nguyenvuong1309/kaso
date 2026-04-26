import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("forecasts end of month balance from current pace and history")
func forecastsEndOfMonthBalanceFromCurrentPaceAndHistory() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = try [
        income(amount: 10_000_000, date: date(2026, 4, 1, calendar: calendar)),
        expense(amount: 3_000_000, date: date(2026, 4, 15, calendar: calendar)),
        expense(amount: 6_000_000, date: date(2026, 1, 15, calendar: calendar)),
        expense(amount: 6_000_000, date: date(2026, 2, 15, calendar: calendar)),
        expense(amount: 6_000_000, date: date(2026, 3, 15, calendar: calendar)),
    ]

    let forecast = MonthlyBalanceForecaster.forecast(
        transactions: transactions,
        referenceDate: try date(2026, 4, 15, calendar: calendar),
        calendar: calendar
    )

    #expect(forecast.incomeToDate == 10_000_000)
    #expect(forecast.expenseToDate == 3_000_000)
    #expect(forecast.projectedExpense == 6_000_000)
    #expect(forecast.projectedBalance == 4_000_000)
    #expect(forecast.remainingDayCount == 15)
    #expect(forecast.status == .safe)
}

@Test("marks forecast negative when projected expense exceeds income")
func marksForecastNegativeWhenProjectedExpenseExceedsIncome() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = try [
        income(amount: 5_000_000, date: date(2026, 4, 1, calendar: calendar)),
        expense(amount: 4_000_000, date: date(2026, 4, 10, calendar: calendar)),
    ]

    let forecast = MonthlyBalanceForecaster.forecast(
        transactions: transactions,
        referenceDate: try date(2026, 4, 10, calendar: calendar),
        calendar: calendar
    )

    #expect(forecast.projectedBalance < 0)
    #expect(forecast.status == .negative)
}

@Test("uses historical pace when current month has no expenses")
func usesHistoricalPaceWhenCurrentMonthHasNoExpenses() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = try [
        income(amount: 10_000_000, date: date(2026, 4, 1, calendar: calendar)),
        expense(amount: 3_100_000, date: date(2026, 3, 15, calendar: calendar)),
    ]

    let forecast = MonthlyBalanceForecaster.forecast(
        transactions: transactions,
        referenceDate: try date(2026, 4, 2, calendar: calendar),
        calendar: calendar
    )

    #expect(forecast.expenseToDate == 0)
    #expect(forecast.projectedExpense == 3_000_000)
    #expect(forecast.projectedBalance == 7_000_000)
}

private func income(amount: Decimal, date: Date) -> Transaction {
    Transaction(
        amount: amount,
        kind: .income,
        category: .salary,
        occurredAt: date
    )
}

private func expense(amount: Decimal, date: Date) -> Transaction {
    Transaction(
        amount: amount,
        kind: .expense,
        category: .food,
        occurredAt: date
    )
}

private func date(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    calendar: Calendar
) throws -> Date {
    try #require(
        DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day
        ).date
    )
}
