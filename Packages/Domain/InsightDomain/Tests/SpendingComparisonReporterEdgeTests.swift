import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("month comparison reports a decrease when current spend drops")
func comparisonReporterDecreasedTrend() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = try [
        comparisonExpense(1_000_000, date: comparisonDate(2026, 4, 10, calendar: calendar)),
        comparisonExpense(4_000_000, date: comparisonDate(2026, 3, 10, calendar: calendar)),
    ]

    let report = SpendingComparisonReporter.report(
        transactions: transactions,
        referenceDate: try comparisonDate(2026, 4, 26, calendar: calendar),
        calendar: calendar
    )

    #expect(report.month.currentExpense == 1_000_000)
    #expect(report.month.previousExpense == 4_000_000)
    #expect(report.month.delta == -3_000_000)
    #expect(report.month.trend == .decreased)
    let percentage = try #require(report.month.percentageChange)
    #expect(abs(percentage + 0.75) < 0.000_001)
}

@Test("flat trend with no previous spend yields a nil percentage change")
func comparisonReporterFlatNilPercentage() throws {
    let calendar = Calendar(identifier: .gregorian)
    // First-ever month: no previous-month or previous-year data.
    let transactions = try [
        comparisonExpense(2_000_000, date: comparisonDate(2026, 1, 5, calendar: calendar)),
    ]

    let report = SpendingComparisonReporter.report(
        transactions: transactions,
        referenceDate: try comparisonDate(2026, 1, 10, calendar: calendar),
        calendar: calendar
    )

    #expect(report.month.currentExpense == 2_000_000)
    #expect(report.month.previousExpense == 0)
    #expect(report.month.percentageChange == nil)
    #expect(report.month.trend == .increased)
}

@Test("identical spend across periods is flat with a zero percentage change")
func comparisonReporterFlatTrend() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = try [
        comparisonExpense(2_000_000, date: comparisonDate(2026, 4, 10, calendar: calendar)),
        comparisonExpense(2_000_000, date: comparisonDate(2026, 3, 10, calendar: calendar)),
    ]

    let report = SpendingComparisonReporter.report(
        transactions: transactions,
        referenceDate: try comparisonDate(2026, 4, 26, calendar: calendar),
        calendar: calendar
    )

    #expect(report.month.delta == 0)
    #expect(report.month.trend == .flat)
    let percentage = try #require(report.month.percentageChange)
    #expect(percentage == 0)
}

@Test("income transactions never count toward spending comparisons")
func comparisonReporterIgnoresIncome() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = try [
        Transaction(amount: 30_000_000, kind: .income, category: .salary, occurredAt: comparisonDate(2026, 4, 10, calendar: calendar)),
        comparisonExpense(1_000_000, date: comparisonDate(2026, 4, 11, calendar: calendar)),
    ]

    let report = SpendingComparisonReporter.report(
        transactions: transactions,
        referenceDate: try comparisonDate(2026, 4, 26, calendar: calendar),
        calendar: calendar
    )

    #expect(report.month.currentExpense == 1_000_000)
    #expect(report.yearToDate.currentExpense == 1_000_000)
}

private func comparisonExpense(_ amount: Decimal, date: Date) -> Transaction {
    Transaction(amount: amount, kind: .expense, category: .food, occurredAt: date)
}

private func comparisonDate(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    calendar: Calendar
) throws -> Date {
    try #require(
        DateComponents(calendar: calendar, year: year, month: month, day: day, hour: 12).date
    )
}
