import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("detects peak weekdays and evening spending")
func detectsPeakWeekdaysAndEveningSpending() throws {
    let calendar = Calendar(identifier: .gregorian)
    let fridayNight = try date(2026, 4, 3, hour: 21, calendar: calendar)
    let saturdayNight = try date(2026, 4, 4, hour: 21, calendar: calendar)
    let fridayWeekday = calendar.component(.weekday, from: fridayNight)
    let saturdayWeekday = calendar.component(.weekday, from: saturdayNight)
    let transactions = [
        expense(amount: 500_000, date: fridayNight),
        expense(amount: 300_000, date: try date(2026, 4, 10, hour: 20, calendar: calendar)),
        expense(amount: 450_000, date: saturdayNight),
        expense(amount: 80_000, date: try date(2026, 4, 6, hour: 9, calendar: calendar)),
        expense(amount: 70_000, date: try date(2026, 4, 7, hour: 12, calendar: calendar)),
    ]

    let analysis = TimeSpendingAnalyzer.analyze(
        transactions: transactions,
        referenceDate: try date(2026, 4, 26, hour: 12, calendar: calendar),
        calendar: calendar,
        configuration: TimeSpendingAnalysisConfiguration(
            minimumTransactionCount: 4,
            eveningShareThreshold: Decimal(string: "0.4") ?? 0.4
        )
    )

    #expect(analysis.transactionCount == 5)
    #expect(analysis.peakWeekdays.map(\.weekday) == [fridayWeekday, saturdayWeekday])
    #expect(analysis.peakWeekdays.first?.amount == 800_000)
    #expect(analysis.peakHours.first?.hour == 21)
    #expect(analysis.peakHours.first?.amount == 950_000)
    #expect(analysis.eveningSpike?.startHour == 20)
    #expect(analysis.eveningSpike?.amount == 1_250_000)
}

@Test("ignores income future and stale transactions")
func ignoresIncomeFutureAndStaleTransactions() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try date(2026, 4, 26, hour: 12, calendar: calendar)
    let transactions = [
        Transaction(
            amount: 10_000_000,
            kind: .income,
            category: .salary,
            occurredAt: try date(2026, 4, 1, hour: 9, calendar: calendar)
        ),
        expense(amount: 9_000_000, date: try date(2026, 1, 20, hour: 21, calendar: calendar)),
        expense(amount: 500_000, date: try date(2026, 5, 1, hour: 21, calendar: calendar)),
        expense(amount: 120_000, date: try date(2026, 4, 12, hour: 10, calendar: calendar)),
    ]

    let analysis = TimeSpendingAnalyzer.analyze(
        transactions: transactions,
        referenceDate: referenceDate,
        calendar: calendar,
        configuration: TimeSpendingAnalysisConfiguration(minimumTransactionCount: 2)
    )

    #expect(analysis.transactionCount == 1)
    #expect(analysis.peakWeekdays.isEmpty)
    #expect(analysis.peakHours.isEmpty)
    #expect(analysis.eveningSpike == nil)
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
    hour: Int,
    calendar: Calendar
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
