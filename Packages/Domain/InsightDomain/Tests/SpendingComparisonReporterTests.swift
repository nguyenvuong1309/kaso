import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("compares current month and year to previous periods")
func comparesCurrentMonthAndYearToPreviousPeriods() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = [
        expense(3_000_000, date: try date(2026, 4, 10, calendar: calendar)),
        expense(2_000_000, date: try date(2026, 3, 10, calendar: calendar)),
        expense(7_000_000, date: try date(2026, 2, 10, calendar: calendar)),
        expense(4_000_000, date: try date(2025, 4, 10, calendar: calendar)),
        Transaction(
            amount: 30_000_000,
            kind: .income,
            category: .salary,
            occurredAt: try date(2026, 4, 10, calendar: calendar)
        ),
    ]

    let report = SpendingComparisonReporter.report(
        transactions: transactions,
        referenceDate: try date(2026, 4, 26, calendar: calendar),
        calendar: calendar
    )

    #expect(report.month.currentExpense == 3_000_000)
    #expect(report.month.previousExpense == 2_000_000)
    #expect(report.month.delta == 1_000_000)
    #expect(report.month.trend == .increased)
    #expect(report.yearToDate.currentExpense == 12_000_000)
    #expect(report.yearToDate.previousExpense == 4_000_000)
    #expect(report.yearToDate.trend == .increased)
}

private func expense(_ amount: Decimal, date: Date) -> Transaction {
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
    try #require(DateComponents(calendar: calendar, year: year, month: month, day: day).date)
}
