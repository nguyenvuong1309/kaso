import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("forecast is tight when the projected balance is a thin slice of income")
func forecasterTightStatus() throws {
    let calendar = Calendar(identifier: .gregorian)
    // Income 10,000,000, current pace spends ~9,600,000 over the month -> balance within 10%.
    let transactions = try [
        forecasterIncome(amount: 10_000_000, date: forecasterDate(2026, 4, 1, calendar: calendar)),
        forecasterExpense(amount: 4_800_000, date: forecasterDate(2026, 4, 15, calendar: calendar)),
    ]

    let forecast = MonthlyBalanceForecaster.forecast(
        transactions: transactions,
        referenceDate: try forecasterDate(2026, 4, 15, calendar: calendar),
        calendar: calendar
    )

    // 4,800,000 over 15 days = 320,000/day * 30 days = 9,600,000 projected.
    #expect(forecast.projectedExpense == 9_600_000)
    #expect(forecast.projectedBalance == 400_000)
    #expect(forecast.status == .tight)
}

@Test("forecast reports the daily rate and remaining days for the month")
func forecasterDailyRateAndRemainingDays() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = try [
        forecasterIncome(amount: 20_000_000, date: forecasterDate(2026, 4, 1, calendar: calendar)),
        forecasterExpense(amount: 1_000_000, date: forecasterDate(2026, 4, 10, calendar: calendar)),
    ]

    let forecast = MonthlyBalanceForecaster.forecast(
        transactions: transactions,
        referenceDate: try forecasterDate(2026, 4, 10, calendar: calendar),
        calendar: calendar
    )

    // 1,000,000 over 10 elapsed days = 100,000/day.
    #expect(forecast.dailyExpenseRate == 100_000)
    // April has 30 days, 10 elapsed -> 20 remaining.
    #expect(forecast.remainingDayCount == 20)
    #expect(forecast.expenseToDate == 1_000_000)
}

@Test("forecast on the last day of the month leaves zero remaining days")
func forecasterLastDayRemainingZero() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = try [
        forecasterIncome(amount: 10_000_000, date: forecasterDate(2026, 4, 1, calendar: calendar)),
        forecasterExpense(amount: 3_000_000, date: forecasterDate(2026, 4, 5, calendar: calendar)),
    ]

    let forecast = MonthlyBalanceForecaster.forecast(
        transactions: transactions,
        referenceDate: try forecasterDate(2026, 4, 30, calendar: calendar),
        calendar: calendar
    )

    #expect(forecast.remainingDayCount == 0)
    // projected expense never drops below the expense already booked
    #expect(forecast.projectedExpense >= 3_000_000)
}

@Test("forecast with no transactions is safe and balanced at zero")
func forecasterEmptyTransactions() throws {
    let calendar = Calendar(identifier: .gregorian)

    let forecast = MonthlyBalanceForecaster.forecast(
        transactions: [],
        referenceDate: try forecasterDate(2026, 4, 15, calendar: calendar),
        calendar: calendar
    )

    #expect(forecast.incomeToDate == 0)
    #expect(forecast.expenseToDate == 0)
    #expect(forecast.projectedExpense == 0)
    #expect(forecast.projectedBalance == 0)
    #expect(forecast.dailyExpenseRate == 0)
    #expect(forecast.status == .safe)
}

@Test("lookback window controls which historical months feed the pace")
func forecasterLookbackWindow() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = try [
        forecasterIncome(amount: 30_000_000, date: forecasterDate(2026, 4, 1, calendar: calendar)),
        // only one month of history, beyond a 1-month lookback when measured from early April
        forecasterExpense(amount: 6_000_000, date: forecasterDate(2026, 2, 15, calendar: calendar)),
    ]

    let oneMonthLookback = MonthlyBalanceForecaster.forecast(
        transactions: transactions,
        referenceDate: try forecasterDate(2026, 4, 2, calendar: calendar),
        lookbackMonthCount: 1,
        calendar: calendar
    )
    let threeMonthLookback = MonthlyBalanceForecaster.forecast(
        transactions: transactions,
        referenceDate: try forecasterDate(2026, 4, 2, calendar: calendar),
        lookbackMonthCount: 3,
        calendar: calendar
    )

    // With a 1-month lookback only March is sampled (empty) -> no historical pace.
    #expect(oneMonthLookback.projectedExpense == 0)
    // With a 3-month lookback February's spend lifts the projected expense.
    #expect(threeMonthLookback.projectedExpense > 0)
}

private func forecasterIncome(amount: Decimal, date: Date) -> Transaction {
    Transaction(amount: amount, kind: .income, category: .salary, occurredAt: date)
}

private func forecasterExpense(amount: Decimal, date: Date) -> Transaction {
    Transaction(amount: amount, kind: .expense, category: .food, occurredAt: date)
}

private func forecasterDate(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    calendar: Calendar
) throws -> Date {
    try #require(
        DateComponents(calendar: calendar, year: year, month: month, day: day, hour: 12).date
    )
}
