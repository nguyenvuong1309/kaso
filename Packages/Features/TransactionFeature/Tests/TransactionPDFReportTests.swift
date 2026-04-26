import Foundation
import Testing
import ComposableArchitecture
import TransactionDomain
@testable import TransactionFeature

@Test("builds PDF report from current month transactions")
func buildsPDFReportFromCurrentMonthTransactions() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try date(2026, 4, 26, calendar: calendar)
    let incomeID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000101"))
    let expenseID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000102"))
    let previousMonthID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000103"))
    let transactions = [
        Transaction(
            id: incomeID,
            amount: 20_000_000,
            kind: .income,
            category: .salary,
            occurredAt: try date(2026, 4, 1, calendar: calendar)
        ),
        Transaction(
            id: expenseID,
            amount: 125_000,
            kind: .expense,
            category: .food,
            occurredAt: try date(2026, 4, 25, calendar: calendar),
            note: "Bữa tối"
        ),
        Transaction(
            id: previousMonthID,
            amount: 1_000_000,
            kind: .expense,
            category: .shopping,
            occurredAt: try date(2026, 3, 15, calendar: calendar)
        ),
    ]
    let state = TransactionFeature.State(
        transactions: IdentifiedArray(uniqueElements: transactions),
        historyReferenceDate: referenceDate
    )

    let report = state.pdfReport

    #expect(report.fileName == "kaso-report-2026-04-26.pdf")
    #expect(report.summary.income == 20_000_000)
    #expect(report.summary.expense == 125_000)
    #expect(report.summary.balance == 19_875_000)
    #expect(report.transactionCount == 2)
    #expect(report.recentTransactions.map(\.id) == [expenseID, incomeID])
    #expect(report.categorySpendings == [
        MonthlyCategorySpending(
            category: .food,
            amount: 125_000,
            fraction: 1
        ),
    ])
}

private func date(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    calendar: Calendar
) throws -> Date {
    try #require(DateComponents(calendar: calendar, year: year, month: month, day: day).date)
}
